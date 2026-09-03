use crate::api::booru_auth::{AuthSchemaDto, AuthStateDto, SourceCredentialsDto, WebCookieDto};
use crate::api::booru_download::{DownloadEventDto, DownloadRequestDto, PreparedDownloadDto};
use crate::api::booru_models::{
    BooruEngineConfigDto, BooruPostDto, BooruSourceDto, MediaRequestDto, MediaVariantKind,
    PostPageDto, RouteCacheStateDto, SearchRequestDto, TagSuggestionDto,
};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::anime_pictures::AnimePicturesAdapter;
use crate::booru::adapters::danbooru::DanbooruAdapter;
use crate::booru::adapters::gelbooru::GelbooruAdapter;
use crate::booru::adapters::moebooru::MoebooruAdapter;
use crate::booru::adapters::wallhaven::WallhavenAdapter;
use crate::booru::auth::credential::auth_schema;
use crate::booru::auth::SessionStore;
use crate::booru::error::{BooruErrorCode, BooruErrorDto, BooruResult};
use crate::booru::media::download::{download_to_path, DownloadProgress};
use crate::booru::media::request::prepared_download;
use crate::booru::model::{PostId, SearchQuery};
use crate::booru::network::NetworkRuntime;
use crate::booru::registry::SourceRegistry;
use crate::booru::source::{builtin_sources, ProtocolFamily};
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
    pub fn new(config: BooruEngineConfigDto) -> BooruResult<Self> {
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

    pub fn list_sources(&self) -> Vec<BooruSourceDto> {
        self.registry
            .all()
            .map(|adapter| adapter.definition().to_dto())
            .collect()
    }

    pub async fn search(&self, request: SearchRequestDto) -> BooruResult<PostPageDto> {
        let adapter = self.registry.get(&request.source_id)?;
        let capabilities = &adapter.definition().capabilities;
        if !capabilities.supports_search
            || request.page_size == 0
            || request
                .ratings
                .iter()
                .any(|rating| !capabilities.ratings.contains(rating))
        {
            return Err(BooruErrorDto::invalid_request(Some(&request.source_id)));
        }
        let query = SearchQuery {
            text: request.query_text,
            ratings: request.ratings,
            page_size: request.page_size,
            cursor: request.cursor,
            content_policy: request.content_policy,
        };
        let page = adapter.search(&self.context(), query).await?;
        Ok(PostPageDto {
            items: page.items.into_iter().map(|post| post.into_dto()).collect(),
            next_cursor: page.next_cursor,
            exhausted: page.exhausted,
        })
    }

    pub async fn get_post(&self, source_id: String, post_id: String) -> BooruResult<BooruPostDto> {
        let adapter = self.registry.get(&source_id)?;
        adapter
            .get_post(&self.context(), &PostId(post_id))
            .await
            .map(|post| post.into_dto())
    }

    pub async fn autocomplete(
        &self,
        source_id: String,
        text: String,
    ) -> BooruResult<Vec<TagSuggestionDto>> {
        let adapter = self.registry.get(&source_id)?;
        if !adapter.definition().capabilities.supports_autocomplete {
            return Err(unsupported(&source_id));
        }
        adapter.autocomplete(&self.context(), text.trim()).await
    }

    pub async fn related_posts(
        &self,
        source_id: String,
        post_id: String,
    ) -> BooruResult<Vec<BooruPostDto>> {
        let adapter = self.registry.get(&source_id)?;
        if !adapter.definition().capabilities.supports_related_posts {
            return Err(unsupported(&source_id));
        }
        Ok(adapter
            .related_posts(&self.context(), &PostId(post_id))
            .await?
            .into_iter()
            .map(|post| post.into_dto())
            .collect())
    }

    pub fn auth_schema(&self, source_id: String) -> BooruResult<AuthSchemaDto> {
        let adapter = self.registry.get(&source_id)?;
        Ok(auth_schema(
            &source_id,
            adapter.definition().capabilities.auth_kind,
        ))
    }

    pub fn auth_state(&self, source_id: String) -> BooruResult<AuthStateDto> {
        self.registry.get(&source_id)?;
        self.sessions.state(&source_id)
    }

    pub async fn set_credentials(
        &self,
        source_id: String,
        credentials: SourceCredentialsDto,
    ) -> BooruResult<AuthStateDto> {
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
        cookies: Vec<WebCookieDto>,
        user_agent: String,
    ) -> BooruResult<AuthStateDto> {
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
            return Err(BooruErrorDto::invalid_request(Some(&source_id)));
        }
        let state = self
            .sessions
            .set_web_session(&source_id, cookies, user_agent)?;
        self.runtime.invalidate_source(&source_id)?;
        Ok(state)
    }

    pub async fn verify_auth(&self, source_id: String) -> BooruResult<AuthStateDto> {
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
    ) -> BooruResult<MediaRequestDto> {
        let adapter = self.registry.get(&source_id)?;
        let prepared = adapter
            .prepare_media(&self.context(), &PostId(post_id.clone()), variant)
            .await?;
        let auth_revision = self.sessions.revision(&source_id);
        let route_revision = self.runtime.route_revision();
        Ok(MediaRequestDto {
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

    pub async fn prepare_download(
        &self,
        source_id: String,
        post_id: String,
        variant: MediaVariantKind,
    ) -> BooruResult<PreparedDownloadDto> {
        let adapter = self.registry.get(&source_id)?;
        let prepared = adapter
            .prepare_media(&self.context(), &PostId(post_id.clone()), variant)
            .await?;
        prepared_download(&source_id, &post_id, variant, prepared)
    }

    pub async fn download_to_file<F>(
        &self,
        request: DownloadRequestDto,
        mut on_event: F,
    ) -> BooruResult<()>
    where
        F: FnMut(DownloadEventDto) -> BooruResult<()>,
    {
        if request.download_root.trim().is_empty() {
            return Err(BooruErrorDto::invalid_request(Some(&request.source_id)));
        }
        let job_key = format!(
            "{}:{}:{:?}",
            request.source_id, request.post_id, request.variant
        );
        {
            let mut active = self.active_downloads.lock().map_err(|_| {
                BooruErrorDto::new(
                    BooruErrorCode::Internal,
                    Some(&request.source_id),
                    "booru.error.internal",
                )
            })?;
            if !active.insert(job_key.clone()) {
                return Err(BooruErrorDto::new(
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
                    on_event(DownloadEventDto::Progress {
                        received_bytes_decimal: event.received.to_string(),
                        total_bytes_decimal: event.total.map(|value| value.to_string()),
                        progress: event.progress,
                    })
                },
            )
            .await?;
            on_event(DownloadEventDto::Done {
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

    pub async fn initialize_route_cache(&self) -> BooruResult<RouteCacheStateDto> {
        let state = self.runtime.route_cache.initialize().await?;
        self.runtime.invalidate_all_clients()?;
        Ok(state)
    }

    pub fn route_cache_state(&self) -> BooruResult<RouteCacheStateDto> {
        self.runtime.route_cache.snapshot()
    }

    pub async fn refresh_route_cache(&self) -> BooruResult<RouteCacheStateDto> {
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

fn unsupported(source_id: &str) -> BooruErrorDto {
    BooruErrorDto::new(
        BooruErrorCode::UnsupportedCapability,
        Some(source_id),
        "booru.error.unsupportedCapability",
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::booru_models::{ContentPolicy, ContentRating, NetworkFallbackMode};

    fn engine() -> BooruEngine {
        let directory = tempfile::tempdir().unwrap().keep();
        BooruEngine::new(BooruEngineConfigDto {
            app_support_directory: directory.to_string_lossy().to_string(),
            proxy_url: None,
            fallback_mode: NetworkFallbackMode::Off,
            fallback_to_system_dns: true,
            user_agent: "yande_gui-test".to_owned(),
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
            .search(SearchRequestDto {
                source_id: "yande".to_owned(),
                query_text: String::new(),
                ratings: vec![ContentRating::Sensitive],
                page_size: 20,
                cursor: None,
                content_policy: ContentPolicy::AnimeFocused,
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
                SourceCredentialsDto {
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
                SourceCredentialsDto {
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
                vec![WebCookieDto {
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
                DownloadRequestDto {
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
    #[ignore = "live anonymous network test; writes 35 originals under rust/test-downloads"]
    async fn live_anonymous_downloads_five_originals_from_every_source() {
        let manifest = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let output_root = manifest.join("test-downloads");
        let support = manifest.join("target").join("live-test-support");
        let engine = BooruEngine::new(BooruEngineConfigDto {
            app_support_directory: support.to_string_lossy().into_owned(),
            proxy_url: None,
            fallback_mode: NetworkFallbackMode::Off,
            fallback_to_system_dns: true,
            user_agent: "anybooru/1.0".to_owned(),
        })
        .unwrap();
        let mut failures = Vec::new();
        let source_filter = std::env::var("ANYBOORU_LIVE_SOURCE").ok();
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
            let page = match engine
                .search(SearchRequestDto {
                    source_id: source.source_id.clone(),
                    query_text: String::new(),
                    ratings: Vec::new(),
                    page_size: 5,
                    cursor: None,
                    content_policy: ContentPolicy::Unfiltered,
                })
                .await
            {
                Ok(page) => page,
                Err(error) => {
                    failures.push(format!(
                        "anonymous search failed for {}: {}",
                        source.source_id, error
                    ));
                    continue;
                }
            };
            if page.items.len() < 5 {
                failures.push(format!(
                    "anonymous search returned {} posts for {} (expected 5)",
                    page.items.len(),
                    source.source_id
                ));
                continue;
            }

            for post in page.items.into_iter().take(5) {
                let post_id = post.post_id.clone();
                let prepared = engine
                    .prepare_media(
                        source.source_id.clone(),
                        post_id.clone(),
                        MediaVariantKind::Original,
                    )
                    .await;
                match prepared {
                    Ok(prepared) if prepared.variant == MediaVariantKind::Original => {}
                    Ok(_) => {
                        failures.push(format!(
                            "original request silently downgraded for {} post {}",
                            source.source_id, post_id
                        ));
                        continue;
                    }
                    Err(error) => {
                        failures.push(format!(
                            "original preparation failed for {} post {}: {}",
                            source.source_id, post_id, error
                        ));
                        continue;
                    }
                }
                let mut completed_path = None;
                let result = engine
                    .download_to_file(
                        DownloadRequestDto {
                            source_id: post.source_id,
                            post_id: post.post_id,
                            variant: MediaVariantKind::Original,
                            download_root: output_root.to_string_lossy().into_owned(),
                        },
                        |event| {
                            if let DownloadEventDto::Done { path } = event {
                                completed_path = Some(path);
                            }
                            Ok(())
                        },
                    )
                    .await;
                if let Err(error) = result {
                    failures.push(format!(
                        "original download failed for {} post {}: {}",
                        source.source_id, post_id, error
                    ));
                    continue;
                }
                let Some(completed_path) = completed_path else {
                    failures.push(format!(
                        "original download emitted no Done event for {} post {}",
                        source.source_id, post_id
                    ));
                    continue;
                };
                let completed_path = PathBuf::from(completed_path);
                assert!(completed_path.starts_with(output_root.join(&source.source_id)));
                assert!(tokio::fs::try_exists(&completed_path).await.unwrap());
                assert!(tokio::fs::metadata(&completed_path).await.unwrap().len() > 0);
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
