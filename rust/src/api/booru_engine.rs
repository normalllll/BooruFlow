use crate::api::booru_auth::{AuthSchema, AuthState, SourceCredentials, WebCookie};
use crate::api::booru_download::{
    DownloadEvent, DownloadRequest, MediaFetchEvent, PreparedDownload,
};
use crate::api::booru_models::{
    BooruEngineConfig, BooruPost, BooruSource, BooruTagSuggestion, MediaRequest, MediaVariantKind,
    PostPage, RouteCacheState, SearchRequest,
};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::anime_pictures::AnimePicturesAdapter;
use crate::booru::adapters::danbooru::DanbooruAdapter;
use crate::booru::adapters::gelbooru::GelbooruAdapter;
use crate::booru::adapters::moebooru::MoebooruAdapter;
use crate::booru::adapters::wallhaven::WallhavenAdapter;
use crate::booru::auth::credential::auth_schema;
use crate::booru::auth::SessionStore;
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use crate::booru::media::download::{
    download_to_path, open_prepared_unthrottled, DownloadProgress,
};
use crate::booru::media::request::prepared_download;
use crate::booru::media::transcode::avif_to_png;
use crate::booru::model::{PostId, SearchQuery};
use crate::booru::network::NetworkRuntime;
use crate::booru::registry::SourceRegistry;
use crate::booru::source::{builtin_sources, ProtocolFamily};
use crate::frb_generated::StreamSink;
use futures_util::StreamExt;
use std::collections::BTreeSet;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

pub struct BooruEngine {
    registry: SourceRegistry,
    sessions: Arc<SessionStore>,
    runtime: Arc<NetworkRuntime>,
    active_downloads: Mutex<BTreeSet<String>>,
}

impl BooruEngine {
    pub fn new(config: BooruEngineConfig) -> BooruResult<Self> {
        let definitions = builtin_sources();
        let sessions = Arc::new(SessionStore::default());
        let runtime = Arc::new(NetworkRuntime::new(config, &definitions, sessions.clone())?);
        let adapters = definitions
            .into_iter()
            .map(|definition| -> Arc<dyn BooruAdapter> {
                match definition.family {
                    ProtocolFamily::Moebooru => Arc::new(MoebooruAdapter::new(definition)),
                    ProtocolFamily::Danbooru => Arc::new(DanbooruAdapter::new(definition)),
                    ProtocolFamily::Gelbooru => Arc::new(GelbooruAdapter::new(definition)),
                    ProtocolFamily::Wallhaven => Arc::new(WallhavenAdapter::new(definition)),
                    ProtocolFamily::AnimePictures => {
                        Arc::new(AnimePicturesAdapter::new(definition))
                    }
                }
            })
            .collect();
        Ok(Self {
            registry: SourceRegistry::new(adapters)?,
            sessions,
            runtime,
            active_downloads: Mutex::new(BTreeSet::new()),
        })
    }

    pub fn list_sources(&self) -> Vec<BooruSource> {
        self.registry
            .all()
            .map(|adapter| adapter.definition().to_api())
            .collect()
    }

    pub async fn search(&self, request: SearchRequest) -> BooruResult<PostPage> {
        let adapter = self.registry.get(&request.source_id)?;
        let capabilities = &adapter.definition().capabilities;
        if !capabilities.supports_search
            || request.query_text.trim().is_empty()
            || request.page_size == 0
            || request
                .ratings
                .iter()
                .any(|rating| !capabilities.ratings.contains(rating))
        {
            return Err(BooruError::invalid_request(Some(&request.source_id)));
        }
        let query = SearchQuery {
            text: request.query_text,
            ratings: crate::booru::discovery::resolve_ratings(
                adapter.definition(),
                request.ratings,
                self.context()
                    .runtime
                    .auth_state(&request.source_id)?
                    .status
                    != crate::api::booru_auth::AuthStatus::NotConfigured,
            ),
            page_size: request.page_size,
            cursor: request.cursor,
        };
        let page = adapter.search(&self.context(), query).await?;
        Ok(PostPage {
            items: page.items.into_iter().map(|post| post.into_api()).collect(),
            next_cursor: page.next_cursor,
            exhausted: page.exhausted,
        })
    }

    pub async fn get_post(&self, source_id: String, post_id: String) -> BooruResult<BooruPost> {
        let adapter = self.registry.get(&source_id)?;
        adapter
            .get_post(&self.context(), &PostId(post_id))
            .await
            .map(|post| post.into_api())
    }

    pub async fn autocomplete(
        &self,
        source_id: String,
        text: String,
    ) -> BooruResult<Vec<BooruTagSuggestion>> {
        let adapter = self.registry.get(&source_id)?;
        if text.trim().chars().count()
            < adapter
                .definition()
                .capabilities
                .discovery
                .autocomplete_min_chars as usize
        {
            return Err(BooruError::invalid_request(Some(&source_id)));
        }
        if !adapter.definition().capabilities.supports_autocomplete {
            return Err(unsupported(&source_id));
        }
        if adapter.definition().family == ProtocolFamily::Gelbooru {
            return Ok(crate::booru::discovery::tags(
                &self.context(),
                adapter.definition(),
                Some(text.trim()),
                1,
                20,
            )
            .await?
            .items);
        }
        adapter.autocomplete(&self.context(), text.trim()).await
    }

    pub async fn feed(
        &self,
        mut request: crate::api::booru_models::FeedRequest,
    ) -> BooruResult<PostPage> {
        let adapter = self.registry.get(&request.source_id)?;
        crate::booru::discovery::validate_feed(adapter.definition(), &request)?;
        request.ratings = crate::booru::discovery::resolve_ratings(
            adapter.definition(),
            request.ratings,
            self.context()
                .runtime
                .auth_state(&request.source_id)?
                .status
                != crate::api::booru_auth::AuthStatus::NotConfigured,
        );
        let ratings = request.ratings.clone();
        let mut page = adapter.feed(&self.context(), request).await?;
        page.items.retain(|post| ratings.contains(&post.rating));
        Ok(PostPage {
            items: page.items.into_iter().map(|post| post.into_api()).collect(),
            next_cursor: page.next_cursor,
            exhausted: page.exhausted,
        })
    }

    pub async fn common_tags(
        &self,
        request: crate::api::booru_models::CommonTagsRequest,
    ) -> BooruResult<crate::api::booru_models::CommonTagsPage> {
        let adapter = self.registry.get(&request.source_id)?;
        crate::booru::discovery::tags(
            &self.context(),
            adapter.definition(),
            None,
            request.page,
            request.page_size,
        )
        .await
    }

    pub async fn related_posts(
        &self,
        source_id: String,
        post_id: String,
    ) -> BooruResult<Vec<BooruPost>> {
        let adapter = self.registry.get(&source_id)?;
        if !adapter.definition().capabilities.supports_related_posts {
            return Err(unsupported(&source_id));
        }
        Ok(adapter
            .related_posts(&self.context(), &PostId(post_id))
            .await?
            .into_iter()
            .map(|post| post.into_api())
            .collect())
    }

    pub fn auth_schema(&self, source_id: String) -> BooruResult<AuthSchema> {
        let adapter = self.registry.get(&source_id)?;
        Ok(auth_schema(
            &source_id,
            adapter.definition().capabilities.auth_kind,
        ))
    }

    pub fn auth_state(&self, source_id: String) -> BooruResult<AuthState> {
        self.registry.get(&source_id)?;
        self.sessions.state(&source_id)
    }

    pub async fn set_credentials(
        &self,
        source_id: String,
        credentials: SourceCredentials,
    ) -> BooruResult<AuthState> {
        let adapter = self.registry.get(&source_id)?;
        let state = self.sessions.set_credentials(
            &source_id,
            adapter.definition().capabilities.auth_kind,
            credentials,
        )?;
        self.runtime.invalidate_source(&source_id)?;
        Ok(state)
    }

    pub async fn set_web_session(
        &self,
        source_id: String,
        cookies: Vec<WebCookie>,
        user_agent: String,
    ) -> BooruResult<AuthState> {
        let adapter = self.registry.get(&source_id)?;
        if adapter.definition().capabilities.auth_kind
            != crate::api::booru_models::AuthKind::WebSession
        {
            return Err(unsupported(&source_id));
        }
        if cookies.iter().any(|cookie| {
            !adapter
                .definition()
                .allows_host(cookie.domain.trim().trim_start_matches('.'))
        }) {
            return Err(BooruError::invalid_request(Some(&source_id)));
        }
        let state = self
            .sessions
            .set_web_session(&source_id, cookies, user_agent)?;
        self.runtime.invalidate_source(&source_id)?;
        Ok(state)
    }

    pub async fn verify_auth(&self, source_id: String) -> BooruResult<AuthState> {
        let adapter = self.registry.get(&source_id)?;
        adapter.verify_auth(&self.context()).await
    }

    pub fn clear_auth(&self, source_id: String) -> BooruResult<()> {
        self.registry.get(&source_id)?;
        self.sessions.clear(&source_id)?;
        self.runtime.invalidate_source(&source_id)
    }

    pub async fn prepare_media(
        &self,
        source_id: String,
        post_id: String,
        variant: MediaVariantKind,
    ) -> BooruResult<MediaRequest> {
        let adapter = self.registry.get(&source_id)?;
        let prepared = adapter
            .prepare_media(&self.context(), &PostId(post_id.clone()), variant)
            .await?;
        let auth_revision = self.sessions.revision(&source_id);
        let route_revision = self.runtime.route_revision();
        Ok(MediaRequest {
            source_id: source_id.clone(),
            post_id,
            variant: prepared.media.kind,
            url: prepared.media.url.clone(),
            headers: prepared.headers,
            route_key: format!("{source_id}:{route_revision}"),
            cache_key: format!(
                "{source_id}:{}:{auth_revision}:{route_revision}",
                prepared.media.url
            ),
            auth_revision,
            route_revision,
            allow_disk_cache: prepared.allow_disk_cache,
        })
    }

    pub fn prepare_media_url(
        &self,
        source_id: String,
        post_id: String,
        variant: MediaVariantKind,
        url: String,
        allow_disk_cache: bool,
    ) -> BooruResult<MediaRequest> {
        let adapter = self.registry.get(&source_id)?;
        let url =
            reqwest::Url::parse(&url).map_err(|_| BooruError::invalid_request(Some(&source_id)))?;
        let headers = self.runtime.prepared_headers(adapter.definition(), &url)?;
        let auth_revision = self.sessions.revision(&source_id);
        let route_revision = self.runtime.route_revision();
        Ok(MediaRequest {
            source_id: source_id.clone(),
            post_id,
            variant,
            url: url.to_string(),
            headers,
            route_key: format!("{source_id}:{route_revision}"),
            cache_key: format!("{source_id}:{url}:{auth_revision}:{route_revision}"),
            auth_revision,
            route_revision,
            allow_disk_cache,
        })
    }

    pub async fn prepare_download(
        &self,
        source_id: String,
        post_id: String,
        variant: MediaVariantKind,
    ) -> BooruResult<PreparedDownload> {
        let adapter = self.registry.get(&source_id)?;
        let prepared = adapter
            .prepare_media(&self.context(), &PostId(post_id.clone()), variant)
            .await?;
        prepared_download(&source_id, &post_id, variant, prepared)
    }

    pub async fn stream_media(&self, request: MediaRequest, sink: StreamSink<MediaFetchEvent>) {
        // FRB exposes the sink as a Dart stream; a returned Result belongs to a
        // separate, unawaited Future. Deliver failures on the same event stream.
        if let Err(error) = self.stream_media_inner(request, &sink).await {
            let _ = sink.add(MediaFetchEvent::Failed { error });
        }
    }

    async fn stream_media_inner(
        &self,
        request: MediaRequest,
        sink: &StreamSink<MediaFetchEvent>,
    ) -> BooruResult<()> {
        let adapter = self.registry.get(&request.source_id)?;
        let prepared = PreparedDownload {
            source_id: request.source_id.clone(),
            post_id: request.post_id,
            variant: request.variant,
            url: request.url,
            headers: request.headers,
            expected_bytes_decimal: None,
            allowed_media_kinds: vec![crate::api::booru_models::MediaKind::Image],
            checksum: None,
            filename: "media.bin".to_owned(),
        };
        let response =
            open_prepared_unthrottled(&self.runtime, adapter.definition(), &prepared).await?;
        let total = response.content_length();
        let transcode_avif = prepared
            .url
            .split('?')
            .next()
            .is_some_and(|url| url.to_ascii_lowercase().ends_with(".avif"))
            || response
                .headers()
                .get(reqwest::header::CONTENT_TYPE)
                .and_then(|value| value.to_str().ok())
                .is_some_and(|value| value.to_ascii_lowercase().contains("image/avif"));
        let mut received = 0_u64;
        let mut avif_bytes = Vec::new();
        let mut chunks = response.bytes_stream();
        while let Some(chunk) = chunks.next().await {
            let chunk = chunk.map_err(|_| {
                BooruError::new(
                    BooruErrorCode::Network,
                    Some(&request.source_id),
                    "booru.error.network",
                )
            })?;
            received = received.saturating_add(chunk.len() as u64);
            let bytes = if transcode_avif {
                avif_bytes.extend_from_slice(&chunk);
                Vec::new()
            } else {
                chunk.to_vec()
            };
            sink.add(MediaFetchEvent::Chunk {
                bytes,
                received_bytes_decimal: received.to_string(),
                total_bytes_decimal: total.map(|value| value.to_string()),
            })
            .map_err(|_| {
                BooruError::new(
                    BooruErrorCode::Cancelled,
                    Some(&request.source_id),
                    "booru.error.cancelled",
                )
            })?;
        }
        if received == 0 {
            return Err(BooruError::new(
                BooruErrorCode::MediaValidationFailed,
                Some(&request.source_id),
                "booru.error.emptyDownload",
            ));
        }
        if transcode_avif {
            let source_id = request.source_id.clone();
            let png = tokio::task::spawn_blocking(move || avif_to_png(&source_id, &avif_bytes))
                .await
                .map_err(|_| {
                    BooruError::new(
                        BooruErrorCode::Internal,
                        Some(&request.source_id),
                        "booru.error.imageDecodeFailed",
                    )
                })??;
            let mut delivered = 0;
            for chunk in png.chunks(64 * 1024) {
                delivered += chunk.len();
                sink.add(MediaFetchEvent::Chunk {
                    bytes: chunk.to_vec(),
                    received_bytes_decimal: delivered.to_string(),
                    total_bytes_decimal: Some(png.len().to_string()),
                })
                .map_err(|_| {
                    BooruError::new(
                        BooruErrorCode::Cancelled,
                        Some(&request.source_id),
                        "booru.error.cancelled",
                    )
                })?;
            }
        }
        Ok(())
    }

    pub async fn download_to_file_stream(
        &self,
        request: DownloadRequest,
        sink: StreamSink<DownloadEvent>,
    ) -> BooruResult<()> {
        self.download_to_file(request, |event| {
            sink.add(event).map_err(|_| {
                BooruError::new(BooruErrorCode::Cancelled, None, "booru.error.cancelled")
            })
        })
        .await
    }

    pub async fn download_to_file<F>(
        &self,
        request: DownloadRequest,
        mut on_event: F,
    ) -> BooruResult<()>
    where
        F: FnMut(DownloadEvent) -> BooruResult<()>,
    {
        if request.download_root.trim().is_empty() {
            return Err(BooruError::invalid_request(Some(&request.source_id)));
        }
        let job_key = format!(
            "{}:{}:{:?}",
            request.source_id, request.post_id, request.variant
        );
        {
            let mut active = self.active_downloads.lock().map_err(|_| {
                BooruError::new(
                    BooruErrorCode::Internal,
                    Some(&request.source_id),
                    "booru.error.internal",
                )
            })?;
            if !active.insert(job_key.clone()) {
                return Err(BooruError::new(
                    BooruErrorCode::InvalidRequest,
                    Some(&request.source_id),
                    "booru.error.downloadAlreadyActive",
                ));
            }
        }
        let result = async {
            let adapter = self.registry.get(&request.source_id)?;
            let prepared_media = adapter
                .prepare_media(
                    &self.context(),
                    &PostId(request.post_id.clone()),
                    request.variant,
                )
                .await?;
            let prepared = prepared_download(
                &request.source_id,
                &request.post_id,
                request.variant,
                prepared_media,
            )?;
            let destination = PathBuf::from(&request.download_root)
                .join(&request.source_id)
                .join(&prepared.filename);
            let completed_path = download_to_path(
                &self.runtime,
                adapter.definition(),
                &prepared,
                &destination,
                |event: DownloadProgress| {
                    on_event(DownloadEvent::Progress {
                        received_bytes_decimal: event.received.to_string(),
                        total_bytes_decimal: event.total.map(|value| value.to_string()),
                        progress: event.progress,
                    })
                },
            )
            .await?;
            on_event(DownloadEvent::Done {
                path: completed_path.to_string_lossy().into_owned(),
            })?;
            Ok(())
        }
        .await;
        if let Ok(mut active) = self.active_downloads.lock() {
            active.remove(&job_key);
        }
        result
    }

    /// Check an actual API response using the active network configuration.
    pub async fn check_source(&self, source_id: String) -> BooruResult<()> {
        let adapter = self.registry.get(&source_id)?;
        tokio::time::timeout(
            std::time::Duration::from_secs(20),
            adapter.search(
                &self.context(),
                SearchQuery {
                    text: "rating:safe".into(),
                    ratings: vec![crate::api::booru_models::ContentRating::General],
                    page_size: 1,
                    cursor: None,
                },
            ),
        )
        .await
        .map_err(|_| {
            BooruError::new(
                BooruErrorCode::Timeout,
                Some(&source_id),
                "booru.error.timeout",
            )
        })??;
        Ok(())
    }

    pub async fn initialize_route_cache(&self) -> BooruResult<RouteCacheState> {
        let state = self.runtime.route_cache.initialize().await?;
        self.runtime.invalidate_all_clients()?;
        Ok(state)
    }

    pub fn route_cache_state(&self) -> BooruResult<RouteCacheState> {
        self.runtime.route_cache.snapshot()
    }

    pub async fn refresh_route_cache(&self) -> BooruResult<RouteCacheState> {
        let state = self.runtime.route_cache.refresh().await?;
        self.runtime.invalidate_all_clients()?;
        Ok(state)
    }

    fn context(&self) -> RequestContext {
        RequestContext {
            runtime: self.runtime.clone(),
        }
    }
}

fn unsupported(source_id: &str) -> BooruError {
    BooruError::new(
        BooruErrorCode::UnsupportedCapability,
        Some(source_id),
        "booru.error.unsupportedCapability",
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::booru_models::{ContentRating, NetworkFallbackMode};

    #[tokio::test]
    async fn empty_search_and_autocomplete_do_not_reach_network() {
        let engine = engine();
        for source in engine.list_sources() {
            let error = engine
                .autocomplete(source.source_id.clone(), "  ".into())
                .await
                .unwrap_err();
            assert_eq!(error.code, BooruErrorCode::InvalidRequest);
            let error = engine
                .search(SearchRequest {
                    source_id: source.source_id,
                    query_text: " ".into(),
                    ratings: vec![ContentRating::General],
                    page_size: 40,
                    cursor: None,
                })
                .await
                .unwrap_err();
            assert_eq!(error.code, BooruErrorCode::InvalidRequest);
        }
    }

    #[tokio::test]
    #[ignore = "manual default home acceptance, no media downloads"]
    async fn live_default_home_all_sources() {
        use crate::api::booru_models::{FeedKind, FeedRequest};
        let engine = engine();
        let mut failures = vec![];
        for source in engine.list_sources() {
            let result = tokio::time::timeout(
                std::time::Duration::from_secs(30),
                engine.feed(FeedRequest {
                    source_id: source.source_id.clone(),
                    kind: FeedKind::Latest,
                    range: None,
                    date: None,
                    seed: None,
                    ratings: vec![],
                    page_size: 40,
                    cursor: None,
                }),
            )
            .await;
            match result {
                Ok(Ok(page)) if !page.items.is_empty() => {
                    println!("HOME {}: {} items", source.source_id, page.items.len())
                }
                other => failures.push(format!(
                    "{}: {:?}",
                    source.source_id,
                    other.map(|r| r.map(|p| (p.items.len(), p.exhausted)).map_err(|e| e.code))
                )),
            }
        }
        assert!(failures.is_empty(), "{}", failures.join("\n"));
    }

    #[tokio::test]
    #[ignore = "manual discovery API smoke, no media downloads"]
    async fn live_discovery_smoke() {
        use crate::api::booru_models::{
            CapabilityAvailability, CommonTagsRequest, FeedKind, FeedRequest,
        };
        let engine = engine();
        let source_filter = std::env::var("BOORUFLOW_LIVE_SOURCE").ok();
        for source in engine.list_sources() {
            if source_filter
                .as_deref()
                .is_some_and(|id| id != source.source_id)
            {
                continue;
            }
            let mut modes = vec![(FeedKind::Latest, None)];
            modes.extend(
                source
                    .capabilities
                    .discovery
                    .popular_ranges
                    .iter()
                    .take(3)
                    .map(|range| (FeedKind::RecentPopular, Some(*range))),
            );
            modes.extend(
                source
                    .capabilities
                    .discovery
                    .historical_ranges
                    .iter()
                    .map(|range| (FeedKind::HistoricalPopular, Some(*range))),
            );
            for (kind, range) in modes {
                let request = FeedRequest {
                    source_id: source.source_id.clone(),
                    kind,
                    range,
                    date: (kind == FeedKind::HistoricalPopular).then(|| "2026-08-01".into()),
                    seed: None,
                    ratings: vec![ContentRating::General],
                    page_size: 12,
                    cursor: None,
                };
                let result =
                    tokio::time::timeout(std::time::Duration::from_secs(25), engine.feed(request))
                        .await;
                match result {
                    Ok(Ok(page)) => println!(
                        "DISCOVERY {} {kind:?} {range:?}: OK items={} exhausted={}",
                        source.source_id,
                        page.items.len(),
                        page.exhausted
                    ),
                    Ok(Err(error)) => println!(
                        "DISCOVERY {} {kind:?} {range:?}: {:?} HTTP={:?}",
                        source.source_id, error.code, error.http_status
                    ),
                    Err(_) => {
                        println!("DISCOVERY {} {kind:?} {range:?}: TIMEOUT", source.source_id)
                    }
                }
            }
            if source.capabilities.discovery.common_tags != CapabilityAvailability::Unsupported {
                match tokio::time::timeout(
                    std::time::Duration::from_secs(25),
                    engine.common_tags(CommonTagsRequest {
                        source_id: source.source_id.clone(),
                        page: 1,
                        page_size: 12,
                    }),
                )
                .await
                {
                    Ok(Ok(page)) => {
                        println!("TAGS {}: OK count={}", source.source_id, page.items.len())
                    }
                    Ok(Err(error)) => println!(
                        "TAGS {}: {:?} HTTP={:?}",
                        source.source_id, error.code, error.http_status
                    ),
                    Err(_) => println!("TAGS {}: TIMEOUT", source.source_id),
                }
                match tokio::time::timeout(
                    std::time::Duration::from_secs(25),
                    engine.autocomplete(source.source_id.clone(), "sky".into()),
                )
                .await
                {
                    Ok(Ok(items)) => println!(
                        "AUTOCOMPLETE {}: OK count={}",
                        source.source_id,
                        items.len()
                    ),
                    Ok(Err(error)) => println!(
                        "AUTOCOMPLETE {}: {:?} HTTP={:?}",
                        source.source_id, error.code, error.http_status
                    ),
                    Err(_) => println!("AUTOCOMPLETE {}: TIMEOUT", source.source_id),
                }
            }
        }
    }

    #[tokio::test]
    #[ignore = "manual Wallhaven extra discovery acceptance"]
    async fn live_wallhaven_extra_feeds() {
        use crate::api::booru_models::{FeedKind, FeedRequest};
        let engine = engine();
        for kind in [
            FeedKind::Random,
            FeedKind::LifetimeViews,
            FeedKind::LifetimeFavorites,
        ] {
            let mut cursor = None;
            let mut ids = BTreeSet::new();
            for page in 1..=3 {
                let result = engine
                    .feed(FeedRequest {
                        source_id: "wallhaven".into(),
                        kind,
                        range: None,
                        date: None,
                        seed: if kind == FeedKind::Random {
                            Some("bflow1".into())
                        } else {
                            None
                        },
                        ratings: vec![ContentRating::General],
                        page_size: 24,
                        cursor,
                    })
                    .await
                    .unwrap();
                assert!(!result.items.is_empty());
                for post in &result.items {
                    assert!(ids.insert(post.post_key.clone()), "duplicate in {kind:?}");
                }
                println!(
                    "EXTRA {kind:?} page={page} items={} unique={}",
                    result.items.len(),
                    ids.len()
                );
                cursor = result.next_cursor;
                if result.exhausted {
                    break;
                }
            }
        }
    }

    fn engine() -> BooruEngine {
        let directory = tempfile::tempdir().unwrap().keep();
        BooruEngine::new(BooruEngineConfig {
            app_support_directory: directory.to_string_lossy().to_string(),
            proxy_url: None,
            fallback_mode: NetworkFallbackMode::Off,
            dns_provider: crate::api::booru_models::RouteProvider::UncensoredDns,
            user_agent: "booruflow-test".to_owned(),
        })
        .unwrap()
    }

    #[test]
    fn exposes_all_sources_in_priority_order() {
        let ids = engine()
            .list_sources()
            .into_iter()
            .map(|source| source.source_id)
            .collect::<Vec<_>>();
        assert_eq!(
            ids,
            [
                "yande",
                "konachan_net",
                "danbooru",
                "aibooru",
                "gelbooru",
                "wallhaven",
                "anime_pictures"
            ]
        );
    }

    #[tokio::test]
    async fn rejects_unknown_source_without_network() {
        let error = engine()
            .get_post("unknown".to_owned(), "1".to_owned())
            .await
            .unwrap_err();
        assert_eq!(error.code, BooruErrorCode::InvalidRequest);
    }

    #[tokio::test]
    async fn rejects_unsupported_rating_and_capability_without_network() {
        let engine = engine();
        let error = engine
            .search(SearchRequest {
                source_id: "yande".to_owned(),
                query_text: String::new(),
                ratings: vec![ContentRating::Sensitive],
                page_size: 20,
                cursor: None,
            })
            .await
            .unwrap_err();
        assert_eq!(error.code, BooruErrorCode::InvalidRequest);

        let error = engine
            .autocomplete("wallhaven".to_owned(), "sky".to_owned())
            .await
            .unwrap_err();
        assert_eq!(error.code, BooruErrorCode::UnsupportedCapability);
    }

    #[tokio::test]
    async fn auth_replace_and_clear_change_revision() {
        let engine = engine();
        let first = engine
            .set_credentials(
                "wallhaven".to_owned(),
                SourceCredentials {
                    username: None,
                    user_id: None,
                    api_key: Some("first".to_owned()),
                },
            )
            .await
            .unwrap();
        let second = engine
            .set_credentials(
                "wallhaven".to_owned(),
                SourceCredentials {
                    username: None,
                    user_id: None,
                    api_key: Some("second".to_owned()),
                },
            )
            .await
            .unwrap();
        assert!(second.auth_revision > first.auth_revision);
        engine.clear_auth("wallhaven".to_owned()).unwrap();
        assert_eq!(
            engine.auth_state("wallhaven".to_owned()).unwrap().status,
            crate::api::booru_auth::AuthStatus::NotConfigured
        );
    }

    #[tokio::test]
    async fn web_session_rejects_cookie_domains_outside_source() {
        let error = engine()
            .set_web_session(
                "anime_pictures".to_owned(),
                vec![WebCookie {
                    name: "session".to_owned(),
                    value: "secret".to_owned(),
                    domain: "example.com".to_owned(),
                    path: "/".to_owned(),
                    secure: true,
                    expires_at_iso8601: None,
                }],
                "test-agent".to_owned(),
            )
            .await
            .unwrap_err();
        assert_eq!(error.code, BooruErrorCode::InvalidRequest);
    }

    #[tokio::test]
    async fn duplicate_download_job_is_rejected_before_network() {
        let engine = engine();
        engine
            .active_downloads
            .lock()
            .unwrap()
            .insert("yande:1:Original".to_owned());
        let error = engine
            .download_to_file(
                DownloadRequest {
                    source_id: "yande".to_owned(),
                    post_id: "1".to_owned(),
                    variant: MediaVariantKind::Original,
                    download_root: "downloads".to_owned(),
                },
                |_| Ok(()),
            )
            .await
            .unwrap_err();
        assert_eq!(error.user_message_key, "booru.error.downloadAlreadyActive");
    }

    #[tokio::test]
    #[ignore = "checks actual APIs with selected DNS and bypass; no media downloads"]
    async fn live_network_settings_checks_all_sources() {
        let directory = tempfile::tempdir().unwrap();
        let engine = BooruEngine::new(BooruEngineConfig {
            app_support_directory: directory.path().to_string_lossy().into_owned(),
            proxy_url: None,
            fallback_mode: NetworkFallbackMode::PersistedIpOverride,
            dns_provider: crate::api::booru_models::RouteProvider::UncensoredDns,
            user_agent: "BooruFlow/0.10.0".into(),
        })
        .unwrap();
        engine.refresh_route_cache().await.unwrap();
        let results =
            futures_util::future::join_all(engine.list_sources().into_iter().map(|source| {
                let engine = &engine;
                async move {
                    (
                        source.source_id.clone(),
                        engine.check_source(source.source_id).await,
                    )
                }
            }))
            .await;
        for (source, result) in &results {
            println!("{source}: {result:?}");
        }
        assert!(results
            .iter()
            .any(|(source, result)| source == "yande" && result.is_ok()));
    }

    #[tokio::test]
    #[ignore = "live anonymous network test; writes media under rust/test-downloads"]
    async fn live_anonymous_downloads_five_from_every_source() {
        let manifest = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let output_root = manifest.join("test-downloads");
        let support = manifest.join("target").join("live-test-support");
        let bypass = std::env::var("BOORUFLOW_LIVE_BYPASS").as_deref() == Ok("1");
        let variant = match std::env::var("BOORUFLOW_LIVE_VARIANT").as_deref() {
            Ok("thumbnail") => MediaVariantKind::Thumbnail,
            Ok("preview") => MediaVariantKind::Preview,
            Ok("sample") => MediaVariantKind::Sample,
            _ => MediaVariantKind::Original,
        };
        let engine = BooruEngine::new(BooruEngineConfig {
            app_support_directory: support.to_string_lossy().into_owned(),
            proxy_url: None,
            fallback_mode: if bypass {
                NetworkFallbackMode::PersistedIpOverride
            } else {
                NetworkFallbackMode::Off
            },
            dns_provider: crate::api::booru_models::RouteProvider::UncensoredDns,
            user_agent: "BooruFlow/1.0".to_owned(),
        })
        .unwrap();
        if bypass {
            engine.refresh_route_cache().await.unwrap();
        }
        let mut failures = Vec::new();
        let source_filter = std::env::var("BOORUFLOW_LIVE_SOURCE").ok();
        let post_filter = std::env::var("BOORUFLOW_LIVE_POST_ID").ok();
        assert!(
            post_filter.is_none() || source_filter.is_some(),
            "BOORUFLOW_LIVE_POST_ID requires BOORUFLOW_LIVE_SOURCE"
        );
        for source in engine.list_sources() {
            if source_filter
                .as_deref()
                .is_some_and(|filter| filter != source.source_id)
            {
                continue;
            }
            assert_eq!(
                engine.auth_state(source.source_id.clone()).unwrap().status,
                crate::api::booru_auth::AuthStatus::NotConfigured
            );
            let expected_posts = if post_filter.is_some() { 1 } else { 5 };
            let posts = if let Some(post_id) = post_filter.as_ref() {
                match engine
                    .get_post(source.source_id.clone(), post_id.clone())
                    .await
                {
                    Ok(post) => vec![post],
                    Err(error) => {
                        failures.push(format!(
                            "post lookup failed for {} post {}: {}",
                            source.source_id, post_id, error,
                        ));
                        continue;
                    }
                }
            } else {
                match engine
                    .feed(crate::api::booru_models::FeedRequest {
                        source_id: source.source_id.clone(),
                        kind: crate::api::booru_models::FeedKind::Latest,
                        range: None,
                        date: None,
                        seed: None,
                        ratings: source.capabilities.ratings.clone(),
                        page_size: 5,
                        cursor: None,
                    })
                    .await
                {
                    Ok(page) => page.items,
                    Err(error) => {
                        failures.push(format!(
                            "anonymous search failed for {}: {}",
                            source.source_id, error
                        ));
                        continue;
                    }
                }
            };
            if posts.len() < expected_posts {
                failures.push(format!(
                    "anonymous lookup returned {} posts for {} (expected {})",
                    posts.len(),
                    source.source_id,
                    expected_posts,
                ));
                continue;
            }

            for post in posts.into_iter().take(expected_posts) {
                let post_id = post.post_id.clone();
                let prepared = engine
                    .prepare_media(source.source_id.clone(), post_id.clone(), variant)
                    .await;
                match prepared {
                    Ok(prepared)
                        if variant == MediaVariantKind::Original
                            && prepared.variant != MediaVariantKind::Original =>
                    {
                        failures.push(format!(
                            "original request silently downgraded for {} post {}",
                            source.source_id, post_id,
                        ));
                        continue;
                    }
                    Ok(prepared) => {
                        println!(
                            "fetching {:?} as {:?}: {}",
                            variant, prepared.variant, prepared.url,
                        );
                    }
                    Err(error) => {
                        failures.push(format!(
                            "{variant:?} preparation failed for {} post {}: {}",
                            source.source_id, post_id, error,
                        ));
                        continue;
                    }
                }
                let mut completed_path = None;
                let result = engine
                    .download_to_file(
                        DownloadRequest {
                            source_id: post.source_id,
                            post_id: post.post_id,
                            variant,
                            download_root: output_root.to_string_lossy().into_owned(),
                        },
                        |event| {
                            if let DownloadEvent::Done { path } = event {
                                completed_path = Some(path);
                            }
                            Ok(())
                        },
                    )
                    .await;
                if let Err(error) = result {
                    failures.push(format!(
                        "{variant:?} download failed for {} post {}: {}",
                        source.source_id, post_id, error,
                    ));
                    continue;
                }
                let Some(completed_path) = completed_path else {
                    failures.push(format!(
                        "{variant:?} download emitted no Done event for {} post {}",
                        source.source_id, post_id,
                    ));
                    continue;
                };
                let completed_path = PathBuf::from(completed_path);
                assert!(completed_path.starts_with(output_root.join(&source.source_id)));
                assert!(tokio::fs::try_exists(&completed_path).await.unwrap());
                assert!(tokio::fs::metadata(&completed_path).await.unwrap().len() > 0);
                if source.source_id == "anime_pictures" && variant != MediaVariantKind::Original {
                    let avif = tokio::fs::read(&completed_path).await.unwrap();
                    let png = avif_to_png(&source.source_id, &avif).unwrap();
                    assert!(png.starts_with(&[137, 80, 78, 71, 13, 10, 26, 10]));
                }
                println!("downloaded {}", completed_path.display());
            }
        }
        assert!(
            failures.is_empty(),
            "live source failures:\n{}",
            failures.join("\n")
        );
    }
}
