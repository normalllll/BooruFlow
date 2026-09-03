use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;
use futures_util::StreamExt;
use md5::Md5;
use reqwest::header::{HeaderMap, HeaderName, HeaderValue, CONTENT_TYPE, HOST};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};
use tokio::io::AsyncWriteExt;

#[frb]
#[derive(Clone, Debug)]
pub enum FrbDownloadFileEvent {
    Progress { received: u32, total: u32 },
    Done { path: String },
}

#[allow(clippy::too_many_arguments)]
pub async fn download_to_file(
    url: String,
    path: String,
    headers: HashMap<String, String>,
    proxy_url: Option<String>,
    connect_host: Option<String>,
    host_header: Option<String>,
    disable_tls_sni: bool,
    allow_invalid_certificates: bool,
    connect_timeout_seconds: u32,
    receive_timeout_seconds: u32,
    expected_bytes: Option<u32>,
    allowed_content_types: Vec<String>,
    checksum_algorithm: Option<String>,
    checksum_value: Option<String>,
    sink: StreamSink<FrbDownloadFileEvent>,
) -> Result<(), String> {
    let original_url =
        reqwest::Url::parse(&url).map_err(|error| format!("Invalid download URL: {error}"))?;
    let mut request_url = original_url;
    if let Some(connect_host) = non_empty(connect_host) {
        request_url
            .set_host(Some(&connect_host))
            .map_err(|_| format!("Invalid connection host: {connect_host}"))?;
    }

    let mut client_builder = reqwest::Client::builder()
        .connect_timeout(Duration::from_secs(connect_timeout_seconds.max(1) as u64))
        .read_timeout(Duration::from_secs(receive_timeout_seconds.max(1) as u64))
        .danger_accept_invalid_certs(allow_invalid_certificates)
        .tls_sni(!disable_tls_sni);
    if let Some(proxy_url) = non_empty(proxy_url) {
        client_builder = client_builder.proxy(
            reqwest::Proxy::all(&proxy_url)
                .map_err(|error| format!("Invalid proxy URL: {error}"))?,
        );
    }
    let client = client_builder
        .build()
        .map_err(|error| format!("Could not create download client: {error}"))?;

    let mut request_headers = parse_headers(headers)?;
    if let Some(host_header) = non_empty(host_header) {
        request_headers.insert(
            HOST,
            HeaderValue::from_str(&host_header)
                .map_err(|error| format!("Invalid Host header: {error}"))?,
        );
    }

    let response = client
        .get(request_url)
        .headers(request_headers)
        .send()
        .await
        .map_err(|error| format!("Download request failed: {error}"))?
        .error_for_status()
        .map_err(|error| format!("Download failed: {error}"))?;

    validate_content_type(response.headers().get(CONTENT_TYPE), &allowed_content_types)?;
    let response_length = response.content_length();
    if let (Some(expected), Some(actual)) = (expected_bytes.map(u64::from), response_length) {
        if expected != actual {
            return Err(format!(
                "Response byte count mismatch: expected {expected}, got {actual}"
            ));
        }
    }
    let total = expected_bytes.map(u64::from).or(response_length);

    let destination = PathBuf::from(&path);
    if let Some(parent) = destination.parent() {
        tokio::fs::create_dir_all(parent)
            .await
            .map_err(|error| format!("Could not create download directory: {error}"))?;
    }
    let mut file = tokio::fs::File::create(&destination)
        .await
        .map_err(|error| format!("Could not create download file: {error}"))?;
    let mut stream = response.bytes_stream();
    let mut received = 0_u64;
    let mut last_emit = Instant::now() - Duration::from_secs(1);
    let mut checksum = StreamingChecksum::new(checksum_algorithm.as_deref())?;

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|error| format!("Download stream failed: {error}"))?;
        file.write_all(&chunk)
            .await
            .map_err(|error| format!("Could not write download file: {error}"))?;
        checksum.update(&chunk);
        received += chunk.len() as u64;
        if last_emit.elapsed() >= Duration::from_millis(300) || total == Some(received) {
            last_emit = Instant::now();
            emit_progress(&sink, received, total)?;
        }
    }
    file.flush()
        .await
        .map_err(|error| format!("Could not flush download file: {error}"))?;
    drop(file);

    if received == 0 {
        remove_invalid_file(&destination).await;
        return Err("Downloaded file is empty".to_owned());
    }
    if let Some(expected) = expected_bytes.map(u64::from).or(response_length) {
        if received != expected {
            remove_invalid_file(&destination).await;
            return Err(format!(
                "Downloaded byte count mismatch: expected {expected}, got {received}"
            ));
        }
    }
    if let Some(actual) = checksum.finish() {
        let expected = checksum_value
            .unwrap_or_default()
            .trim()
            .to_ascii_lowercase();
        if expected.is_empty() {
            remove_invalid_file(&destination).await;
            return Err("Checksum algorithm was provided without a checksum value".to_owned());
        }
        if actual != expected {
            remove_invalid_file(&destination).await;
            return Err(format!(
                "Downloaded checksum mismatch: expected {expected}, got {actual}"
            ));
        }
    }

    emit_progress(&sink, received, Some(received))?;
    sink.add(FrbDownloadFileEvent::Done {
        path: destination.to_string_lossy().to_string(),
    })
    .map_err(|error| format!("Download event sink closed: {error:?}"))?;
    Ok(())
}

fn parse_headers(headers: HashMap<String, String>) -> Result<HeaderMap, String> {
    let mut result = HeaderMap::new();
    for (name, value) in headers {
        let name = HeaderName::from_bytes(name.trim().as_bytes())
            .map_err(|error| format!("Invalid request header name: {error}"))?;
        let value = HeaderValue::from_str(value.trim())
            .map_err(|error| format!("Invalid request header value: {error}"))?;
        result.insert(name, value);
    }
    Ok(result)
}

fn validate_content_type(value: Option<&HeaderValue>, allowed: &[String]) -> Result<(), String> {
    if allowed.is_empty() {
        return Ok(());
    }
    let actual = value
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.split(';').next())
        .map(str::trim)
        .map(str::to_ascii_lowercase)
        .ok_or_else(|| "Download response has no valid Content-Type".to_owned())?;
    let matches = allowed.iter().any(|candidate| {
        let candidate = candidate.trim().to_ascii_lowercase();
        candidate
            .strip_suffix("/*")
            .map_or(actual == candidate, |prefix| {
                actual.starts_with(&format!("{prefix}/"))
            })
    });
    if matches {
        Ok(())
    } else {
        Err(format!("Unexpected download Content-Type: {actual}"))
    }
}

fn emit_progress(
    sink: &StreamSink<FrbDownloadFileEvent>,
    received: u64,
    total: Option<u64>,
) -> Result<(), String> {
    sink.add(FrbDownloadFileEvent::Progress {
        received: progress_value(received as usize),
        total: progress_value(total.unwrap_or(0) as usize),
    })
    .map_err(|error| format!("Download event sink closed: {error:?}"))
}

fn progress_value(value: usize) -> u32 {
    u32::try_from(value).unwrap_or(u32::MAX)
}

fn non_empty(value: Option<String>) -> Option<String> {
    value
        .map(|value| value.trim().to_owned())
        .filter(|value| !value.is_empty())
}

async fn remove_invalid_file(path: &Path) {
    let _ = tokio::fs::remove_file(path).await;
}

enum StreamingChecksum {
    None,
    Md5(Md5),
    Sha256(Sha256),
}

impl StreamingChecksum {
    fn new(algorithm: Option<&str>) -> Result<Self, String> {
        match algorithm.map(str::trim).filter(|value| !value.is_empty()) {
            None => Ok(Self::None),
            Some("md5") => Ok(Self::Md5(Md5::new())),
            Some("sha256") => Ok(Self::Sha256(Sha256::new())),
            Some(value) => Err(format!("Unsupported checksum algorithm: {value}")),
        }
    }

    fn update(&mut self, bytes: &[u8]) {
        match self {
            Self::None => {}
            Self::Md5(hasher) => hasher.update(bytes),
            Self::Sha256(hasher) => hasher.update(bytes),
        }
    }

    fn finish(self) -> Option<String> {
        match self {
            Self::None => None,
            Self::Md5(hasher) => Some(format!("{:x}", hasher.finalize())),
            Self::Sha256(hasher) => Some(format!("{:x}", hasher.finalize())),
        }
    }
}
