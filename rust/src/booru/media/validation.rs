use crate::api::booru_models::{ChecksumAlgorithm, MediaKind, MediaType};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use md5::Md5;
use sha2::{Digest, Sha256};

pub enum StreamingChecksum {
    None,
    Md5(Md5),
    Sha256(Sha256),
}

impl StreamingChecksum {
    pub fn new(algorithm: Option<ChecksumAlgorithm>) -> Self {
        match algorithm {
            None => Self::None,
            Some(ChecksumAlgorithm::Md5) => Self::Md5(Md5::new()),
            Some(ChecksumAlgorithm::Sha256) => Self::Sha256(Sha256::new()),
        }
    }

    pub fn update(&mut self, bytes: &[u8]) {
        match self {
            Self::None => {}
            Self::Md5(hasher) => hasher.update(bytes),
            Self::Sha256(hasher) => hasher.update(bytes),
        }
    }

    pub fn finish(self) -> Option<String> {
        match self {
            Self::None => None,
            Self::Md5(hasher) => Some(
                hasher
                    .finalize()
                    .as_slice()
                    .iter()
                    .map(|byte| format!("{byte:02x}"))
                    .collect(),
            ),
            Self::Sha256(hasher) => Some(
                hasher
                    .finalize()
                    .as_slice()
                    .iter()
                    .map(|byte| format!("{byte:02x}"))
                    .collect(),
            ),
        }
    }
}

pub fn validate_content_type(
    source_id: &str,
    actual: Option<&str>,
    allowed: &[MediaKind],
) -> BooruResult<MediaType> {
    let actual = actual
        .and_then(|value| value.split(';').next())
        .map(str::trim)
        .map(str::to_ascii_lowercase)
        .filter(|value| !value.is_empty())
        .ok_or_else(|| validation_error(source_id, "booru.error.missingContentType"))?;
    if actual == "text/html" || actual == "application/xhtml+xml" {
        return Err(BooruError::new(
            BooruErrorCode::ChallengeRequired,
            Some(source_id),
            "booru.error.challengeRequired",
        ));
    }
    let actual = MediaType::from_mime(&actual)
        .ok_or_else(|| validation_error(source_id, "booru.error.invalidMediaType"))?;
    if allowed.contains(&actual.kind()) {
        Ok(actual)
    } else {
        Err(validation_error(source_id, "booru.error.invalidMediaType"))
    }
}

/// Image streams reject a declared video response before yielding any bytes.
/// Preserve legacy image hosts that omit MIME or use octet-stream; known video
/// is deterministic and must never be handed to Flutter's image codec.
pub fn validate_image_preview_content_type(
    source_id: &str,
    actual: Option<&str>,
) -> BooruResult<()> {
    if actual.and_then(MediaType::from_mime).map(MediaType::kind) == Some(MediaKind::Video) {
        return Err(BooruError::new(
            BooruErrorCode::MediaValidationFailed,
            Some(source_id),
            "booru.error.previewUnsupported",
        ));
    }
    Ok(())
}

/// Opaque originals retain filename/length/checksum validation. They must not
/// be forced through an image decoder or saved under an image extension.
/// HTML remains a challenge response, never a successful opaque download.
pub fn validate_download_content_type(
    source_id: &str,
    actual: Option<&str>,
    allowed: &[MediaKind],
) -> BooruResult<Option<MediaType>> {
    if !allowed.is_empty() {
        return validate_content_type(source_id, actual, allowed).map(Some);
    }
    let actual = actual
        .and_then(|value| value.split(';').next())
        .map(str::trim)
        .map(str::to_ascii_lowercase)
        .filter(|value| !value.is_empty())
        .ok_or_else(|| validation_error(source_id, "booru.error.missingContentType"))?;
    if actual == "text/html" || actual == "application/xhtml+xml" {
        return Err(BooruError::new(
            BooruErrorCode::ChallengeRequired,
            Some(source_id),
            "booru.error.challengeRequired",
        ));
    }
    Ok(MediaType::from_mime(&actual))
}

pub fn validate_filename_component(source_id: &str, value: &str) -> BooruResult<()> {
    let valid = !value.is_empty()
        && value != "."
        && value != ".."
        && value
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'_' | b'-'))
        && !is_windows_device_name(value);
    if valid {
        Ok(())
    } else {
        Err(BooruError::invalid_request(Some(source_id)))
    }
}

fn is_windows_device_name(value: &str) -> bool {
    let stem = value
        .split('.')
        .next()
        .unwrap_or_default()
        .to_ascii_uppercase();
    matches!(stem.as_str(), "CON" | "PRN" | "AUX" | "NUL")
        || stem
            .strip_prefix("COM")
            .or_else(|| stem.strip_prefix("LPT"))
            .is_some_and(|suffix| {
                suffix
                    .parse::<u8>()
                    .is_ok_and(|number| (1..=9).contains(&number))
            })
}

fn validation_error(source_id: &str, key: &str) -> BooruError {
    BooruError::new(BooruErrorCode::MediaValidationFailed, Some(source_id), key)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn image_streams_reject_video_before_decoding() {
        for mime in ["video/mp4", "video/webm", "video/quicktime"] {
            assert_eq!(
                validate_image_preview_content_type("danbooru", Some(mime))
                    .unwrap_err()
                    .user_message_key,
                "booru.error.previewUnsupported"
            );
        }
        for mime in [
            None,
            Some("image/jpeg"),
            Some("image/avif"),
            Some("application/octet-stream"),
        ] {
            assert!(validate_image_preview_content_type("danbooru", mime).is_ok());
        }
    }

    #[test]
    fn opaque_originals_accept_files_but_never_html_challenges() {
        for mime in [
            "application/zip",
            "application/x-shockwave-flash",
            "application/octet-stream",
        ] {
            assert_eq!(
                validate_download_content_type("danbooru", Some(mime), &[]).unwrap(),
                None
            );
            assert!(
                validate_download_content_type("danbooru", Some(mime), &[MediaKind::Image])
                    .is_err()
            );
        }
        for mime in ["text/html", "application/xhtml+xml"] {
            assert_eq!(
                validate_download_content_type("danbooru", Some(mime), &[])
                    .unwrap_err()
                    .code,
                BooruErrorCode::ChallengeRequired
            );
        }
        assert!(validate_download_content_type("danbooru", None, &[]).is_err());
    }

    #[test]
    fn validates_wildcard_media_type() {
        assert_eq!(
            validate_content_type(
                "yande",
                Some("image/jpeg; charset=binary"),
                &[MediaKind::Image]
            )
            .unwrap(),
            MediaType::Jpeg
        );
        assert!(validate_content_type("yande", Some("text/html"), &[MediaKind::Image]).is_err());
    }

    #[test]
    fn path_components_reject_traversal_and_devices() {
        assert!(validate_filename_component("yande", "123-abc_2").is_ok());
        assert!(validate_filename_component("yande", "../x").is_err());
        assert!(validate_filename_component("yande", "CON.jpg").is_err());
    }

    #[test]
    fn streaming_checksums_match_known_values() {
        let mut md5 = StreamingChecksum::new(Some(ChecksumAlgorithm::Md5));
        md5.update(b"hello");
        assert_eq!(
            md5.finish().as_deref(),
            Some("5d41402abc4b2a76b9719d911017c592")
        );

        let mut sha256 = StreamingChecksum::new(Some(ChecksumAlgorithm::Sha256));
        sha256.update(b"hello");
        assert_eq!(
            sha256.finish().as_deref(),
            Some("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        );
    }
}
