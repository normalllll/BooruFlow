use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};

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

fn transcode_error(source_id: &str) -> BooruError {
    BooruError::new(
        BooruErrorCode::MediaValidationFailed,
        Some(source_id),
        "booru.error.imageDecodeFailed",
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn avif_preview_is_converted_to_platform_independent_png() {
        let input = include_bytes!("../../../../test/fixtures/media/white.avif");
        let png = avif_to_png("anime_pictures", input).unwrap();
        let image = lodepng::decode32(&png).unwrap();
        assert_eq!((image.width, image.height), (16, 16));
        assert!(image
            .buffer
            .iter()
            .all(|pixel| pixel.r > 250 && pixel.g > 250 && pixel.b > 250 && pixel.a == 255));
    }
}
