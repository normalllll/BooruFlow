//! Bounded, frame-at-a-time ugoira export. No frame files are extracted to disk.
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use serde::Deserialize;
use std::{
    collections::HashSet,
    fs::File,
    io::{Read, Seek, SeekFrom, Write},
    path::{Path, PathBuf},
};
use tokio_util::sync::CancellationToken;
use zune_jpeg::{
    zune_core::{bytestream::ZCursor, colorspace::ColorSpace},
    JpegDecoder,
};

// Bound archive metadata, decoded frame memory and animation size independently.
const MAX_ARCHIVE_BYTES: u64 = 512 * 1024 * 1024;
const MAX_DIRECTORY_BYTES: u64 = 8 * 1024 * 1024;
const MAX_METADATA_BYTES: u64 = 1024 * 1024;
const MAX_FRAME_BYTES: u64 = 64 * 1024 * 1024;
const MAX_PIXELS: usize = 16_777_216;
const MAX_FRAMES: usize = 10_000;
const MAX_OUTPUT_BYTES: u64 = 1024 * 1024 * 1024;

#[derive(Deserialize)]
struct Animation {
    frames: Vec<Frame>,
}
#[derive(Deserialize)]
struct Frame {
    file: String,
    delay: u32,
}

fn error(key: &str) -> BooruError {
    BooruError::new(BooruErrorCode::MediaValidationFailed, None, key)
}
fn io_error() -> BooruError {
    error("booru.error.downloadIoFailed")
}
fn cancelled(token: &CancellationToken) -> BooruResult<()> {
    if token.is_cancelled() {
        Err(BooruError::new(
            BooruErrorCode::Cancelled,
            None,
            "booru.error.cancelled",
        ))
    } else {
        Ok(())
    }
}
fn u24(value: u32) -> [u8; 3] {
    let b = value.to_le_bytes();
    [b[0], b[1], b[2]]
}
fn chunk<W: Write>(out: &mut W, id: &[u8; 4], data: &[u8]) -> BooruResult<()> {
    out.write_all(id)
        .and_then(|_| out.write_all(&(data.len() as u32).to_le_bytes()))
        .and_then(|_| out.write_all(data))
        .map_err(|_| io_error())?;
    if data.len() % 2 != 0 {
        out.write_all(&[0]).map_err(|_| io_error())?;
    }
    Ok(())
}

/// Publishes only a complete RIFF. Cancellation/failure removes the partial;
/// the original archive is never modified. At most one decoded frame is held.
pub fn export<F>(
    input: &Path,
    destination: &Path,
    token: &CancellationToken,
    mut progress: F,
) -> BooruResult<PathBuf>
where
    F: FnMut(usize, usize) -> BooruResult<()>,
{
    let part = destination.with_extension("webp.part");
    let result = encode(input, &part, token, &mut progress);
    if let Err(e) = result {
        let _ = std::fs::remove_file(&part);
        return Err(e);
    }
    if let Err(e) = cancelled(token) {
        let _ = std::fs::remove_file(&part);
        return Err(e);
    }
    // The caller owns this task-specific temporary directory. Do not overwrite
    // unrelated existing files; final user-facing collision handling is later.
    if destination.exists() {
        let _ = std::fs::remove_file(&part);
        return Err(io_error());
    }
    std::fs::rename(&part, destination).map_err(|_| {
        let _ = std::fs::remove_file(&part);
        io_error()
    })?;
    Ok(destination.to_owned())
}
fn encode<F>(
    input: &Path,
    part: &Path,
    token: &CancellationToken,
    progress: &mut F,
) -> BooruResult<()>
where
    F: FnMut(usize, usize) -> BooruResult<()>,
{
    cancelled(token)?;
    let mut file = File::open(input).map_err(|_| io_error())?;
    validate_archive_directory(&mut file)?;
    let mut archive =
        zip::ZipArchive::new(file).map_err(|_| error("booru.error.ugoiraInvalidArchive"))?;
    let animation: Animation = {
        let metadata = archive
            .by_name("animation.json")
            .map_err(|_| error("booru.error.ugoiraMetadataMissing"))?;
        if metadata.size() > MAX_METADATA_BYTES {
            return Err(error("booru.error.ugoiraInvalidMetadata"));
        }
        serde_json::from_reader(metadata.take(MAX_METADATA_BYTES + 1))
            .map_err(|_| error("booru.error.ugoiraInvalidMetadata"))?
    };
    let mut names = HashSet::new();
    if animation.frames.is_empty()
        || animation.frames.len() > MAX_FRAMES
        || animation.frames.iter().any(|f| {
            f.delay == 0
                || f.delay > 0xFF_FFFF
                || !names.insert(f.file.as_str())
                || f.file.contains(['/', '\\'])
                || f.file == "animation.json"
        })
    {
        return Err(error("booru.error.ugoiraInvalidMetadata"));
    }
    let mut out = File::create(part).map_err(|_| io_error())?;
    out.write_all(b"RIFF\0\0\0\0WEBP").map_err(|_| io_error())?;
    let mut dimensions = None;
    for (index, frame) in animation.frames.iter().enumerate() {
        cancelled(token)?;
        // This also observes a closed FRB stream before doing another frame.
        progress(index, animation.frames.len())?;
        let mut entry = archive
            .by_name(&frame.file)
            .map_err(|_| error("booru.error.ugoiraFrameMissing"))?;
        if entry.size() > MAX_FRAME_BYTES {
            return Err(error("booru.error.ugoiraFrameTooLarge"));
        }
        let mut compressed = Vec::new();
        entry
            .by_ref()
            .take(MAX_FRAME_BYTES + 1)
            .read_to_end(&mut compressed)
            .map_err(|_| error("booru.error.ugoiraFrameCorrupt"))?;
        if compressed.len() as u64 > MAX_FRAME_BYTES {
            return Err(error("booru.error.ugoiraFrameTooLarge"));
        }
        drop(entry);
        let (pixels, width, height) = decode(&compressed)?;
        drop(compressed);
        if let Some(expected) = dimensions {
            if expected != (width, height) {
                return Err(error("booru.error.ugoiraFrameSizeMismatch"));
            }
        } else {
            dimensions = Some((width, height));
            // Always advertise alpha: each full-canvas frame replaces previous
            // pixels (ANMF no-blend), including transparent source pixels.
            let mut vp8x = vec![0x12, 0, 0, 0];
            vp8x.extend(u24(width - 1));
            vp8x.extend(u24(height - 1));
            chunk(&mut out, b"VP8X", &vp8x)?;
            chunk(&mut out, b"ANIM", &[0; 6])?; // transparent background, infinite loop
        }
        cancelled(token)?;
        let mut still = Vec::new();
        image_webp::WebPEncoder::new(&mut still)
            .encode(&pixels, width, height, image_webp::ColorType::Rgba8)
            .map_err(|_| error("booru.error.ugoiraEncodeFailed"))?;
        drop(pixels);
        cancelled(token)?;
        // image-webp writes a complete still RIFF. Retain only its VP8L chunk,
        // not another RIFF or VP8X inside the animation frame.
        let mut offset = 12;
        let mut lossless = None;
        while offset + 8 <= still.len() {
            let n = u32::from_le_bytes(still[offset + 4..offset + 8].try_into().unwrap()) as usize;
            let end = offset
                .checked_add(8 + n + n % 2)
                .filter(|end| *end <= still.len())
                .ok_or_else(|| error("booru.error.ugoiraEncodeFailed"))?;
            if &still[offset..offset + 4] == b"VP8L" {
                lossless = Some(&still[offset..end]);
                break;
            }
            offset = end;
        }
        let payload = lossless.ok_or_else(|| error("booru.error.ugoiraEncodeFailed"))?;
        let mut header = Vec::with_capacity(16);
        header.extend([0; 6]);
        header.extend(u24(width - 1));
        header.extend(u24(height - 1));
        header.extend(u24(frame.delay));
        header.push(2); // full frame, do not alpha-blend
        let length = header.len() + payload.len();
        out.write_all(b"ANMF")
            .and_then(|_| out.write_all(&(length as u32).to_le_bytes()))
            .and_then(|_| out.write_all(&header))
            .and_then(|_| out.write_all(payload))
            .map_err(|_| io_error())?;
        if length % 2 != 0 {
            out.write_all(&[0]).map_err(|_| io_error())?;
        }
        if out.stream_position().map_err(|_| io_error())? > MAX_OUTPUT_BYTES {
            return Err(error("booru.error.ugoiraOutputTooLarge"));
        }
        progress(index + 1, animation.frames.len())?;
    }
    let size = out.stream_position().map_err(|_| io_error())? as u32 - 8;
    out.seek(SeekFrom::Start(4))
        .and_then(|_| out.write_all(&size.to_le_bytes()))
        .and_then(|_| out.sync_all())
        .map_err(|_| io_error())
}
// Bound central-directory allocation before ZipArchive reads its index.
// ZIP64 sentinels are rejected within this bounded export contract.
fn validate_archive_directory(file: &mut File) -> BooruResult<()> {
    let invalid = || error("booru.error.ugoiraInvalidArchive");
    let length = file.metadata().map_err(|_| io_error())?.len();
    if length < 22 || length > MAX_ARCHIVE_BYTES {
        return Err(invalid());
    }
    let tail_len = length.min(65557) as usize;
    file.seek(SeekFrom::End(-(tail_len as i64)))
        .map_err(|_| io_error())?;
    let mut tail = vec![0; tail_len];
    file.read_exact(&mut tail).map_err(|_| io_error())?;
    let at = (0..=tail.len() - 22)
        .rev()
        .find(|i| {
            tail[*i..*i + 4] == [80, 75, 5, 6]
                && *i + 22 + u16::from_le_bytes(tail[*i + 20..*i + 22].try_into().unwrap()) as usize
                    == tail.len()
        })
        .ok_or_else(invalid)?;
    let end = &tail[at..];
    let entries = u16::from_le_bytes(end[10..12].try_into().unwrap()) as usize;
    let size = u32::from_le_bytes(end[12..16].try_into().unwrap()) as u64;
    let start = u32::from_le_bytes(end[16..20].try_into().unwrap()) as u64;
    if entries == 0
        || entries > MAX_FRAMES + 64
        || size > MAX_DIRECTORY_BYTES
        || start.checked_add(size).is_none_or(|n| n > length - 22)
        || end[4..8] != [0; 4]
        || end[8..10] != end[10..12]
    {
        return Err(invalid());
    }
    file.seek(SeekFrom::Start(0)).map_err(|_| io_error())?;
    Ok(())
}
fn check_size(width: usize, height: usize) -> BooruResult<()> {
    if width == 0
        || height == 0
        || width > 16384
        || height > 16384
        || width.checked_mul(height).is_none_or(|n| n > MAX_PIXELS)
    {
        Err(error("booru.error.ugoiraFrameTooLarge"))
    } else {
        Ok(())
    }
}
fn decode(bytes: &[u8]) -> BooruResult<(Vec<u8>, u32, u32)> {
    if bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
        if bytes.len() < 24 {
            return Err(error("booru.error.ugoiraFrameCorrupt"));
        }
        check_size(
            u32::from_be_bytes(bytes[16..20].try_into().unwrap()) as usize,
            u32::from_be_bytes(bytes[20..24].try_into().unwrap()) as usize,
        )?;
        let image =
            lodepng::decode32(bytes).map_err(|_| error("booru.error.ugoiraFrameCorrupt"))?;
        let pixels = image
            .buffer
            .into_iter()
            .flat_map(|p| [p.r, p.g, p.b, p.a])
            .collect();
        Ok((pixels, image.width as u32, image.height as u32))
    } else if bytes.starts_with(&[0xFF, 0xD8]) {
        let mut decoder = JpegDecoder::new(ZCursor::new(bytes));
        let options = decoder
            .options()
            .jpeg_set_out_colorspace(ColorSpace::RGBA)
            .set_max_width(16384)
            .set_max_height(16384);
        decoder.set_options(options);
        decoder
            .decode_headers()
            .map_err(|_| error("booru.error.ugoiraFrameCorrupt"))?;
        let (w, h) = decoder
            .dimensions()
            .ok_or_else(|| error("booru.error.ugoiraFrameCorrupt"))?;
        check_size(w, h)?;
        let pixels = decoder
            .decode()
            .map_err(|_| error("booru.error.ugoiraFrameCorrupt"))?;
        if pixels.len() != w * h * 4 {
            return Err(error("booru.error.ugoiraFrameCorrupt"));
        }
        Ok((pixels, w as u32, h as u32))
    } else {
        Err(error("booru.error.ugoiraFrameCorrupt"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;
    fn archive(root: &Path, metadata: Option<&str>, sizes: &[(usize, usize)]) -> PathBuf {
        let path = root.join("frames.zip");
        let mut z = zip::ZipWriter::new(File::create(&path).unwrap());
        let options = zip::write::SimpleFileOptions::default();
        if let Some(json) = metadata {
            z.start_file("animation.json", options).unwrap();
            z.write_all(json.as_bytes()).unwrap();
        }
        for (i, &(w, h)) in sizes.iter().enumerate() {
            let pixels: Vec<u8> = (0..w * h)
                .flat_map(|n| [n as u8, 80, 255, if n % 2 == 0 { 0 } else { 127 }])
                .collect();
            let png = lodepng::encode_memory(&pixels, w, h, lodepng::ColorType::RGBA, 8).unwrap();
            z.start_file(format!("{i}.png"), options).unwrap();
            z.write_all(&png).unwrap();
        }
        z.finish().unwrap();
        path
    }
    const META: &str = r#"{"frames":[{"file":"0.png","delay":100},{"file":"1.png","delay":240}]}"#;
    #[test]
    fn lossless_animation_keeps_pixels_alpha_sizes_and_delays() {
        let dir = tempfile::tempdir().unwrap();
        let input = archive(dir.path(), Some(META), &[(4, 3), (4, 3)]);
        let output = dir.path().join("out.webp");
        let mut steps = Vec::new();
        export(&input, &output, &CancellationToken::new(), |n, _| {
            steps.push(n);
            Ok(())
        })
        .unwrap();
        let bytes = std::fs::read(output).unwrap();
        assert_eq!(
            u32::from_le_bytes(bytes[4..8].try_into().unwrap()) as usize,
            bytes.len() - 8
        );
        let mut decoder = image_webp::WebPDecoder::new(Cursor::new(bytes)).unwrap();
        assert_eq!(decoder.dimensions(), (4, 3));
        assert_eq!(decoder.num_frames(), 2);
        let expected: Vec<u8> = (0..12)
            .flat_map(|n| [n as u8, 80, 255, if n % 2 == 0 { 0 } else { 127 }])
            .collect();
        let mut pixels = vec![0; 48];
        assert_eq!(decoder.read_frame(&mut pixels).unwrap(), 100);
        assert_eq!(pixels, expected);
        assert_eq!(decoder.read_frame(&mut pixels).unwrap(), 240);
        assert_eq!(pixels, expected);
        assert_eq!(steps.last(), Some(&2));
    }
    #[test]
    fn missing_metadata_mismatched_sizes_and_cancel_do_not_publish() {
        let dir = tempfile::tempdir().unwrap();
        let output = dir.path().join("out.webp");
        let token = CancellationToken::new();
        let input = archive(dir.path(), None, &[(4, 3)]);
        assert_eq!(
            export(&input, &output, &token, |_, _| Ok(()))
                .unwrap_err()
                .user_message_key,
            "booru.error.ugoiraMetadataMissing"
        );
        let input = archive(dir.path(), Some(META), &[(4, 3), (3, 4)]);
        assert_eq!(
            export(&input, &output, &token, |_, _| Ok(()))
                .unwrap_err()
                .user_message_key,
            "booru.error.ugoiraFrameSizeMismatch"
        );
        let input = archive(dir.path(), Some(META), &[(4, 3), (4, 3)]);
        let result = export(&input, &output, &token, |n, _| {
            if n == 1 {
                token.cancel();
            }
            Ok(())
        });
        assert_eq!(result.unwrap_err().code, BooruErrorCode::Cancelled);
        assert!(!output.exists());
        assert!(!output.with_extension("webp.part").exists());
        assert!(input.exists());
    }
    #[test]
    fn invalid_delays_missing_or_corrupt_frame_are_explicit_errors() {
        for (metadata, sizes, key) in [
            (
                r#"{"frames":[{"file":"0.png","delay":0}]}"#,
                vec![(1, 1)],
                "ugoiraInvalidMetadata",
            ),
            (META, vec![(1, 1)], "ugoiraFrameMissing"),
        ] {
            let dir = tempfile::tempdir().unwrap();
            let input = archive(dir.path(), Some(metadata), &sizes);
            assert_eq!(
                export(
                    &input,
                    &dir.path().join("out.webp"),
                    &CancellationToken::new(),
                    |_, _| Ok(())
                )
                .unwrap_err()
                .user_message_key,
                format!("booru.error.{key}")
            );
        }
        assert_eq!(
            decode(b"not a frame").unwrap_err().user_message_key,
            "booru.error.ugoiraFrameCorrupt"
        );
        assert!(check_size(100_000, 100_000).is_err());
    }
    #[test]
    fn jpeg_frames_use_the_same_lossless_pixel_path() {
        let dir = tempfile::tempdir().unwrap();
        let jpg = include_bytes!("../../../../test/fixtures/media/test_frame.jpg");
        let (expected, w, h) = decode(jpg).unwrap();
        let input = dir.path().join("jpeg.zip");
        let mut z = zip::ZipWriter::new(File::create(&input).unwrap());
        let options = zip::write::SimpleFileOptions::default();
        z.start_file("animation.json", options).unwrap();
        z.write_all(br#"{"frames":[{"file":"frame.jpg","delay":80}]}"#)
            .unwrap();
        z.start_file("frame.jpg", options).unwrap();
        z.write_all(jpg).unwrap();
        z.finish().unwrap();
        let output = dir.path().join("out.webp");
        export(&input, &output, &CancellationToken::new(), |_, _| Ok(())).unwrap();
        let mut decoder =
            image_webp::WebPDecoder::new(Cursor::new(std::fs::read(output).unwrap())).unwrap();
        assert_eq!(decoder.dimensions(), (w, h));
        let mut actual = vec![0; expected.len()];
        decoder.read_frame(&mut actual).unwrap();
        assert_eq!(actual, expected);
    }
    #[test]
    fn oversized_directory_is_rejected_before_archive_index_allocation() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("bad.zip");
        let mut bytes = vec![0; 22];
        bytes[..4].copy_from_slice(&[80, 75, 5, 6]);
        bytes[8..12].copy_from_slice(&[255; 4]);
        std::fs::write(&path, &bytes).unwrap();
        assert!(validate_archive_directory(&mut File::open(path).unwrap()).is_err());
    }

    /// Explicit public-sample acceptance, not part of the offline suite.
    #[test]
    #[ignore = "R7 public sample/benchmark paths supplied by environment"]
    fn public_sample_benchmark() {
        let input = PathBuf::from(std::env::var("R7_UGOIRA_ZIP").unwrap());
        let output = PathBuf::from(std::env::var("R7_UGOIRA_WEBP").unwrap());
        let start = std::time::Instant::now();
        export(&input, &output, &CancellationToken::new(), |_, _| Ok(())).unwrap();
        println!(
            "R7 image-webp: {} bytes, {} ms",
            std::fs::metadata(output).unwrap().len(),
            start.elapsed().as_millis()
        );
    }
}
