use flutter_rust_bridge::DartFnFuture;
use futures_util::future::try_join_all;
use futures_util::stream::StreamExt;
use reqwest::Url;
use std::io::Write;
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;
use tokio::io::{AsyncSeekExt, AsyncWriteExt};
use tokio::sync::Mutex;
use tokio::task;

pub struct HttpClient {
    client: reqwest::Client,
}

impl HttpClient {
    pub fn new(ips: Option<[String; 3]>, for_large_file: bool) -> Self {
        let mut client_builder = reqwest::ClientBuilder::new()
            .http2_prior_knowledge()
            .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)")
            .https_only(true)
            .http2_adaptive_window(true)
            .http2_keep_alive_interval(Duration::from_secs(30))
            .http2_keep_alive_timeout(Duration::from_secs(60))
            .http2_keep_alive_while_idle(true);

        if for_large_file {
            client_builder = client_builder
                .http2_keep_alive_interval(Duration::from_secs(30))
                .http2_keep_alive_timeout(Duration::from_secs(120))
                .http2_initial_connection_window_size(1024 * 1024)
                .http2_initial_stream_window_size(1024 * 1024)
                .http2_max_frame_size(128 * 1024)
                .http2_keep_alive_while_idle(true)
        }

        if let Some(ips) = ips {
            let socket0 = format!("{}:443", ips[0]).parse();
            let socket1 = format!("{}:443", ips[1]).parse();
            let socket2 = format!("{}:443", ips[2]).parse();

            if let (Ok(socket0), Ok(socket1), Ok(socket2)) = (socket0, socket1, socket2) {
                return Self {
                    client: client_builder
                        .tls_sni(false)
                        .resolve("yande.re", socket0)
                        .resolve("files.yande.re", socket1)
                        .resolve("assets.yande.re", socket2)
                        .danger_accept_invalid_certs(true)
                        .build()
                        .unwrap(),
                };
            }
        }
        Self {
            client: client_builder.build().unwrap(),
        }
    }

    pub async fn get(
        &self,
        url: &str,
        params: Option<Vec<(&str, &str)>>,
    ) -> anyhow::Result<reqwest::Response> {
        let url = match params {
            Some(params) => {
                let encoded_params = params.iter().map(|(key, value)| {
                    let encoded_key = url::form_urlencoded::byte_serialize(key.as_bytes())
                        .collect::<String>()
                        .replace("%2B", "+");
                    let encoded_value = url::form_urlencoded::byte_serialize(value.as_bytes())
                        .collect::<String>()
                        .replace("%2B", "+");
                    (encoded_key, encoded_value)
                });

                // Construct query string manually
                let query_string = encoded_params
                    .map(|(k, v)| format!("{}={}", k, v))
                    .collect::<Vec<String>>()
                    .join("&");
                let mut url = Url::parse(url)?;
                url.set_query(Some(&query_string));
                url
            }
            None => Url::parse(url)?,
        };
        self.client.get(url).send().await.map_err(|e| e.into())
    }

    pub async fn download_to_file(
        &self,
        url: &str,
        file_path: &str,
        max_task_count: usize,
        progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + Send + Sync + 'static,
        cancel_token: tokio_util::sync::CancellationToken,
    ) -> anyhow::Result<()> {
        let head_resp = self.client.head(url).send().await?;
        let total_size = head_resp
            .content_length()
            .ok_or_else(|| anyhow::anyhow!("No content length"))? as usize;

        let accept_ranges = head_resp
            .headers()
            .get("accept-ranges")
            .and_then(|v| v.to_str().ok())
            .unwrap_or("none");

        if accept_ranges != "bytes" {
            return self
                .simple_download(url, file_path, total_size, progress_callback)
                .await;
        }

        let part_dir = Path::new(&file_path)
            .parent()
            .ok_or_else(|| anyhow::anyhow!("Invalid file path"))?;

        tokio::fs::create_dir_all(part_dir).await?;

        let part_count = max_task_count
            .min(total_size.max(1) / (2 * 1024 * 1024))
            .max(1);
        let chunk_size = total_size / part_count;
        let progress_min_count = total_size / 50;

        let total_received = Arc::new(Mutex::new(0usize));
        let callback = Arc::new(progress_callback);
        let client = Arc::new(self.client.clone());

        let mut tasks = Vec::new();
        let internal_token = cancel_token.child_token();

        for i in 0..part_count {
            let range_start = i * chunk_size;
            let range_end = if i == part_count - 1 {
                total_size - 1
            } else {
                (i + 1) * chunk_size - 1
            };

            let part_path = format!("{}.part{}", file_path, i);
            let url = url.to_string();
            let client = client.clone();
            let callback = callback.clone();
            let total_received = total_received.clone();
            let token = internal_token.clone();

            tasks.push(task::spawn(async move {
                let mut downloaded = std::fs::metadata(&part_path)
                    .map(|m| m.len() as usize)
                    .unwrap_or(0);
                let expected_size = range_end - range_start + 1;

                {
                    let mut total = total_received.lock().await;
                    *total += downloaded;
                }

                if downloaded == expected_size {
                    callback(downloaded, total_size).await;
                    return Ok(downloaded);
                }

                let mut file = tokio::fs::OpenOptions::new()
                    .create(true)
                    .write(true)
                    .open(&part_path)
                    .await?;

                file.seek(std::io::SeekFrom::Start(downloaded as u64))
                    .await?;

                let actual_start = range_start + downloaded;
                let range_header = format!("bytes={}-{}", actual_start, range_end);

                let resp = client
                    .get(&url)
                    .header("Range", range_header)
                    .send()
                    .await?;

                if resp.status() != reqwest::StatusCode::PARTIAL_CONTENT {
                    return Err(anyhow::anyhow!(
                        "Server did not support range requests properly"
                    ));
                }

                let mut stream = resp.bytes_stream();
                let mut last = 0;

                loop {
                    tokio::select! {
                        _ = token.cancelled() => {
                            return Err(anyhow::anyhow!("Task cancelled"));
                        }

                        maybe_chunk = stream.next() => {
                            let chunk = match maybe_chunk {
                                Some(Ok(data)) => data,
                                Some(Err(e)) => return Err(e.into()),
                                None => break,
                            };

                            file.write_all(&chunk).await?;
                            downloaded += chunk.len();
                            last += chunk.len();

                            if last >= progress_min_count || downloaded == expected_size {
                                let mut total = total_received.lock().await;
                                *total += last;
                                callback(*total, total_size).await;
                                last = 0;
                            }
                        }
                    }
                }

                file.flush().await?;

                if downloaded != expected_size {
                    return Err(anyhow::anyhow!(
                        "Part {} Incomplete download: expected {} bytes, got {} bytes",
                        i,
                        expected_size,
                        downloaded
                    ));
                }
                Ok(downloaded)
            }));
        }

        let results = try_join_all(tasks).await;

        let results = results.map_err(|e| {
            internal_token.cancel(); // cancel all task
            return anyhow::anyhow!("Download failed: {:?}", e);
        })?;

        for result in results {
            result?;
        }

        let total_received = *total_received.lock().await;
        if total_received != total_size {
            return Err(anyhow::anyhow!(
                "Incomplete download: expected {} bytes, got {} bytes",
                total_size,
                total_received
            ));
        }

        // mix
        let mut output = std::fs::File::create(file_path)?;
        for i in 0..part_count {
            let part_path = format!("{}.part{}", file_path, i);
            let mut part = std::fs::File::open(&part_path)?;
            std::io::copy(&mut part, &mut output)?;
            std::fs::remove_file(&part_path)?;
        }

        output.flush()?;
        Ok(())
    }

    async fn simple_download(
        &self,
        url: &str,
        file_path: &str,
        total_size: usize,
        progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + Send + 'static,
    ) -> anyhow::Result<()> {
        use std::fs::File;

        let mut received = 0;
        let part_offset = total_size / 50;
        let mut next_threshold = part_offset;

        let resp = self.client.get(url).send().await?;
        let mut stream = resp.bytes_stream();

        std::fs::create_dir_all(Path::new(file_path).parent().unwrap())?;
        let mut file = File::create(file_path)?;

        while let Some(item) = stream.next().await {
            let chunk = item?;
            received += chunk.len();
            file.write_all(&chunk)?;

            if received >= next_threshold || received == total_size {
                progress_callback(received, total_size).await;
                next_threshold += part_offset;
            }
        }

        file.flush()?;
        Ok(())
    }

    pub async fn download_to_memory(
        &self,
        url: &str,
        progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + 'static + Send,
    ) -> anyhow::Result<Vec<u8>> {
        let get_resp = self.get(url, None).await?;
        let total_size = get_resp
            .content_length()
            .ok_or("No content length")
            .map_err(|e| anyhow::anyhow!(e))? as usize;

        let mut bytes = Vec::with_capacity(total_size);

        let mut received = 0;
        let part_offset = total_size / 50;
        let mut next_threshold = part_offset;

        let mut bytes_stream = get_resp.bytes_stream();

        while let Some(item) = bytes_stream.next().await {
            let chunk = item?;
            received += chunk.len();

            if received >= next_threshold || received == total_size {
                progress_callback(received, total_size).await;
                next_threshold += part_offset;
            }

            bytes.extend_from_slice(&chunk);
        }

        Ok(bytes)
    }
}
