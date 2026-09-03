use reqwest::Url;
use std::time::Duration;

pub struct HttpClient {
    client: reqwest::Client,
}

impl HttpClient {
    pub fn new(ips: Option<[String; 3]>) -> Self {
        let mut builder = reqwest::ClientBuilder::new()
            .user_agent(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)",
            )
            .https_only(true)
            .connect_timeout(Duration::from_secs(30))
            .read_timeout(Duration::from_secs(120));

        if let Some(ips) = ips {
            let addresses = ips.map(|ip| format!("{ip}:443").parse());
            if let [Ok(yande), Ok(files), Ok(assets)] = addresses {
                builder = builder
                    .tls_sni(false)
                    .resolve("yande.re", yande)
                    .resolve("files.yande.re", files)
                    .resolve("assets.yande.re", assets)
                    .danger_accept_invalid_certs(true);
            }
        }

        Self {
            client: builder.build().expect("failed to build HTTP client"),
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
                let query = encoded_params
                    .map(|(key, value)| format!("{key}={value}"))
                    .collect::<Vec<_>>()
                    .join("&");
                let mut parsed = Url::parse(url)?;
                parsed.set_query(Some(&query));
                parsed
            }
            None => Url::parse(url)?,
        };
        Ok(self.client.get(url).send().await?.error_for_status()?)
    }
}
