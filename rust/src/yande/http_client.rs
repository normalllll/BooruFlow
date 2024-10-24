use std::io::Write;
use std::sync::Arc;
use std::time::Duration;
use flutter_rust_bridge::DartFnFuture;
use futures_util::future::join_all;
use futures_util::stream::StreamExt;
use reqwest::Url;
use tokio::sync::Mutex;
use tokio::task;
use tokio::task::JoinHandle;

pub struct HttpClient {
    client: reqwest::Client,
}


impl HttpClient {
    pub fn new(ips: Option<[String; 3]>, for_large_file: bool) -> Self {
        let mut client_builder = reqwest::ClientBuilder::new().
            http2_prior_knowledge().
            https_only(true).
            http2_adaptive_window(true).
            http2_keep_alive_interval(Duration::from_secs(30)).
            http2_keep_alive_timeout(Duration::from_secs(60)).
            http2_keep_alive_while_idle(true);

        if for_large_file {
            client_builder = client_builder.
                http2_keep_alive_interval(Duration::from_secs(30)).
                http2_keep_alive_timeout(Duration::from_secs(120)).
                http2_initial_connection_window_size(1024 * 1024).
                http2_initial_stream_window_size(1024 * 1024).
                http2_max_frame_size(128 * 1024).
                http2_keep_alive_while_idle(true)
        }

        if let Some(ips) = ips {
            let socket0 = format!("{}:443", ips[0]).parse();
            let socket1 = format!("{}:443", ips[1]).parse();
            let socket2 = format!("{}:443", ips[2]).parse();

            if let (Ok(socket0), Ok(socket1), Ok(socket2)) = (socket0, socket1, socket2) {
                return Self {
                    client: client_builder.
                        tls_sni(false).
                        resolve("yande.re", socket0).
                        resolve("files.yande.re", socket1).
                        resolve("assets.yande.re", socket2).
                        danger_accept_invalid_certs(true).
                        build().unwrap(),
                };
            }
        }
        Self {
            client: client_builder.build().unwrap(),
        }
    }

    pub async fn get(&self, url: &str, params: Option<Vec<(&str, &str)>>) -> anyhow::Result<reqwest::Response> {
        let url = match params {
            Some(params) => {
                let encoded_params = params.iter().map(|(key, value)| {
                    let encoded_key = url::form_urlencoded::byte_serialize(key.as_bytes()).collect::<String>().replace("%2B", "+");
                    let encoded_value = url::form_urlencoded::byte_serialize(value.as_bytes()).collect::<String>().replace("%2B", "+");
                    (encoded_key, encoded_value)
                });

                // Construct query string manually
                let query_string = encoded_params.map(|(k, v)| format!("{}={}", k, v)).collect::<Vec<String>>().join("&");
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
        progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + 'static + Send,
    ) -> anyhow::Result<()> {
        if max_task_count > 1 {
            // Send an initial request to check whether the server supports Range requests
            let head_resp = self.client.head(url).send().await?;

            let total_size = head_resp.content_length().ok_or("No content length").map_err(|e| anyhow::anyhow!(e))? as usize;

            let accept_ranges = head_resp
                .headers()
                .get("accept-ranges")
                .and_then(|v| v.to_str().ok())
                .unwrap_or("none");

            if accept_ranges == "bytes" && total_size > 2 * 1024 * 1024 {
                let total_received = Arc::new(Mutex::new(0));
                let progress_callback = Arc::new(Mutex::new(progress_callback));
                // If the server supports segmented downloads and the file is larger than 2MB, dynamically select the number of coroutines
                let num_parts = (total_size / (2 * 1024 * 1024)).min(max_task_count);

                let chunk_size = total_size / num_parts;
                let mut tasks = Vec::new();

                let client = Arc::new(self.client.clone());

                for i in 0..num_parts {
                    let range_start = i * chunk_size;
                    let range_end = if i == num_parts - 1 {
                        total_size - 1
                    } else {
                        (i + 1) * chunk_size - 1
                    };

                    let url_clone = url.to_string();
                    let progress_callback_clone = Arc::clone(&progress_callback);
                    let total_received_clone = Arc::clone(&total_received);
                    let client_clone = Arc::clone(&client);

                    let part_size = range_end - range_start + 1;
                    let part_offset = total_size / 50; // Progress max count

                    // Part handle
                    let task: JoinHandle<anyhow::Result<Vec<u8>>> = task::spawn(async move {
                        let range_header = format!("bytes={}-{}", range_start, range_end);
                        let part_resp = client_clone
                            .get(&url_clone)
                            .header("Range", range_header)
                            .send()
                            .await?;

                        let mut received = 0;
                        let mut last_progress_part_received = 0;
                        let mut next_threshold = part_offset;
                        let mut bytes_stream = part_resp.bytes_stream();
                        let mut part_bytes = Vec::with_capacity(part_size);

                        while let Some(item) = bytes_stream.next().await {
                            let chunk = item?;
                            received += chunk.len();
                            last_progress_part_received += chunk.len();
                            part_bytes.extend_from_slice(&chunk);

                            if received >= next_threshold || received == part_size {
                                let mut total_received_locked = total_received_clone.lock().await;
                                *total_received_locked += last_progress_part_received;
                                last_progress_part_received = 0;
                                // post progress
                                let progress_callback_locked = progress_callback_clone.lock().await;
                                progress_callback_locked(*total_received_locked, total_size).await;

                                next_threshold += part_offset;
                            }
                        }

                        Ok(part_bytes)
                    });
                    tasks.push(task);
                }

                // Wait for all parts to be downloaded
                let results = join_all(tasks).await;


                std::fs::create_dir_all(std::path::Path::new(file_path).parent().unwrap())?;
                let mut file = std::fs::File::create(file_path)?;
                // Combine all results
                for result in results {
                    let part = result??;
                    file.write_all(&part)?;
                }
                file.flush()?;
                return Ok(());
            }
        }

        let get_resp = self.get(url, None).await?;
        let total_size = get_resp.content_length().ok_or("No content length").map_err(|e| anyhow::anyhow!(e))? as usize;

        let mut received = 0;
        let part_offset = total_size / 50;
        let mut next_threshold = part_offset;

        let mut bytes_stream = get_resp.bytes_stream();

        std::fs::create_dir_all(std::path::Path::new(file_path).parent().unwrap())?;
        let mut file = std::fs::File::create(file_path)?;
        while let Some(item) = bytes_stream.next().await {
            let chunk = item?;
            received += chunk.len();

            if received >= next_threshold || received == total_size {
                progress_callback(received, total_size).await;
                next_threshold += part_offset;
            }
            file.write_all(&chunk)?;
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
        let total_size = get_resp.content_length().ok_or("No content length").map_err(|e| anyhow::anyhow!(e))? as usize;

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