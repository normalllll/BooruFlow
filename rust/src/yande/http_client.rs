use std::io::Write;
use flutter_rust_bridge::DartFnFuture;

use futures_util::stream::StreamExt;
use reqwest::Url;

pub struct HttpClient {
    client: reqwest::Client,
}


impl HttpClient {
    pub fn new(ips: Option<[String; 3]>) -> Self {
        //107.189.2.17
        if let Some(ips) = ips {
            // if let Ok(socket) = format!("{}:443", ip).parse() {
            //     return Self {
            //         client: reqwest::ClientBuilder::new().
            //             tls_sni(false).
            //             resolve("yande.re", socket).
            //             resolve("files.yande.re", socket).
            //             resolve("assets.yande.re", socket).
            //             danger_accept_invalid_certs(true).
            //             build().unwrap(),
            //     };
            // }

            let socket0 = format!("{}:443", ips[0]).parse();
            let socket1 = format!("{}:443", ips[1]).parse();
            let socket2 = format!("{}:443", ips[2]).parse();

            if let (Ok(socket0), Ok(socket1), Ok(socket2)) = (socket0, socket1, socket2) {
                return Self {
                    client: reqwest::ClientBuilder::new().
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
            client: reqwest::ClientBuilder::new().
                build().unwrap(),
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

    pub async fn download_to_memory(&self, url: &str, progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + 'static) -> anyhow::Result<Vec<u8>> {
        let resp = self.get(url, None).await?;


        let total_size = resp.content_length().ok_or("No content length").map_err(|e| anyhow::anyhow!(e))? as usize;
        let part_offset = total_size / 50;

        let mut received = 0;
        let mut next_threshold = part_offset;

        let mut bytes_stream = resp.bytes_stream();

        let mut bytes = Vec::with_capacity(total_size);

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

    pub async fn download_to_file(&self, url: &str, file_path: &str, progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + 'static) -> anyhow::Result<()> {
        let resp = self.get(url, None).await?;


        let total_size = resp.content_length().ok_or("No content length").map_err(|e| anyhow::anyhow!(e))?;

        let mut bytes_stream = resp.bytes_stream();

        let mut file = std::fs::File::create(file_path)?;

        let mut received = 0;

        while let Some(item) = bytes_stream.next().await {
            let chunk = item?;
            received += chunk.len();
            progress_callback(received, total_size as usize).await;

            file.write_all(&chunk)?;
            file.flush()?;
        }

        Ok(())
    }
}