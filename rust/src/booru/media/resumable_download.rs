use super::download::{
    destination_for_content_type, io_error, open_prepared, open_prepared_resume, part_path,
    progress, replace_file, validation_error,
};
use super::download_control::{cancelled, DownloadControl};
use super::validation::{validate_download_content_type, StreamingChecksum};
use crate::api::booru_download::{DownloadEvent, PreparedDownload};
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::network::NetworkRuntime;
use crate::booru::source::SourceDefinition;
use futures_util::StreamExt;
use reqwest::{
    header::{HeaderMap, CONTENT_LENGTH, CONTENT_RANGE, CONTENT_TYPE, ETAG, LAST_MODIFIED},
    StatusCode,
};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

#[derive(Default)]
struct Partial {
    validator: Option<String>,
    total: Option<u64>,
}

pub(crate) async fn download<F>(
    runtime: &NetworkRuntime,
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    destination: &Path,
    control: &DownloadControl,
    on_event: &mut F,
) -> BooruResult<PathBuf>
where
    F: FnMut(DownloadEvent) -> BooruResult<()>,
{
    download_with(
        source,
        prepared,
        destination,
        control,
        on_event,
        |resume| async move {
            match resume {
                Some((offset, validator)) => {
                    open_prepared_resume(
                        runtime,
                        source,
                        prepared,
                        &format!("bytes={offset}-"),
                        &validator,
                    )
                    .await
                }
                None => open_prepared(runtime, source, prepared).await,
            }
        },
    )
    .await
}

async fn download_with<F, Open, Fut>(
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    destination: &Path,
    control: &DownloadControl,
    on_event: &mut F,
    mut open: Open,
) -> BooruResult<PathBuf>
where
    F: FnMut(DownloadEvent) -> BooruResult<()>,
    Open: FnMut(Option<(u64, String)>) -> Fut,
    Fut: std::future::Future<Output = BooruResult<reqwest::Response>>,
{
    let part = part_path(destination)?;
    if let Some(parent) = part.parent() {
        tokio::fs::create_dir_all(parent)
            .await
            .map_err(|_| io_error(source.id))?;
    }
    // A new job never trusts an unassociated old partial or its credentials.
    let _ = tokio::fs::remove_file(&part).await;
    let mut partial = Partial::default();
    let mut resumed = false;
    let result = loop {
        if control.cancel.is_cancelled() {
            break Err(cancelled());
        }
        if control.is_paused() {
            if let Err(error) = on_event(DownloadEvent::Paused) {
                break Err(error);
            }
            if let Err(error) = control.running().await {
                break Err(error);
            }
            resumed = true;
        }
        match transfer(
            source,
            prepared,
            destination,
            &part,
            &mut partial,
            resumed,
            control,
            on_event,
            &mut open,
        )
        .await
        {
            Ok(Some(path)) => break Ok(path),
            Ok(None) => continue,
            Err(error) => break Err(error),
        }
    };
    if result.is_err() {
        let _ = tokio::fs::remove_file(&part).await;
    }
    result
}

async fn transfer<F, Open, Fut>(
    source: &SourceDefinition,
    prepared: &PreparedDownload,
    destination: &Path,
    part: &Path,
    partial: &mut Partial,
    resumed: bool,
    control: &DownloadControl,
    on_event: &mut F,
    open: &mut Open,
) -> BooruResult<Option<PathBuf>>
where
    F: FnMut(DownloadEvent) -> BooruResult<()>,
    Open: FnMut(Option<(u64, String)>) -> Fut,
    Fut: std::future::Future<Output = BooruResult<reqwest::Response>>,
{
    let previous = tokio::fs::metadata(part)
        .await
        .map(|m| m.len())
        .unwrap_or(0);
    let mut offset = previous;
    let mut response = if let Some(validator) = partial.validator.as_deref().filter(|_| offset > 0)
    {
        match open_interruptible(control, open, Some((offset, validator.to_owned()))).await {
            Ok(Some(response)) => response,
            Ok(None) => return Ok(None),
            Err(BooruError {
                http_status: Some(412 | 416),
                ..
            }) => {
                offset = 0;
                match open_interruptible(control, open, None).await? {
                    Some(response) => response,
                    None => return Ok(None),
                }
            }
            Err(error) => return Err(error),
        }
    } else {
        offset = 0;
        match open_interruptible(control, open, None).await? {
            Some(response) => response,
            None => return Ok(None),
        }
    };
    if offset > 0 && !valid_resume(response.status(), response.headers(), offset, partial) {
        offset = 0;
        // A 200 is the complete replacement representation, so reuse it.
        if response.status() != StatusCode::OK {
            drop(response);
            response = match open_interruptible(control, open, None).await? {
                Some(response) => response,
                None => return Ok(None),
            };
        }
    }
    if offset == 0 && response.status() != StatusCode::OK {
        return Err(validation_error(
            source.id,
            "booru.error.invalidRangeResponse",
        ));
    }
    let content_type = validate_download_content_type(
        source.id,
        response
            .headers()
            .get(CONTENT_TYPE)
            .and_then(|v| v.to_str().ok()),
        &prepared.allowed_media_kinds,
    )?;
    let actual_destination = destination_for_content_type(destination, content_type);
    let declared = response
        .headers()
        .get(CONTENT_LENGTH)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok())
        .or_else(|| response.content_length());
    let declared = declared.and_then(|n| n.checked_add(offset));
    let expected = prepared
        .expected_bytes_decimal
        .as_deref()
        .map(str::parse::<u64>)
        .transpose()
        .map_err(|_| crate::booru::error::BooruError::invalid_request(Some(source.id)))?;
    if let (Some(a), Some(b)) = (expected, declared) {
        if a != b {
            return Err(validation_error(source.id, "booru.error.lengthMismatch"));
        }
    }
    let total = expected
        .or(declared)
        .or(if offset > 0 { partial.total } else { None });
    partial.total = total;
    partial.validator = validator(response.headers());
    if resumed {
        on_event(DownloadEvent::Resumed {
            restarted: previous > 0 && offset == 0,
        })?;
    }
    on_event(progress_event(offset, total))?;
    let mut checksum = StreamingChecksum::new(prepared.checksum.as_ref().map(|c| c.algorithm));
    if offset > 0 {
        let mut input = tokio::fs::File::open(part)
            .await
            .map_err(|_| io_error(source.id))?;
        let mut buffer = vec![0; 64 * 1024];
        loop {
            if control.is_paused() || control.cancel.is_cancelled() {
                return Ok(None);
            }
            let read = input
                .read(&mut buffer)
                .await
                .map_err(|_| io_error(source.id))?;
            if read == 0 {
                break;
            }
            checksum.update(&buffer[..read]);
        }
    }
    let mut file = tokio::fs::OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(offset == 0)
        .append(offset > 0)
        .open(part)
        .await
        .map_err(|_| io_error(source.id))?;
    let mut received = offset;
    let mut stream = response.bytes_stream();
    let mut last_emit = Instant::now() - Duration::from_secs(1);
    loop {
        let next = tokio::select! {
            biased;
            _ = control.interrupted() => {
                // Complete pending file writes before exposing a resumable byte
                // offset. Dropping a tokio File during write can race metadata.
                file.flush().await.map_err(|_| io_error(source.id))?;
                drop(file); drop(stream);
                return Ok(None);
            },
            next = stream.next() => next,
        };
        let Some(chunk) = next else {
            break;
        };
        let chunk = chunk.map_err(|e| {
            crate::booru::error::BooruError::new(
                if e.is_timeout() {
                    crate::booru::error::BooruErrorCode::Timeout
                } else {
                    crate::booru::error::BooruErrorCode::Network
                },
                Some(source.id),
                "booru.error.network",
            )
        })?;
        file.write_all(&chunk)
            .await
            .map_err(|_| io_error(source.id))?;
        checksum.update(&chunk);
        received += chunk.len() as u64;
        if total.is_some_and(|n| received > n) {
            return Err(validation_error(source.id, "booru.error.lengthMismatch"));
        }
        if last_emit.elapsed() >= Duration::from_millis(250) || total == Some(received) {
            last_emit = Instant::now();
            on_event(progress_event(received, total))?;
        }
    }
    file.flush().await.map_err(|_| io_error(source.id))?;
    file.sync_all().await.map_err(|_| io_error(source.id))?;
    drop(file);
    if received == 0 || total.is_some_and(|n| n != received) {
        return Err(validation_error(source.id, "booru.error.lengthMismatch"));
    }
    if let (Some(expected), Some(actual)) = (prepared.checksum.as_ref(), checksum.finish()) {
        if !expected.value.eq_ignore_ascii_case(&actual) {
            return Err(validation_error(source.id, "booru.error.checksumMismatch"));
        }
    }
    if control.is_paused() || control.cancel.is_cancelled() {
        return Ok(None);
    }
    replace_file(part, &actual_destination, source.id).await?;
    on_event(progress_event(received, Some(received)))?;
    Ok(Some(actual_destination))
}
async fn open_interruptible<Open, Fut>(
    control: &DownloadControl,
    open: &mut Open,
    resume: Option<(u64, String)>,
) -> BooruResult<Option<reqwest::Response>>
where
    Open: FnMut(Option<(u64, String)>) -> Fut,
    Fut: std::future::Future<Output = BooruResult<reqwest::Response>>,
{
    tokio::select! {biased;
        _=control.interrupted() => Ok(None),
        response=open(resume) => response.map(Some),
    }
}

fn progress_event(received: u64, total: Option<u64>) -> DownloadEvent {
    let event = progress(received, total);
    DownloadEvent::Progress {
        received_bytes_decimal: event.received.to_string(),
        total_bytes_decimal: event.total.map(|v| v.to_string()),
        progress: event.progress,
    }
}
fn validator(headers: &HeaderMap) -> Option<String> {
    headers
        .get(ETAG)
        .and_then(|v| v.to_str().ok())
        .filter(|v| !v.starts_with("W/"))
        .or_else(|| headers.get(LAST_MODIFIED).and_then(|v| v.to_str().ok()))
        .map(str::to_owned)
}
fn valid_resume(status: StatusCode, headers: &HeaderMap, offset: u64, partial: &Partial) -> bool {
    if status != StatusCode::PARTIAL_CONTENT || validator(headers) != partial.validator {
        return false;
    }
    let Some(range) = headers
        .get(CONTENT_RANGE)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("bytes "))
    else {
        return false;
    };
    let Some((span, total)) = range.split_once('/') else {
        return false;
    };
    let Some((start, end)) = span.split_once('-') else {
        return false;
    };
    let (Ok(start), Ok(end), Ok(total)) = (
        start.parse::<u64>(),
        end.parse::<u64>(),
        total.parse::<u64>(),
    ) else {
        return false;
    };
    start == offset && end >= start && end < total && partial.total.is_none_or(|n| n == total)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn only_matching_identity_and_exact_range_can_append() {
        let p = Partial {
            validator: Some("\"v1\"".into()),
            total: Some(100),
        };
        let mut h = HeaderMap::new();
        h.insert(ETAG, "\"v1\"".parse().unwrap());
        h.insert(CONTENT_RANGE, "bytes 40-99/100".parse().unwrap());
        assert!(valid_resume(StatusCode::PARTIAL_CONTENT, &h, 40, &p));
        assert!(!valid_resume(StatusCode::OK, &h, 40, &p));
        assert!(!valid_resume(StatusCode::PARTIAL_CONTENT, &h, 41, &p));
        h.insert(ETAG, "\"v2\"".parse().unwrap());
        assert!(!valid_resume(StatusCode::PARTIAL_CONTENT, &h, 40, &p));
        h.insert(ETAG, "W/\"v1\"".parse().unwrap());
        assert!(!valid_resume(StatusCode::PARTIAL_CONTENT, &h, 40, &p));
    }
}

/// Encoding is restarted from the already downloaded ZIP on resume. The worker
/// is joined before publishing Paused, so it cannot keep burning CPU in pause.
pub(crate) async fn encode<F>(
    input: &Path,
    control: &DownloadControl,
    on_event: &mut F,
) -> BooruResult<PathBuf>
where
    F: FnMut(DownloadEvent) -> BooruResult<()>,
{
    let result = encode_inner(input, control, on_event).await;
    if result.is_err() {
        let _ = tokio::fs::remove_file(input).await;
        let _ = tokio::fs::remove_file(input.with_extension("webp.part")).await;
    }
    result
}

async fn encode_inner<F>(
    input: &Path,
    control: &DownloadControl,
    on_event: &mut F,
) -> BooruResult<PathBuf>
where
    F: FnMut(DownloadEvent) -> BooruResult<()>,
{
    loop {
        if control.is_paused() {
            on_event(DownloadEvent::Paused)?;
            control.running().await?;
            on_event(DownloadEvent::Resumed { restarted: true })?;
        }
        if control.cancel.is_cancelled() {
            let _ = tokio::fs::remove_file(input).await;
            return Err(cancelled());
        }
        let output = input.with_extension("webp");
        let worker_input = input.to_owned();
        let worker_token = control.cancel.child_token();
        let stop = worker_token.clone();
        let (tx, mut rx) = tokio::sync::mpsc::channel(2);
        let worker = tokio::task::spawn_blocking(move || {
            super::ugoira::export(&worker_input, &output, &worker_token, |n, total| {
                tx.blocking_send((n as u32, total as u32))
                    .map_err(|_| cancelled())
            })
        });
        let mut interruption = None;
        loop {
            tokio::select! {
                biased;
                _=control.interrupted() => {stop.cancel(); rx.close(); break;},
                frame=rx.recv() => match frame {
                    Some((completed_frames,total_frames)) => if let Err(error)=on_event(DownloadEvent::Encoding {completed_frames,total_frames}) {
                        stop.cancel();rx.close();interruption=Some(error);break;
                    },
                    None => break,
                }
            }
        }
        let result = worker.await.map_err(|_| io_error("ugoira"))?;
        if let Some(error) = interruption {
            let _ = tokio::fs::remove_file(input).await;
            return Err(error);
        }
        if control.is_paused() && !control.cancel.is_cancelled() {
            if let Ok(path) = result {
                let _ = tokio::fs::remove_file(path).await;
            }
            continue;
        }
        let _ = tokio::fs::remove_file(input).await;
        if control.cancel.is_cancelled() {
            if let Ok(path) = result {
                let _ = tokio::fs::remove_file(path).await;
            }
            return Err(cancelled());
        }
        return result;
    }
}

#[cfg(test)]
mod socket_tests {
    use super::*;
    use crate::api::booru_models::{MediaKind, MediaVariantKind};
    use std::sync::{Arc, Mutex};

    async fn scenario(mode: &'static str) {
        let listener = tokio::net::TcpListener::bind(("127.0.0.1", 0))
            .await
            .unwrap();
        let address = listener.local_addr().unwrap();
        let requests = Arc::new(Mutex::new(Vec::<String>::new()));
        let recorded = requests.clone();
        let server = tokio::spawn(async move {
            let count = if mode == "cancel" {
                1
            } else if matches!(mode, "changed-206" | "wrong-range") {
                3
            } else {
                2
            };
            for number in 0..count {
                let (mut socket, _) = listener.accept().await.unwrap();
                let mut request = Vec::new();
                let mut byte = [0];
                while !request.ends_with(b"\r\n\r\n") {
                    if socket.read(&mut byte).await.unwrap() == 0 {
                        break;
                    }
                    request.push(byte[0]);
                }
                recorded
                    .lock()
                    .unwrap()
                    .push(String::from_utf8(request).unwrap().to_lowercase());
                let resume = number == 1 && mode != "no-validator";
                let partial = resume && !matches!(mode, "ignored" | "changed-200");
                let total = 8192;
                let range_start = if mode == "wrong-range" { 4095 } else { 4096 };
                let length = if partial { 4096 } else { total };
                let mut headers=format!("HTTP/1.1 {}\r\nContent-Type: image/png\r\nContent-Length: {length}\r\nConnection: close\r\n",if partial {"206 Partial Content"} else {"200 OK"});
                if mode != "no-validator" {
                    headers.push_str(
                        if matches!(mode, "changed-206" | "changed-200") && number > 0 {
                            "ETag: \"v2\"\r\n"
                        } else {
                            "ETag: \"v1\"\r\n"
                        },
                    );
                }
                if partial {
                    headers.push_str(&format!("Content-Range: bytes {range_start}-8191/8192\r\n"));
                }
                headers.push_str("\r\n");
                socket.write_all(headers.as_bytes()).await.unwrap();
                if number == 0 {
                    socket.write_all(&vec![1; 4096]).await.unwrap();
                    // The paused client must close this incomplete connection.
                    assert_eq!(socket.read(&mut byte).await.unwrap(), 0);
                } else {
                    let value = if mode.starts_with("changed") { 2 } else { 1 };
                    let _ = socket.write_all(&vec![value; length]).await;
                }
            }
        });
        let source = crate::booru::source::builtin_sources().remove(0);
        let prepared = PreparedDownload {
            source_id: source.id.into(),
            post_id: "1".into(),
            variant: MediaVariantKind::Original,
            url: format!("http://{address}/image"),
            headers: vec![],
            expected_bytes_decimal: Some("8192".into()),
            allowed_media_kinds: vec![MediaKind::Image],
            checksum: if mode == "valid" {
                use md5::{Digest, Md5};
                Some(crate::api::booru_models::Checksum {
                    algorithm: crate::api::booru_models::ChecksumAlgorithm::Md5,
                    value: Md5::digest(vec![1u8; 8192])
                        .iter()
                        .map(|byte| format!("{byte:02x}"))
                        .collect(),
                })
            } else {
                None
            },
            filename: "image.png".into(),
        };
        let directory = tempfile::tempdir().unwrap();
        let destination = directory.path().join("image.png");
        let control = DownloadControl::new();
        let mut paused = false;
        let mut events = Vec::new();
        let mut callback = |event: DownloadEvent| {
            match &event {
                DownloadEvent::Progress {
                    received_bytes_decimal,
                    ..
                } if !paused && received_bytes_decimal == "4096" => {
                    paused = true;
                    control.pause();
                }
                DownloadEvent::Paused => {
                    assert_eq!(
                        std::fs::metadata(part_path(&destination).unwrap())
                            .unwrap()
                            .len(),
                        4096
                    );
                    if mode == "cancel" {
                        control.cancel.cancel();
                    } else {
                        control.resume();
                    }
                }
                _ => {}
            }
            events.push(event);
            Ok(())
        };
        let _ = rustls::crypto::ring::default_provider().install_default();
        let client = reqwest::Client::builder().no_proxy().build().unwrap();
        let url = prepared.url.clone();
        let result = tokio::time::timeout(
            Duration::from_secs(4),
            download_with(
                &source,
                &prepared,
                &destination,
                &control,
                &mut callback,
                |resume| {
                    let client = client.clone();
                    let url = url.clone();
                    async move {
                        let mut request = client.get(url);
                        if let Some((offset, validator)) = resume {
                            request = request
                                .header("range", format!("bytes={offset}-"))
                                .header("if-range", validator);
                        }
                        request.send().await.map_err(|_| io_error("test"))
                    }
                },
            ),
        )
        .await
        .unwrap();
        tokio::time::timeout(Duration::from_secs(2), server)
            .await
            .unwrap()
            .unwrap();
        assert!(paused);
        assert!(events.iter().any(|e| matches!(e, DownloadEvent::Paused)));
        if mode == "cancel" {
            assert_eq!(
                result.err().unwrap().code,
                crate::booru::error::BooruErrorCode::Cancelled
            );
            assert!(!part_path(&destination).unwrap().exists());
            assert!(!destination.exists());
            return;
        }
        assert_eq!(
            std::fs::read(result.unwrap()).unwrap(),
            vec![if mode.starts_with("changed") { 2 } else { 1 }; 8192]
        );
        assert!(events.iter().any(
            |e| matches!(e,DownloadEvent::Resumed {restarted} if *restarted==(mode!="valid"))
        ));
        let requests = requests.lock().unwrap();
        if mode != "no-validator" {
            assert!(requests[1].contains("range: bytes=4096-"));
            assert!(requests[1].contains("if-range: \"v1\""));
        } else {
            assert!(!requests[1].contains("range:"));
        }
        if requests.len() == 3 {
            assert!(!requests[2].contains("range:"));
        }
    }
    #[tokio::test]
    async fn range_resume_keeps_prefix_and_closes_paused_connection() {
        scenario("valid").await;
    }
    #[tokio::test]
    async fn ignored_range_restarts_without_duplicate_prefix() {
        scenario("ignored").await;
    }
    #[tokio::test]
    async fn changed_resource_200_restarts() {
        scenario("changed-200").await;
    }
    #[tokio::test]
    async fn changed_resource_206_is_refetched_completely() {
        scenario("changed-206").await;
    }
    #[tokio::test]
    async fn wrong_content_range_never_appends() {
        scenario("wrong-range").await;
    }
    #[tokio::test]
    async fn missing_validator_restarts_safely() {
        scenario("no-validator").await;
    }
    #[tokio::test]
    async fn cancel_while_paused_removes_partial_and_terminates() {
        scenario("cancel").await;
    }
}

#[cfg(test)]
mod encoding_tests {
    use super::*;
    use std::io::Write;
    fn fixture(root: &Path) -> PathBuf {
        let path = root.join("frames.zip");
        let mut zip = zip::ZipWriter::new(std::fs::File::create(&path).unwrap());
        let options = zip::write::SimpleFileOptions::default();
        zip.start_file("animation.json", options).unwrap();
        zip.write_all(br#"{"frames":[{"file":"0.png","delay":100},{"file":"1.png","delay":200}]}"#)
            .unwrap();
        let png = lodepng::encode_memory(
            &vec![255u8; 256 * 256 * 4],
            256,
            256,
            lodepng::ColorType::RGBA,
            8,
        )
        .unwrap();
        for i in 0..2 {
            zip.start_file(format!("{i}.png"), options).unwrap();
            zip.write_all(&png).unwrap();
        }
        zip.finish().unwrap();
        path
    }
    #[tokio::test]
    async fn encoding_pause_joins_worker_and_resumes_from_valid_archive() {
        let root = tempfile::tempdir().unwrap();
        let input = fixture(root.path());
        let control = DownloadControl::new();
        let mut paused = false;
        let mut acknowledged = false;
        let mut restarted = false;
        let result = encode(&input, &control, &mut |event| {
            match event {
                DownloadEvent::Encoding { .. } if !paused => {
                    paused = true;
                    control.pause();
                }
                DownloadEvent::Paused => {
                    acknowledged = true;
                    assert!(input.exists());
                    assert!(!input.with_extension("webp.part").exists());
                    control.resume();
                }
                DownloadEvent::Resumed { restarted: value } => restarted = value,
                _ => {}
            }
            Ok(())
        })
        .await
        .unwrap();
        assert!(paused && acknowledged && restarted);
        assert!(result.exists());
        assert!(!input.exists());
    }
    #[tokio::test]
    async fn encoding_cancel_while_paused_cleans_archive_and_worker_output() {
        let root = tempfile::tempdir().unwrap();
        let input = fixture(root.path());
        let control = DownloadControl::new();
        let result = encode(&input, &control, &mut |event| {
            match event {
                DownloadEvent::Encoding { .. } => control.pause(),
                DownloadEvent::Paused => control.cancel.cancel(),
                _ => {}
            }
            Ok(())
        })
        .await;
        assert_eq!(
            result.err().unwrap().code,
            crate::booru::error::BooruErrorCode::Cancelled
        );
        assert!(!input.exists());
        assert!(!input.with_extension("webp.part").exists());
    }
}
