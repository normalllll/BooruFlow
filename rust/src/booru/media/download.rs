use crate::api::booru_download::PreparedDownload;
#[cfg(test)]
use crate::api::booru_models::ChecksumAlgorithm;
use crate::api::booru_models::{MediaType, MediaVariantKind};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use crate::booru::media::validation::{validate_content_type, StreamingChecksum};
use crate::booru::network::{NetworkRuntime, RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use futures_util::StreamExt;
use reqwest::header::{CONTENT_LENGTH, CONTENT_TYPE, LOCATION, SET_COOKIE};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};
use tokio::io::AsyncWriteExt;

#[derive(Debug, Clone, PartialEq)]
pub struct DownloadProgress {
    pub received: u64,
    pub total: Option<u64>,
    pub progress: f64,
}

pub async fn download_to_path<F>(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    destination: &Path,
    mut on_progress: F,
) -> BooruResult<PathBuf>
where
    F: FnMut(DownloadProgress) -> BooruResult<()>,
{
    let part_path = part_path(destination)?;
    if let Some(parent) = part_path.parent() {
        tokio::fs::create_dir_all(parent)
            .await
            .map_err(|_| io_error(source.id))?;
    }
    let result = download_inner(
        runtime,
        source,
        prepared,
        destination,
        &part_path,
        &mut on_progress,
    )
    .await;
    if result.is_err() {
        let _ = tokio::fs::remove_file(&part_path).await;
    }
    result
}

async fn download_inner<F>(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    destination: &Path,
    part_path: &Path,
    on_progress: &mut F,
) -> BooruResult<PathBuf>
where
    F: FnMut(DownloadProgress) -> BooruResult<()>,
{
    let response = open_prepared(runtime, source, prepared).await?;
    let actual_content_type = response
        .headers()
        .get(CONTENT_TYPE)
        .and_then(|value| value.to_str().ok());
    let actual_content_type = validate_content_type(
        source.id,
        actual_content_type,
        &prepared.allowed_media_kinds,
    )?;
    let actual_destination = destination_for_content_type(destination, actual_content_type);
    let declared_length = response
        .headers()
        .get(CONTENT_LENGTH)
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.parse::<u64>().ok())
        .or_else(|| response.content_length());
    let expected_length = prepared
        .expected_bytes_decimal
        .as_deref()
        .map(|value| value.parse::<u64>())
        .transpose()
        .map_err(|_| BooruError::invalid_request(Some(source.id)))?;
    if let (Some(expected), Some(actual)) = (expected_length, declared_length) {
        if expected != actual {
            return Err(validation_error(source.id, "booru.error.lengthMismatch"));
        }
    }
    let total = expected_length.or(declared_length);
    let mut file = tokio::fs::File::create(part_path)
        .await
        .map_err(|_| io_error(source.id))?;
    let checksum_algorithm = prepared
        .checksum
        .as_ref()
        .map(|checksum| checksum.algorithm);
    let mut checksum = StreamingChecksum::new(checksum_algorithm);
    let mut stream = response.bytes_stream();
    let mut received = 0_u64;
    let mut last_emit = Instant::now() - Duration::from_secs(1);
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|error| {
            if error.is_timeout() {
                BooruError::new(
                    BooruErrorCode::Timeout,
                    Some(source.id),
                    "booru.error.timeout",
                )
            } else {
                BooruError::new(
                    BooruErrorCode::Network,
                    Some(source.id),
                    "booru.error.network",
                )
            }
        })?;
        file.write_all(&chunk)
            .await
            .map_err(|_| io_error(source.id))?;
        checksum.update(&chunk);
        received = received.saturating_add(chunk.len() as u64);
        if last_emit.elapsed() >= Duration::from_millis(250) || total == Some(received) {
            last_emit = Instant::now();
            on_progress(progress(received, total))?;
        }
    }
    file.flush().await.map_err(|_| io_error(source.id))?;
    file.sync_all().await.map_err(|_| io_error(source.id))?;
    drop(file);
    if received == 0 {
        return Err(validation_error(source.id, "booru.error.emptyDownload"));
    }
    if let Some(expected) = total {
        if expected != received {
            return Err(validation_error(source.id, "booru.error.lengthMismatch"));
        }
    }
    if let (Some(expected), Some(actual)) = (prepared.checksum.as_ref(), checksum.finish()) {
        if !expected.value.eq_ignore_ascii_case(&actual) {
            return Err(validation_error(source.id, "booru.error.checksumMismatch"));
        }
    }
    replace_file(part_path, &actual_destination, source.id).await?;
    on_progress(progress(received, Some(received)))?;
    Ok(actual_destination)
}

fn destination_for_content_type(destination: &Path, content_type: MediaType) -> PathBuf {
    let extension = match content_type {
        MediaType::Jpeg => Some("jpg"),
        MediaType::Png => Some("png"),
        MediaType::Gif => Some("gif"),
        MediaType::Webp => Some("webp"),
        MediaType::Avif => Some("avif"),
        MediaType::Mp4 => Some("mp4"),
        MediaType::Webm => Some("webm"),
        _ => None,
    };
    extension
        .map(|extension| destination.with_extension(extension))
        .unwrap_or_else(|| destination.to_owned())
}

async fn replace_file(part_path: &Path, destination: &Path, source_id: &str) -> BooruResult<()> {
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
    open_prepared_inner(runtime, source, prepared, true).await
}

pub(crate) async fn open_prepared_unthrottled(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
) -> BooruResult<reqwest::Response> {
    open_prepared_inner(runtime, source, prepared, false).await
}

async fn open_prepared_inner(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    throttle: bool,
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

fn progress(received: u64, total: Option<u64>) -> DownloadProgress {
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

fn part_path(destination: &Path) -> BooruResult<PathBuf> {
    let filename = destination
        .file_name()
        .and_then(|value| value.to_str())
        .filter(|value| !value.is_empty())
        .ok_or_else(|| BooruError::invalid_request(None))?;
    Ok(destination.with_file_name(format!(".{filename}.part")))
}

fn validation_error(source_id: &str, key: &str) -> BooruError {
    BooruError::new(BooruErrorCode::MediaValidationFailed, Some(source_id), key)
}

fn io_error(source_id: &str) -> BooruError {
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
            destination_for_content_type(Path::new("42.bin"), MediaType::Jpeg),
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
