use crate::booru::error::{BooruErrorCode, BooruErrorDto, BooruResult};

const MAX_AVIF_INPUT_BYTES: usize = 32 * 1024 * 1024;
const MAX_PREVIEW_PIXELS: usize = 36_000_000;

pub fn avif_to_png(source_id: &str, input: &[u8]) -> BooruResult<Vec<u8>> {
    if input.is_empty() || input.len() > MAX_AVIF_INPUT_BYTES {
        return Err(transcode_error(source_id));
    }
    let image = avif_rust::image_from_bytes(input).map_err(|_| transcode_error(source_id))?;
    validate_dimensions(source_id, image.width, image.height)?;
    lodepng::encode_memory(
        &image.rgba,
        image.width,
        image.height,
        lodepng::ColorType::RGBA,
        8,
    )
    .map_err(|_| transcode_error(source_id))
}

fn validate_dimensions(source_id: &str, width: usize, height: usize) -> BooruResult<()> {
    width
        .checked_mul(height)
        .filter(|pixels| *pixels > 0 && *pixels <= MAX_PREVIEW_PIXELS)
        .ok_or_else(|| transcode_error(source_id))?;
    Ok(())
}

fn transcode_error(source_id: &str) -> BooruErrorDto {
    BooruErrorDto::new(
        BooruErrorCode::MediaValidationFailed,
        Some(source_id),
        "booru.error.imageDecodeFailed",
    )
}
