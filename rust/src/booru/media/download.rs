use crate::api::booru_download::PreparedDownload;
#[cfg(test)]
use crate::api::booru_models::ChecksumAlgorithm;
use crate::api::booru_models::{MediaType, MediaVariantKind};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use crate::booru::network::{NetworkRuntime, RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use reqwest::header::{LOCATION, SET_COOKIE};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq)]
pub struct DownloadProgress {
    pub received: u64,
    pub total: Option<u64>,
    pub progress: f64,
}

pub(crate) fn destination_for_content_type(
    destination: &Path,
    content_type: Option<MediaType>,
) -> PathBuf {
    let extension = match content_type {
        Some(MediaType::Jpeg) => Some("jpg"),
        Some(MediaType::Png) => Some("png"),
        Some(MediaType::Gif) => Some("gif"),
        Some(MediaType::Webp) => Some("webp"),
        Some(MediaType::Avif) => Some("avif"),
        Some(MediaType::Mp4) => Some("mp4"),
        Some(MediaType::Webm) => Some("webm"),
        _ => None,
    };
    extension
        .map(|extension| destination.with_extension(extension))
        .unwrap_or_else(|| destination.to_owned())
}

pub(crate) async fn replace_file(
    part_path: &Path,
    destination: &Path,
    source_id: &str,
) -> BooruResult<()> {
    let filename = destination
        .file_name()
        .and_then(|value| value.to_str())
        .ok_or_else(|| BooruError::invalid_request(Some(source_id)))?;
    let backup = destination.with_file_name(format!(".{filename}.backup"));
    let destination_exists = tokio::fs::try_exists(destination).await.unwrap_or(false);
    let backup_exists = tokio::fs::try_exists(&backup).await.unwrap_or(false);
    if backup_exists && !destination_exists {
        tokio::fs::rename(&backup, destination)
            .await
            .map_err(|_| io_error(source_id))?;
    } else if backup_exists {
        tokio::fs::remove_file(&backup)
            .await
            .map_err(|_| io_error(source_id))?;
    }
    if tokio::fs::try_exists(destination).await.unwrap_or(false) {
        tokio::fs::rename(destination, &backup)
            .await
            .map_err(|_| io_error(source_id))?;
    }
    if tokio::fs::rename(part_path, destination).await.is_err() {
        let _ = tokio::fs::rename(&backup, destination).await;
        return Err(io_error(source_id));
    }
    if tokio::fs::try_exists(&backup).await.unwrap_or(false) {
        tokio::fs::remove_file(backup)
            .await
            .map_err(|_| io_error(source_id))?;
    }
    Ok(())
}

pub(crate) async fn open_prepared(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
) -> BooruResult<reqwest::Response> {
    open_prepared_inner(runtime, source, prepared, true, None, None).await
}

pub(crate) async fn open_prepared_unthrottled(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
) -> BooruResult<reqwest::Response> {
    open_prepared_inner(runtime, source, prepared, false, None, None).await
}

pub(crate) async fn open_prepared_resume(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    range: &str,
    validator: &str,
) -> BooruResult<reqwest::Response> {
    open_prepared_inner(
        runtime,
        source,
        prepared,
        true,
        Some(range),
        Some(validator),
    )
    .await
}

async fn open_prepared_inner(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    throttle: bool,
    range: Option<&str>,
    validator: Option<&str>,
) -> BooruResult<reqwest::Response> {
    let url = reqwest::Url::parse(&prepared.url)
        .map_err(|_| BooruError::invalid_request(Some(source.id)))?;
    let mut spec = RequestSpec::get(url.clone(), ResponseKind::Media);
    spec.headers = prepared
        .headers
        .iter()
        .filter(|header| {
            !matches!(
                header.name.to_ascii_lowercase().as_str(),
                "cookie" | "authorization" | "user-agent" | "x-api-key"
            )
        })
        .map(|header| (header.name.clone(), header.value.clone()))
        .collect();
    if let Some(range) = range {
        spec.headers.push(("range".into(), range.into()));
        spec.headers
            .push(("accept-encoding".into(), "identity".into()));
    }
    if let Some(validator) = validator {
        spec.headers.push(("if-range".into(), validator.into()));
    }
    spec.allow_protected_headers = true;
    if source.id != "anime_pictures" || prepared.variant != MediaVariantKind::Original {
        return open_media(runtime, source, spec, throttle).await;
    }

    spec.follow_redirects = false;
    let auth_revision = runtime.auth_state(source.id)?.auth_revision;
    let response = open_media(runtime, source, spec, throttle).await?;
    if !response.status().is_redirection() {
        return Ok(response);
    }
    let location = response
        .headers()
        .get(LOCATION)
        .and_then(|value| value.to_str().ok())
        .ok_or_else(|| unsafe_redirect(source.id))?;
    let target = url.join(location).map_err(|_| unsafe_redirect(source.id))?;
    let temporary_cookie = response
        .headers()
        .get_all(SET_COOKIE)
        .iter()
        .filter_map(|value| value.to_str().ok())
        .filter_map(|value| value.split(';').next())
        .filter(|value| value.contains('='))
        .collect::<Vec<_>>()
        .join("; ");
    let mut redirected = RequestSpec::get(target, ResponseKind::Media);
    redirected.expected_auth_revision = Some(auth_revision);
    if runtime.auth_state(source.id)?.auth_revision != auth_revision {
        return Err(BooruError::new(
            BooruErrorCode::Cancelled,
            Some(source.id),
            "booru.error.cancelled",
        ));
    }
    let redirect_cookie = if temporary_cookie.is_empty() {
        "sitelang=en".to_owned()
    } else {
        format!("sitelang=en; {temporary_cookie}")
    };
    redirected
        .headers
        .push(("cookie".to_owned(), redirect_cookie));
    if let Some(range) = range {
        redirected.headers.push(("range".into(), range.into()));
        redirected
            .headers
            .push(("accept-encoding".into(), "identity".into()));
    }
    if let Some(validator) = validator {
        redirected
            .headers
            .push(("if-range".into(), validator.into()));
    }
    redirected.allow_protected_headers = true;
    open_media(runtime, source, redirected, throttle).await
}

async fn open_media(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    spec: RequestSpec,
    throttle: bool,
) -> BooruResult<reqwest::Response> {
    if throttle {
        runtime.open_media(source, spec).await
    } else {
        runtime.open_media_unthrottled(source, spec).await
    }
}

pub(crate) fn progress(received: u64, total: Option<u64>) -> DownloadProgress {
    let ratio = total
        .filter(|total| *total > 0)
        .map(|total| received as f64 / total as f64)
        .unwrap_or(0.0)
        .clamp(0.0, 1.0);
    DownloadProgress {
        received,
        total,
        progress: ratio,
    }
}

pub(crate) fn part_path(destination: &Path) -> BooruResult<PathBuf> {
    let filename = destination
        .file_name()
        .and_then(|value| value.to_str())
        .filter(|value| !value.is_empty())
        .ok_or_else(|| BooruError::invalid_request(None))?;
    Ok(destination.with_file_name(format!(".{filename}.part")))
}

pub(crate) fn validation_error(source_id: &str, key: &str) -> BooruError {
    BooruError::new(BooruErrorCode::MediaValidationFailed, Some(source_id), key)
}

pub(crate) fn io_error(source_id: &str) -> BooruError {
    BooruError::new(
        BooruErrorCode::Internal,
        Some(source_id),
        "booru.error.fileIo",
    )
}

fn unsafe_redirect(source_id: &str) -> BooruError {
    BooruError::new(
        BooruErrorCode::UnsafeRedirect,
        Some(source_id),
        "booru.error.invalidRedirect",
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn opaque_originals_preserve_extension_and_video_mime_never_becomes_an_image() {
        for file in ["42.zip", "42.swf", "42.unknown"] {
            assert_eq!(
                destination_for_content_type(Path::new(file), None),
                Path::new(file)
            );
        }
        assert_eq!(
            destination_for_content_type(Path::new("42.bin"), Some(MediaType::Mp4)),
            Path::new("42.mp4")
        );
        assert_eq!(
            destination_for_content_type(Path::new("42.bin"), Some(MediaType::Webm)),
            Path::new("42.webm")
        );
    }

    #[test]
    fn progress_supports_lengths_above_four_gib() {
        let total = 8_u64 * 1024 * 1024 * 1024;
        let event = progress(total / 2, Some(total));
        assert_eq!(event.received, 4_u64 * 1024 * 1024 * 1024);
        assert_eq!(event.progress, 0.5);
    }

    #[test]
    fn checksum_algorithm_is_copyable_for_stream_setup() {
        let algorithm = ChecksumAlgorithm::Sha256;
        assert_eq!(algorithm, ChecksumAlgorithm::Sha256);
    }

    #[test]
    fn verified_mime_controls_final_extension() {
        assert_eq!(
            destination_for_content_type(Path::new("42.bin"), Some(MediaType::Jpeg)),
            PathBuf::from("42.jpg")
        );
    }

    #[tokio::test]
    async fn replacement_preserves_a_complete_destination() {
        let directory = tempfile::tempdir().unwrap();
        let destination = directory.path().join("42.jpg");
        let part = directory.path().join(".42.jpg.part");
        tokio::fs::write(&destination, b"old").await.unwrap();
        tokio::fs::write(&part, b"new").await.unwrap();
        replace_file(&part, &destination, "yande").await.unwrap();
        assert_eq!(tokio::fs::read(&destination).await.unwrap(), b"new");
        assert!(
            !tokio::fs::try_exists(directory.path().join(".42.jpg.backup"))
                .await
                .unwrap()
        );
    }
}
