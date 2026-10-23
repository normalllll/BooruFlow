use crate::api::booru_download::PreparedDownload;
use crate::api::booru_models::{MediaType, MediaVariantKind};
use crate::booru::adapter::PreparedMedia;
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::media::validation::validate_filename_component;

pub fn prepared_download(
    source_id: &str,
    post_id: &str,
    variant: MediaVariantKind,
    prepared: PreparedMedia,
) -> BooruResult<PreparedDownload> {
    validate_filename_component(source_id, source_id)?;
    validate_filename_component(source_id, post_id)?;
    let extension = prepared
        .media
        .extension
        .as_deref()
        .map(|value| value.trim_start_matches('.').to_ascii_lowercase())
        .filter(|value| !value.is_empty() && value.bytes().all(|byte| byte.is_ascii_alphanumeric()))
        .or_else(|| {
            match prepared.media.media_type {
                Some(MediaType::Jpeg) => Some("jpg"),
                Some(MediaType::Png) => Some("png"),
                Some(MediaType::Gif) => Some("gif"),
                Some(MediaType::Webp) => Some("webp"),
                Some(MediaType::Avif) => Some("avif"),
                Some(MediaType::Mp4) => Some("mp4"),
                Some(MediaType::Webm) => Some("webm"),
                _ => None,
            }
            .map(str::to_owned)
        })
        .unwrap_or_else(|| "bin".to_owned());
    let variant_suffix = match variant {
        MediaVariantKind::Original => String::new(),
        MediaVariantKind::Thumbnail => "_thumbnail".to_owned(),
        MediaVariantKind::Preview => "_preview".to_owned(),
        MediaVariantKind::Sample => "_sample".to_owned(),
    };
    let filename = format!("{post_id}{variant_suffix}.{extension}");
    validate_filename_component(source_id, &filename)?;
    // No declared image/video kind means an opaque original file (for example
    // Ugoira ZIP or Flash), not an implicit image. Preserve its real extension.
    let allowed_media_kinds = prepared
        .media
        .media_type
        .map(MediaType::kind)
        .into_iter()
        .collect();
    if reqwest::Url::parse(&prepared.media.url).is_err() {
        return Err(BooruError::invalid_response(source_id));
    }
    Ok(PreparedDownload {
        source_id: source_id.to_owned(),
        post_id: post_id.to_owned(),
        variant,
        url: prepared.media.url,
        headers: prepared.headers,
        expected_bytes_decimal: prepared.media.byte_length.map(|value| value.to_string()),
        allowed_media_kinds,
        checksum: prepared.media.checksum,
        filename,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::booru_models::MediaVariantKind;
    use crate::booru::model::MediaVariant;

    #[test]
    fn originals_keep_their_real_extension_and_declared_kind() {
        for (extension, media_type) in [
            ("mp4", Some(MediaType::Mp4)),
            ("webm", Some(MediaType::Webm)),
            ("zip", None),
            ("swf", None),
            ("unknown", None),
        ] {
            let prepared = PreparedMedia {
                media: MediaVariant {
                    kind: MediaVariantKind::Original,
                    url: format!("https://cdn.donmai.us/file.{extension}"),
                    width: None,
                    height: None,
                    byte_length: Some(12),
                    media_type,
                    extension: Some(extension.to_owned()),
                    checksum: None,
                },
                headers: Vec::new(),
            };
            let result =
                prepared_download("danbooru", "12408475", MediaVariantKind::Original, prepared)
                    .unwrap();
            assert_eq!(result.filename, format!("12408475.{extension}"));
            assert_eq!(
                result.allowed_media_kinds,
                media_type
                    .map(MediaType::kind)
                    .into_iter()
                    .collect::<Vec<_>>()
            );
            assert_eq!(result.expected_bytes_decimal.as_deref(), Some("12"));
        }
    }

    #[test]
    fn source_aware_filename_uses_variant_suffix() {
        let prepared = PreparedMedia {
            media: MediaVariant {
                kind: MediaVariantKind::Sample,
                url: "https://files.yande.re/a.jpg".to_owned(),
                width: None,
                height: None,
                byte_length: None,
                media_type: Some(MediaType::Jpeg),
                extension: Some("jpg".to_owned()),
                checksum: None,
            },
            headers: Vec::new(),
        };
        assert_eq!(
            prepared_download("yande", "123", MediaVariantKind::Sample, prepared)
                .unwrap()
                .filename,
            "123_sample.jpg"
        );
    }
}
