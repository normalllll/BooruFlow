use crate::yande::http_client::HttpClient;
use crate::yande::model::{Post, Similar};
use flutter_rust_bridge::DartFnFuture;

pub struct YandeClient {
    http: HttpClient,
}

impl YandeClient {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new(ips: Option<[String; 3]>, for_large_file: bool) -> Self {
        Self {
            http: HttpClient::new(ips, for_large_file),
        }
    }
}

impl YandeClient {
    pub async fn get_posts(
        &self,
        tags: Vec<String>,
        limit: u32,
        page: u32,
    ) -> anyhow::Result<Vec<Post>> {
        let tags = tags.join("+");
        let resp = self
            .http
            .get(
                "https://yande.re/post.json",
                Some(
                    vec![
                        ("tags", tags.as_str()),
                        ("limit", limit.to_string().as_str()),
                        ("page", page.to_string().as_str()),
                    ]
                    .iter()
                    .map(|(k, v)| (*k, *v))
                    .collect::<Vec<_>>(),
                ),
            )
            .await?;
        let posts = resp.json::<Vec<Post>>().await?;
        Ok(posts)
    }

    pub async fn get_similar(&self, post_id: i64) -> anyhow::Result<Similar> {
        let resp = self
            .http
            .get(
                "https://yande.re/post/similar.json",
                Some(vec![("id", post_id.to_string().as_str())]),
            )
            .await?;
        let similar = resp.json::<Similar>().await?;
        Ok(similar)
    }

    // pub async fn download_to_file(&self, url: String, file_path: String, progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + 'static) -> anyhow::Result<()> {
    //     self.http.download_to_file(&url, &file_path, progress_callback).await?;
    //     Ok(())
    // }

    pub async fn download_to_file(
        &self,
        url: &str,
        file_path: &str,
        max_task_count: u32,
        progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + 'static + Send+Sync,
    ) -> anyhow::Result<()> {
        self.http
            .download_to_file(
                url,
                file_path,
                max_task_count as _,
                progress_callback,
                tokio_util::sync::CancellationToken::new(),
            )
            .await
    }

    pub async fn download_to_memory(
        &self,
        url: &str,
        progress_callback: impl Fn(usize, usize) -> DartFnFuture<()> + 'static + Send,
    ) -> anyhow::Result<Vec<u8>> {
        let bytes = self
            .http
            .download_to_memory(&url, progress_callback)
            .await?;
        Ok(bytes)
    }
}
