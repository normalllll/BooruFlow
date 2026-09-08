use crate::api::booru_auth::AuthStateDto;
use crate::api::booru_models::{BooruEngineConfigDto, HttpHeaderDto, NetworkFallbackMode};
use crate::booru::auth::SessionStore;
use crate::booru::error::{BooruErrorCode, BooruErrorDto, BooruResult};
use crate::booru::network::challenge::looks_like_challenge;
use crate::booru::network::rate_limit::RateLimiter;
use crate::booru::network::route_cache::RouteCache;
use crate::booru::source::{ProtocolFamily, SourceDefinition};
use crate::booru::user_agent::{normalize_user_agent, BROWSER_USER_AGENT};
use reqwest::header::{
    HeaderMap, HeaderName, HeaderValue, ACCEPT, AUTHORIZATION, COOKIE, HOST, LOCATION, REFERER,
    RETRY_AFTER, USER_AGENT,
};
use reqwest::{Client, StatusCode, Url};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::Duration;

const MAX_REDIRECTS: u32 = 5;
const MAX_ATTEMPTS: u32 = 3;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResponseKind {
    Json,
    Html,
    Media,
}

#[derive(Clone)]
pub struct RequestSpec {
    pub url: Url,
    pub query: Vec<(String, String)>,
    pub headers: Vec<(String, String)>,
    pub response_kind: ResponseKind,
    pub follow_redirects: bool,
    pub allow_protected_headers: bool,
}

impl RequestSpec {
    pub fn get(url: Url, response_kind: ResponseKind) -> Self {
        Self {
            url,
            query: Vec::new(),
            headers: Vec::new(),
            response_kind,
            follow_redirects: true,
            allow_protected_headers: false,
        }
    }
}

#[derive(Debug)]
pub struct NetworkResponse {
    pub body: Vec<u8>,
}

pub struct NetworkRuntime {
    config: BooruEngineConfigDto,
    sessions: Arc<SessionStore>,
    clients: Mutex<HashMap<String, Client>>,
    limiters: HashMap<&'static str, RateLimiter>,
    cooldowns: Mutex<HashMap<&'static str, std::time::Instant>>,
    pub route_cache: RouteCache,
}

impl NetworkRuntime {
    fn check_cooldown(&self, source: &'static str) -> BooruResult<()> {
        if let Some(seconds) = self.cooldowns.lock().ok().and_then(|values| {
            values
                .get(source)
                .and_then(|until| until.checked_duration_since(std::time::Instant::now()))
                .map(|remaining| {
                    u32::try_from(remaining.as_secs().saturating_add(1)).unwrap_or(u32::MAX)
                })
        }) {
            return Err(BooruErrorDto::new(
                BooruErrorCode::RateLimited,
                Some(source),
                "booru.error.rateLimited",
            )
            .with_retry_after(Some(seconds)));
        }
        Ok(())
    }

    fn defer_source(&self, source: &'static str, seconds: u32) {
        if let Ok(mut values) = self.cooldowns.lock() {
            if let Some(until) =
                std::time::Instant::now().checked_add(Duration::from_secs(u64::from(seconds)))
            {
                values.insert(source, until);
            }
        }
    }

    pub fn new(
        mut config: BooruEngineConfigDto,
        sources: &[SourceDefinition],
        sessions: Arc<SessionStore>,
    ) -> BooruResult<Self> {
        if config.app_support_directory.trim().is_empty() {
            return Err(BooruErrorDto::invalid_request(None));
        }
        config.user_agent = normalize_user_agent(&config.user_agent);
        if let Some(proxy) = config.proxy_url.as_deref() {
            reqwest::Proxy::all(proxy).map_err(|_| BooruErrorDto::invalid_request(None))?;
        }
        let limiters = sources
            .iter()
            .map(|source| {
                (
                    source.id,
                    RateLimiter::new(source.requests_per_minute, source.max_concurrency),
                )
            })
            .collect();
        Ok(Self {
            route_cache: RouteCache::new(&config.app_support_directory, sources),
            config,
            sessions,
            clients: Mutex::new(HashMap::new()),
            limiters,
            cooldowns: Mutex::new(HashMap::new()),
        })
    }

    pub async fn execute(
        &self,
        source: &SourceDefinition,
        mut spec: RequestSpec,
    ) -> BooruResult<NetworkResponse> {
        for (key, value) in &spec.query {
            spec.url.query_pairs_mut().append_pair(key, value);
        }
        let limiter = self.limiters.get(source.id).ok_or_else(|| {
            BooruErrorDto::new(
                BooruErrorCode::Internal,
                Some(source.id),
                "booru.error.internal",
            )
        })?;
        let _permit = limiter.acquire().await.map_err(|_| {
            BooruErrorDto::new(
                BooruErrorCode::Cancelled,
                Some(source.id),
                "booru.error.cancelled",
            )
        })?;

        let mut redirects = 0_u32;
        let mut force_system_dns = false;
        let mut url = spec.url.clone();
        'request: loop {
            let authenticated_url = self.authenticated_url(source, &url)?;
            let logical_host = validate_url(source, &authenticated_url)?;
            let mut headers = self.request_headers(
                source,
                &authenticated_url,
                &spec.headers,
                spec.allow_protected_headers,
            )?;
            let mut request_url = authenticated_url.clone();
            let route_mode_active = self.route_mode_active() && !force_system_dns;
            let route_candidates = self.route_cache.candidates(&logical_host);
            if route_mode_active && route_candidates.is_empty() {
                if self.config.fallback_to_system_dns {
                    force_system_dns = true;
                    continue;
                }
                return Err(missing_route(source.id));
            }
            let legacy_ip = (route_mode_active
                && self.config.fallback_mode == NetworkFallbackMode::LegacyIpUrl)
                .then(|| route_candidates.first().copied())
                .flatten();
            if let Some(ip) = legacy_ip {
                request_url
                    .set_host(Some(&ip.to_string()))
                    .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?;
                headers.insert(
                    HOST,
                    HeaderValue::from_str(&url_authority(&authenticated_url))
                        .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?,
                );
            }
            let client = self.client(source, force_system_dns)?;
            let attempt_count = if legacy_ip.is_some() {
                u32::try_from(route_candidates.len().min(MAX_ATTEMPTS as usize))
                    .unwrap_or(MAX_ATTEMPTS)
            } else {
                MAX_ATTEMPTS
            };
            for attempt in 1..=attempt_count {
                self.check_cooldown(source.id)?;
                if legacy_ip.is_some() {
                    let index = usize::try_from(attempt - 1).unwrap_or_default();
                    request_url
                        .set_host(
                            route_candidates
                                .get(index)
                                .map(ToString::to_string)
                                .as_deref(),
                        )
                        .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?;
                }
                match client
                    .get(request_url.clone())
                    .headers(headers.clone())
                    .send()
                    .await
                {
                    Ok(response) => {
                        let status = response.status();
                        let response_url = response.url().clone();
                        let response_headers = response.headers().clone();
                        if status.is_redirection() {
                            if !spec.follow_redirects {
                                return Ok(NetworkResponse { body: Vec::new() });
                            }
                            redirects += 1;
                            if redirects > MAX_REDIRECTS {
                                return Err(BooruErrorDto::new(
                                    BooruErrorCode::UnsafeRedirect,
                                    Some(source.id),
                                    "booru.error.tooManyRedirects",
                                ));
                            }
                            let location = response_headers
                                .get(LOCATION)
                                .and_then(|value| value.to_str().ok())
                                .ok_or_else(|| {
                                    BooruErrorDto::new(
                                        BooruErrorCode::UnsafeRedirect,
                                        Some(source.id),
                                        "booru.error.invalidRedirect",
                                    )
                                })?;
                            url = response_url.join(location).map_err(|_| {
                                BooruErrorDto::new(
                                    BooruErrorCode::UnsafeRedirect,
                                    Some(source.id),
                                    "booru.error.invalidRedirect",
                                )
                            })?;
                            validate_url(source, &url)?;
                            strip_redirect_sensitive_headers(&mut spec);
                            force_system_dns = false;
                            continue 'request;
                        }
                        let retry_after = retry_after_seconds(&response_headers);
                        if status.as_u16() == 429 {
                            self.defer_source(source.id, retry_after.unwrap_or(60));
                            return Err(classify_status(
                                source.id,
                                status,
                                Some(retry_after.unwrap_or(60)),
                                self.sessions.is_configured(source.id),
                            ));
                        }
                        if matches!(status.as_u16(), 502 | 503) && attempt < MAX_ATTEMPTS {
                            tokio::time::sleep(retry_delay(attempt, retry_after)).await;
                            continue;
                        }
                        let body = response
                            .bytes()
                            .await
                            .map_err(|error| classify_reqwest_error(source.id, &error))?;
                        let body = body.to_vec();
                        if looks_like_challenge(
                            &response_headers,
                            &body,
                            status.is_success() && spec.response_kind == ResponseKind::Json,
                        ) {
                            return Err(BooruErrorDto::new(
                                BooruErrorCode::ChallengeRequired,
                                Some(source.id),
                                "booru.error.challengeRequired",
                            )
                            .with_http_status(u32::from(status.as_u16())));
                        }
                        if !status.is_success() {
                            return Err(classify_status(
                                source.id,
                                status,
                                retry_after,
                                self.sessions.is_configured(source.id),
                            ));
                        }
                        if spec.response_kind == ResponseKind::Media
                            && response_headers
                                .get(reqwest::header::CONTENT_TYPE)
                                .and_then(|value| value.to_str().ok())
                                .is_some_and(|value| {
                                    value.to_ascii_lowercase().contains("text/html")
                                })
                        {
                            return Err(BooruErrorDto::new(
                                BooruErrorCode::MediaValidationFailed,
                                Some(source.id),
                                "booru.error.invalidMediaType",
                            ));
                        }
                        return Ok(NetworkResponse { body });
                    }
                    Err(error)
                        if attempt < MAX_ATTEMPTS && (error.is_connect() || error.is_timeout()) =>
                    {
                        tokio::time::sleep(retry_delay(attempt, None)).await;
                    }
                    Err(error) => return Err(classify_reqwest_error(source.id, &error)),
                }
            }
            if route_mode_active && self.config.fallback_to_system_dns {
                force_system_dns = true;
                continue;
            }
            return Err(BooruErrorDto::new(
                BooruErrorCode::Network,
                Some(source.id),
                "booru.error.network",
            ));
        }
    }

    pub async fn open_media(
        &self,
        source: &SourceDefinition,
        spec: RequestSpec,
    ) -> BooruResult<reqwest::Response> {
        let limiter = self
            .limiters
            .get(source.id)
            .ok_or_else(|| internal_error(source.id))?;
        let _permit = limiter.acquire().await.map_err(|_| {
            BooruErrorDto::new(
                BooruErrorCode::Cancelled,
                Some(source.id),
                "booru.error.cancelled",
            )
        })?;
        self.open_media_inner(source, spec).await
    }

    pub async fn open_media_unthrottled(
        &self,
        source: &SourceDefinition,
        spec: RequestSpec,
    ) -> BooruResult<reqwest::Response> {
        self.open_media_inner(source, spec).await
    }

    async fn open_media_inner(
        &self,
        source: &SourceDefinition,
        mut spec: RequestSpec,
    ) -> BooruResult<reqwest::Response> {
        for (key, value) in &spec.query {
            spec.url.query_pairs_mut().append_pair(key, value);
        }
        let mut redirects = 0_u32;
        let mut force_system_dns = false;
        let mut url = spec.url.clone();
        'request: loop {
            let authenticated_url = self.authenticated_url(source, &url)?;
            let logical_host = validate_url(source, &authenticated_url)?;
            let mut headers = self.request_headers(
                source,
                &authenticated_url,
                &spec.headers,
                spec.allow_protected_headers,
            )?;
            let mut request_url = authenticated_url.clone();
            let route_mode_active = self.route_mode_active() && !force_system_dns;
            let route_candidates = self.route_cache.candidates(&logical_host);
            if route_mode_active && route_candidates.is_empty() {
                if self.config.fallback_to_system_dns {
                    force_system_dns = true;
                    continue;
                }
                return Err(missing_route(source.id));
            }
            let legacy_ip = (route_mode_active
                && self.config.fallback_mode == NetworkFallbackMode::LegacyIpUrl)
                .then(|| route_candidates.first().copied())
                .flatten();
            if let Some(ip) = legacy_ip {
                request_url
                    .set_host(Some(&ip.to_string()))
                    .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?;
                headers.insert(
                    HOST,
                    HeaderValue::from_str(&url_authority(&authenticated_url))
                        .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?,
                );
            }
            let client = self.client(source, force_system_dns)?;
            let attempt_count = if legacy_ip.is_some() {
                u32::try_from(route_candidates.len().min(MAX_ATTEMPTS as usize))
                    .unwrap_or(MAX_ATTEMPTS)
            } else {
                MAX_ATTEMPTS
            };
            for attempt in 1..=attempt_count {
                if legacy_ip.is_some() {
                    let index = usize::try_from(attempt - 1).unwrap_or_default();
                    request_url
                        .set_host(
                            route_candidates
                                .get(index)
                                .map(ToString::to_string)
                                .as_deref(),
                        )
                        .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?;
                }
                self.check_cooldown(source.id)?;
                let response = match client
                    .get(request_url.clone())
                    .headers(headers.clone())
                    .send()
                    .await
                {
                    Ok(response) => response,
                    Err(error)
                        if attempt < MAX_ATTEMPTS && (error.is_connect() || error.is_timeout()) =>
                    {
                        tokio::time::sleep(retry_delay(attempt, None)).await;
                        continue;
                    }
                    Err(error) => return Err(classify_reqwest_error(source.id, &error)),
                };
                let status = response.status();
                let retry_after = retry_after_seconds(response.headers());
                if status.as_u16() == 429 {
                    let seconds = retry_after.unwrap_or(60);
                    self.defer_source(source.id, seconds);
                    return Err(classify_status(
                        source.id,
                        status,
                        Some(seconds),
                        self.sessions.is_configured(source.id),
                    ));
                }
                if matches!(status.as_u16(), 502 | 503) && attempt < MAX_ATTEMPTS {
                    tokio::time::sleep(retry_delay(attempt, retry_after)).await;
                    continue;
                }
                if status.is_redirection() {
                    if !spec.follow_redirects {
                        return Ok(response);
                    }
                    redirects += 1;
                    if redirects > MAX_REDIRECTS {
                        return Err(BooruErrorDto::new(
                            BooruErrorCode::UnsafeRedirect,
                            Some(source.id),
                            "booru.error.tooManyRedirects",
                        ));
                    }
                    let location = response
                        .headers()
                        .get(LOCATION)
                        .and_then(|value| value.to_str().ok())
                        .ok_or_else(|| {
                            BooruErrorDto::new(
                                BooruErrorCode::UnsafeRedirect,
                                Some(source.id),
                                "booru.error.invalidRedirect",
                            )
                        })?;
                    url = response.url().join(location).map_err(|_| {
                        BooruErrorDto::new(
                            BooruErrorCode::UnsafeRedirect,
                            Some(source.id),
                            "booru.error.invalidRedirect",
                        )
                    })?;
                    validate_url(source, &url)?;
                    strip_redirect_sensitive_headers(&mut spec);
                    force_system_dns = false;
                    continue 'request;
                }
                if !status.is_success() {
                    let response_headers = response.headers().clone();
                    let body = response
                        .bytes()
                        .await
                        .map_err(|error| classify_reqwest_error(source.id, &error))?;
                    if looks_like_challenge(&response_headers, &body, false) {
                        return Err(BooruErrorDto::new(
                            BooruErrorCode::ChallengeRequired,
                            Some(source.id),
                            "booru.error.challengeRequired",
                        )
                        .with_http_status(u32::from(status.as_u16())));
                    }
                    return Err(classify_status(
                        source.id,
                        status,
                        retry_after,
                        self.sessions.is_configured(source.id),
                    ));
                }
                let content_type = response
                    .headers()
                    .get(reqwest::header::CONTENT_TYPE)
                    .and_then(|value| value.to_str().ok())
                    .unwrap_or_default()
                    .to_ascii_lowercase();
                if content_type.contains("text/html") {
                    return Err(BooruErrorDto::new(
                        BooruErrorCode::ChallengeRequired,
                        Some(source.id),
                        "booru.error.challengeRequired",
                    )
                    .with_http_status(u32::from(status.as_u16())));
                }
                return Ok(response);
            }
            if route_mode_active && self.config.fallback_to_system_dns {
                force_system_dns = true;
                continue;
            }
            return Err(BooruErrorDto::new(
                BooruErrorCode::Network,
                Some(source.id),
                "booru.error.network",
            ));
        }
    }

    pub fn prepared_headers(
        &self,
        source: &SourceDefinition,
        url: &Url,
    ) -> BooruResult<Vec<HttpHeaderDto>> {
        validate_url(source, url)?;
        let headers = self.request_headers(source, url, &[], false)?;
        Ok(headers
            .iter()
            .filter_map(|(name, value)| {
                value.to_str().ok().map(|value| HttpHeaderDto {
                    name: name.as_str().to_owned(),
                    value: value.to_owned(),
                })
            })
            .collect())
    }

    pub fn route_revision(&self) -> String {
        self.route_cache.revision()
    }

    pub fn auth_state(&self, source_id: &str) -> BooruResult<AuthStateDto> {
        self.sessions.state(source_id)
    }

    pub fn mark_auth_verified(&self, source_id: &str) -> BooruResult<AuthStateDto> {
        self.sessions.mark_verified(source_id)
    }

    pub fn mark_auth_rejected(&self, source_id: &str) -> BooruResult<AuthStateDto> {
        self.sessions.mark_rejected(source_id)
    }

    pub fn invalidate_source(&self, source_id: &str) -> BooruResult<()> {
        self.clients
            .lock()
            .map_err(|_| internal_error(source_id))?
            .retain(|key, _| !key.starts_with(&format!("{source_id}:")));
        Ok(())
    }

    pub fn invalidate_all_clients(&self) -> BooruResult<()> {
        self.clients
            .lock()
            .map_err(|_| internal_error("network"))?
            .clear();
        Ok(())
    }

    fn request_headers(
        &self,
        source: &SourceDefinition,
        url: &Url,
        requested: &[(String, String)],
        allow_protected_headers: bool,
    ) -> BooruResult<HeaderMap> {
        let mut headers = HeaderMap::new();
        headers.insert(
            USER_AGENT,
            HeaderValue::from_str(match source.family {
                ProtocolFamily::AnimePictures => BROWSER_USER_AGENT,
                _ => &self.config.user_agent,
            })
            .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?,
        );
        headers.insert(REFERER, HeaderValue::from_static(source.referer));
        headers.insert(ACCEPT, HeaderValue::from_static("*/*"));
        if source.family == ProtocolFamily::AnimePictures {
            headers.insert(COOKIE, HeaderValue::from_static("sitelang=en"));
        }
        for (name, value) in requested {
            let name = HeaderName::from_bytes(name.as_bytes())
                .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?;
            if is_protected_header(&name) && !allow_protected_headers {
                return Err(BooruErrorDto::invalid_request(Some(source.id)));
            }
            headers.insert(
                name,
                HeaderValue::from_str(value)
                    .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?,
            );
        }
        let api_host = Url::parse(source.api_base)
            .ok()
            .and_then(|url| url.host_str().map(str::to_owned));
        let allow_api_credentials = url.host_str() == api_host.as_deref();
        let mut auth_url = url.clone();
        self.sessions.apply(
            source.id,
            source.capabilities.auth_kind,
            &mut auth_url,
            &mut headers,
            allow_api_credentials,
        )?;
        // Query credentials are applied by `authenticated_url`; headers are complete here.
        Ok(headers)
    }

    fn authenticated_url(&self, source: &SourceDefinition, url: &Url) -> BooruResult<Url> {
        let mut url = url.clone();
        let mut ignored_headers = HeaderMap::new();
        let api_host = Url::parse(source.api_base)
            .ok()
            .and_then(|url| url.host_str().map(str::to_owned));
        let allow_api_credentials = url.host_str() == api_host.as_deref();
        self.sessions.apply(
            source.id,
            source.capabilities.auth_kind,
            &mut url,
            &mut ignored_headers,
            allow_api_credentials,
        )?;
        Ok(url)
    }

    fn client(&self, source: &SourceDefinition, force_system_dns: bool) -> BooruResult<Client> {
        let route_revision = self.route_cache.revision();
        let key = format!(
            "{}:{}:{}:{:?}:{}:{}",
            source.id,
            self.sessions.revision(source.id),
            self.config.proxy_url.as_deref().unwrap_or_default(),
            self.config.fallback_mode,
            route_revision,
            force_system_dns
        );
        if let Some(client) = self
            .clients
            .lock()
            .map_err(|_| internal_error(source.id))?
            .get(&key)
            .cloned()
        {
            return Ok(client);
        }
        let mut builder = super::tls::client_builder()
            .https_only(true)
            .redirect(reqwest::redirect::Policy::none())
            .connect_timeout(Duration::from_secs(30))
            .read_timeout(Duration::from_secs(120));
        if uses_insecure_tls(
            self.config.fallback_mode,
            force_system_dns,
            self.config.proxy_url.is_some(),
        ) {
            builder = builder.danger_accept_invalid_certs(true);
        }
        if let Some(proxy) = self.config.proxy_url.as_deref() {
            builder = builder.proxy(
                reqwest::Proxy::all(proxy)
                    .map_err(|_| BooruErrorDto::invalid_request(Some(source.id)))?,
            );
        } else if !force_system_dns
            && self.config.fallback_mode == NetworkFallbackMode::PersistedIpOverride
        {
            for host in source.allowed_hosts {
                let addrs = self
                    .route_cache
                    .candidates(host)
                    .into_iter()
                    .map(|ip| SocketAddr::new(ip, 443))
                    .collect::<Vec<_>>();
                if !addrs.is_empty() {
                    builder = builder.resolve_to_addrs(host, &addrs);
                }
            }
        } else if !force_system_dns && self.config.fallback_mode == NetworkFallbackMode::LegacyIpUrl
        {
            builder = builder.tls_sni(false);
        }
        let client = builder.build().map_err(|_| internal_error(source.id))?;
        self.clients
            .lock()
            .map_err(|_| internal_error(source.id))?
            .insert(key, client.clone());
        Ok(client)
    }

    fn route_mode_active(&self) -> bool {
        self.config.proxy_url.is_none() && self.config.fallback_mode != NetworkFallbackMode::Off
    }
}

fn validate_url(source: &SourceDefinition, url: &Url) -> BooruResult<String> {
    if url.scheme() != "https"
        || url.port_or_known_default() != Some(443)
        || !url.username().is_empty()
        || url.password().is_some()
    {
        return Err(BooruErrorDto::new(
            BooruErrorCode::InvalidRequest,
            Some(source.id),
            "booru.error.httpsRequired",
        ));
    }
    let host = url
        .host_str()
        .ok_or_else(|| BooruErrorDto::invalid_request(Some(source.id)))?;
    if !source.allows_host(host) {
        return Err(BooruErrorDto::new(
            BooruErrorCode::UnsafeRedirect,
            Some(source.id),
            "booru.error.unsafeHost",
        ));
    }
    Ok(host.to_owned())
}

fn is_protected_header(name: &HeaderName) -> bool {
    name == HOST
        || name == AUTHORIZATION
        || name == COOKIE
        || name.as_str().eq_ignore_ascii_case("x-api-key")
}

fn strip_redirect_sensitive_headers(spec: &mut RequestSpec) {
    spec.headers.retain(|(name, _)| {
        HeaderName::from_bytes(name.as_bytes())
            .ok()
            .is_none_or(|name| !is_protected_header(&name))
    });
    spec.allow_protected_headers = false;
}

fn url_authority(url: &Url) -> String {
    match url.port() {
        Some(port) => format!("{}:{port}", url.host_str().unwrap_or_default()),
        None => url.host_str().unwrap_or_default().to_owned(),
    }
}

fn retry_after_seconds(headers: &HeaderMap) -> Option<u32> {
    headers
        .get(RETRY_AFTER)
        .and_then(|value| value.to_str().ok())
        .and_then(|value| {
            value.parse::<u32>().ok().or_else(|| {
                let date = time::OffsetDateTime::parse(
                    value,
                    &time::format_description::well_known::Rfc2822,
                )
                .ok()?;
                u32::try_from(
                    (date - time::OffsetDateTime::now_utc())
                        .whole_seconds()
                        .max(0),
                )
                .ok()
            })
        })
}

fn retry_delay(attempt: u32, retry_after: Option<u32>) -> Duration {
    if let Some(seconds) = retry_after {
        return Duration::from_secs(u64::from(seconds.min(30)));
    }
    Duration::from_millis(250 * u64::from(1_u32 << attempt.saturating_sub(1)))
}

fn classify_reqwest_error(source_id: &str, error: &reqwest::Error) -> BooruErrorDto {
    if error.is_timeout() {
        BooruErrorDto::new(
            BooruErrorCode::Timeout,
            Some(source_id),
            "booru.error.timeout",
        )
    } else {
        BooruErrorDto::new(
            BooruErrorCode::Network,
            Some(source_id),
            "booru.error.network",
        )
    }
}

fn classify_status(
    source_id: &str,
    status: StatusCode,
    retry_after: Option<u32>,
    authenticated: bool,
) -> BooruErrorDto {
    let code = match status.as_u16() {
        401 => {
            if authenticated {
                BooruErrorCode::AuthenticationRejected
            } else {
                BooruErrorCode::AuthenticationRequired
            }
        }
        403 => BooruErrorCode::PermissionDenied,
        429 => BooruErrorCode::RateLimited,
        500..=599 => BooruErrorCode::SourceUnavailable,
        _ => BooruErrorCode::InvalidResponse,
    };
    let key = match code {
        BooruErrorCode::AuthenticationRejected => "booru.error.authenticationRejected",
        BooruErrorCode::AuthenticationRequired => "booru.error.authenticationRequired",
        BooruErrorCode::PermissionDenied => "booru.error.permissionDenied",
        BooruErrorCode::RateLimited => "booru.error.rateLimited",
        BooruErrorCode::SourceUnavailable => "booru.error.sourceUnavailable",
        _ => "booru.error.invalidResponse",
    };
    BooruErrorDto::new(code, Some(source_id), key)
        .with_http_status(u32::from(status.as_u16()))
        .with_retry_after(retry_after)
}

fn internal_error(source_id: &str) -> BooruErrorDto {
    BooruErrorDto::new(
        BooruErrorCode::Internal,
        Some(source_id),
        "booru.error.internal",
    )
}

fn missing_route(source_id: &str) -> BooruErrorDto {
    BooruErrorDto::new(
        BooruErrorCode::SourceUnavailable,
        Some(source_id),
        "booru.error.routeUnavailable",
    )
}

fn uses_insecure_tls(
    fallback_mode: NetworkFallbackMode,
    force_system_dns: bool,
    proxy_enabled: bool,
) -> bool {
    !force_system_dns && !proxy_enabled && fallback_mode != NetworkFallbackMode::Off
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::booru_models::{BooruEngineConfigDto, NetworkFallbackMode};
    use crate::booru::source::builtin_sources;

    #[test]
    fn retry_after_is_bounded() {
        assert_eq!(retry_delay(1, Some(500)), Duration::from_secs(30));
        assert_eq!(retry_delay(2, None), Duration::from_millis(500));
    }

    #[test]
    fn retry_after_supports_seconds_and_http_dates() {
        let mut headers = HeaderMap::new();
        headers.insert(RETRY_AFTER, HeaderValue::from_static("120"));
        assert_eq!(retry_after_seconds(&headers), Some(120));
        let future = time::OffsetDateTime::now_utc() + time::Duration::minutes(2);
        let date = future
            .format(&time::format_description::well_known::Rfc2822)
            .unwrap();
        headers.insert(RETRY_AFTER, HeaderValue::from_str(&date).unwrap());
        assert!(matches!(retry_after_seconds(&headers), Some(118..=120)));
        headers.insert(RETRY_AFTER, HeaderValue::from_static("invalid"));
        assert_eq!(retry_after_seconds(&headers), None);
    }

    #[tokio::test]
    async fn source_cooldown_rejects_queued_requests_before_network() {
        let sources = builtin_sources();
        let directory = tempfile::tempdir().unwrap();
        let runtime = NetworkRuntime::new(
            BooruEngineConfigDto {
                app_support_directory: directory.path().to_string_lossy().to_string(),
                proxy_url: None,
                fallback_mode: NetworkFallbackMode::Off,
                fallback_to_system_dns: true,
                user_agent: "test".into(),
            },
            &sources,
            Arc::new(SessionStore::default()),
        )
        .unwrap();
        runtime.defer_source("yande", 120);
        let source = sources.iter().find(|source| source.id == "yande").unwrap();
        let error = runtime
            .execute(
                source,
                RequestSpec::get(
                    Url::parse("https://yande.re/post.json").unwrap(),
                    ResponseKind::Json,
                ),
            )
            .await
            .unwrap_err();
        assert_eq!(error.code, BooruErrorCode::RateLimited);
        assert!(runtime.check_cooldown("danbooru").is_ok());
        runtime.defer_source("yande", 0);
        assert!(runtime.check_cooldown("yande").is_ok());
    }

    #[test]
    fn rejects_cross_source_url() {
        let source = builtin_sources().remove(0);
        let error = validate_url(
            &source,
            &Url::parse("https://example.com/image.jpg").unwrap(),
        )
        .unwrap_err();
        assert_eq!(error.code, BooruErrorCode::UnsafeRedirect);
        assert!(validate_url(
            &source,
            &Url::parse("https://user:secret@yande.re/post.json").unwrap()
        )
        .is_err());
        assert!(validate_url(
            &source,
            &Url::parse("https://yande.re:8443/post.json").unwrap()
        )
        .is_err());
    }

    #[test]
    fn protected_headers_cannot_be_overridden() {
        let sources = builtin_sources();
        let source = &sources[0];
        let sessions = Arc::new(SessionStore::default());
        let directory = tempfile::tempdir().unwrap();
        let runtime = NetworkRuntime::new(
            BooruEngineConfigDto {
                app_support_directory: directory.path().to_string_lossy().to_string(),
                proxy_url: None,
                fallback_mode: NetworkFallbackMode::Off,
                fallback_to_system_dns: true,
                user_agent: "test".to_owned(),
            },
            &sources,
            sessions,
        )
        .unwrap();
        let result = runtime.request_headers(
            source,
            &Url::parse("https://yande.re/post.json").unwrap(),
            &[("Cookie".to_owned(), "marker".to_owned())],
            false,
        );
        assert!(result.is_err());
    }

    #[test]
    fn user_agent_policy_only_spoofs_sources_that_need_it() {
        let sources = builtin_sources();
        let directory = tempfile::tempdir().unwrap();
        let runtime = NetworkRuntime::new(
            BooruEngineConfigDto {
                app_support_directory: directory.path().to_string_lossy().to_string(),
                proxy_url: None,
                fallback_mode: NetworkFallbackMode::Off,
                fallback_to_system_dns: true,
                user_agent: "custom-client/2".to_owned(),
            },
            &sources,
            Arc::new(SessionStore::default()),
        )
        .unwrap();
        let yande = sources.iter().find(|source| source.id == "yande").unwrap();
        let yande_headers = runtime
            .request_headers(
                yande,
                &Url::parse("https://yande.re/post.json").unwrap(),
                &[],
                false,
            )
            .unwrap();
        assert_eq!(
            yande_headers.get(USER_AGENT).unwrap(),
            "BooruFlow/1.0 custom-client/2"
        );
        assert!(!yande_headers.contains_key(COOKIE));

        let anime = sources
            .iter()
            .find(|source| source.id == "anime_pictures")
            .unwrap();
        let anime_headers = runtime
            .request_headers(
                anime,
                &Url::parse("https://api.anime-pictures.net/api/v3/posts").unwrap(),
                &[],
                false,
            )
            .unwrap();
        assert_eq!(anime_headers.get(USER_AGENT).unwrap(), BROWSER_USER_AGENT);
        assert_eq!(anime_headers.get(COOKIE).unwrap(), "sitelang=en");
    }

    #[test]
    fn redirect_drops_caller_supplied_credentials() {
        let mut spec = RequestSpec::get(
            Url::parse("https://api.anime-pictures.net/pictures/download_image/1").unwrap(),
            ResponseKind::Media,
        );
        spec.headers = vec![
            ("Cookie".to_owned(), "temporary=secret".to_owned()),
            ("Accept".to_owned(), "image/*".to_owned()),
        ];
        spec.allow_protected_headers = true;
        strip_redirect_sensitive_headers(&mut spec);
        assert_eq!(spec.headers, [("Accept".to_owned(), "image/*".to_owned())]);
        assert!(!spec.allow_protected_headers);
    }

    #[tokio::test]
    async fn strict_persisted_route_mode_never_falls_back_implicitly() {
        let sources = builtin_sources();
        let source = &sources[0];
        let directory = tempfile::tempdir().unwrap();
        let runtime = NetworkRuntime::new(
            BooruEngineConfigDto {
                app_support_directory: directory.path().to_string_lossy().to_string(),
                proxy_url: None,
                fallback_mode: NetworkFallbackMode::PersistedIpOverride,
                fallback_to_system_dns: false,
                user_agent: "test".to_owned(),
            },
            &sources,
            Arc::new(SessionStore::default()),
        )
        .unwrap();
        let error = runtime
            .execute(
                source,
                RequestSpec::get(
                    Url::parse("https://yande.re/post.json").unwrap(),
                    ResponseKind::Json,
                ),
            )
            .await
            .unwrap_err();
        assert_eq!(error.code, BooruErrorCode::SourceUnavailable);
    }

    #[test]
    fn status_classification_distinguishes_missing_and_rejected_auth() {
        assert_eq!(
            classify_status("wallhaven", StatusCode::UNAUTHORIZED, None, false).code,
            BooruErrorCode::AuthenticationRequired
        );
        assert_eq!(
            classify_status("wallhaven", StatusCode::UNAUTHORIZED, None, true).code,
            BooruErrorCode::AuthenticationRejected
        );
        assert_eq!(
            classify_status("wallhaven", StatusCode::FORBIDDEN, None, true).code,
            BooruErrorCode::PermissionDenied
        );
    }

    #[test]
    fn insecure_tls_is_limited_to_active_direct_ip_fallback() {
        assert!(uses_insecure_tls(
            NetworkFallbackMode::PersistedIpOverride,
            false,
            false
        ));
        assert!(uses_insecure_tls(
            NetworkFallbackMode::LegacyIpUrl,
            false,
            false
        ));
        assert!(!uses_insecure_tls(
            NetworkFallbackMode::PersistedIpOverride,
            true,
            false
        ));
        assert!(!uses_insecure_tls(
            NetworkFallbackMode::PersistedIpOverride,
            false,
            true
        ));
    }
}
