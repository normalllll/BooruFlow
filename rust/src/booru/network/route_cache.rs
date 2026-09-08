use crate::api::booru_models::{PersistedHostRouteDto, RouteCacheStateDto, RouteProvider};
use crate::booru::error::{BooruErrorCode, BooruErrorDto, BooruResult};
use crate::booru::source::SourceDefinition;
use reqwest::header::{HeaderMap, HeaderValue, ACCEPT};
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;
use std::net::IpAddr;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::RwLock;
use std::time::{SystemTime, UNIX_EPOCH};

const SCHEMA_VERSION: u32 = 1;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PersistedRouteCache {
    schema_version: u32,
    route_revision: String,
    fetched_at_iso8601: String,
    provider: RouteProvider,
    routes: Vec<PersistedHostRoute>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PersistedHostRoute {
    logical_host: String,
    https_port: u16,
    candidates: Vec<String>,
}

#[derive(Debug)]
pub struct RouteCache {
    path: PathBuf,
    allowed_hosts: BTreeSet<String>,
    state: RwLock<Option<PersistedRouteCache>>,
    refreshing: AtomicBool,
    refresh_lock: tokio::sync::Mutex<()>,
    refresh_epoch: std::sync::atomic::AtomicU32,
    last_refresh_result: RwLock<Option<BooruResult<RouteCacheStateDto>>>,
}

impl RouteCache {
    pub fn new(app_support_directory: &str, sources: &[SourceDefinition]) -> Self {
        let allowed_hosts = sources
            .iter()
            .flat_map(|source| source.allowed_hosts.iter().copied())
            .map(str::to_owned)
            .collect();
        Self {
            path: PathBuf::from(app_support_directory)
                .join("network")
                .join("routes-v1.json"),
            allowed_hosts,
            state: RwLock::new(None),
            refreshing: AtomicBool::new(false),
            refresh_lock: tokio::sync::Mutex::new(()),
            refresh_epoch: std::sync::atomic::AtomicU32::new(0),
            last_refresh_result: RwLock::new(None),
        }
    }

    pub async fn initialize(&self) -> BooruResult<RouteCacheStateDto> {
        if let Ok(bytes) = tokio::fs::read(&self.path).await {
            if let Ok(cache) = serde_json::from_slice::<PersistedRouteCache>(&bytes) {
                if self.validate_cache_structure(&cache).is_ok() {
                    let complete = self.is_complete(&cache);
                    *self.state.write().map_err(|_| internal_error())? = Some(cache);
                    if complete {
                        return self.snapshot();
                    }
                }
            }
        }
        self.refresh().await
    }

    pub async fn refresh(&self) -> BooruResult<RouteCacheStateDto> {
        let epoch_before_wait = self.refresh_epoch.load(Ordering::Acquire);
        let _guard = self.refresh_lock.lock().await;
        if self.refresh_epoch.load(Ordering::Acquire) != epoch_before_wait {
            return self
                .last_refresh_result
                .read()
                .map_err(|_| internal_error())?
                .clone()
                .unwrap_or_else(|| Err(internal_error()));
        }
        self.refreshing.store(true, Ordering::Release);
        let result = self.fetch_and_store().await;
        self.refreshing.store(false, Ordering::Release);
        *self
            .last_refresh_result
            .write()
            .map_err(|_| internal_error())? = Some(result.clone());
        self.refresh_epoch.fetch_add(1, Ordering::AcqRel);
        result
    }

    pub fn snapshot(&self) -> BooruResult<RouteCacheStateDto> {
        let state = self.state.read().map_err(|_| internal_error())?;
        let Some(cache) = state.as_ref() else {
            return Ok(RouteCacheStateDto {
                initialized: false,
                refreshing: self.refreshing.load(Ordering::Acquire),
                route_revision: "0".to_owned(),
                fetched_at_iso8601: None,
                provider: None,
                routes: Vec::new(),
            });
        };
        Ok(RouteCacheStateDto {
            initialized: true,
            refreshing: self.refreshing.load(Ordering::Acquire),
            route_revision: cache.route_revision.clone(),
            fetched_at_iso8601: Some(cache.fetched_at_iso8601.clone()),
            provider: Some(cache.provider),
            routes: cache
                .routes
                .iter()
                .map(|route| PersistedHostRouteDto {
                    logical_host: route.logical_host.clone(),
                    https_port: route.https_port,
                    candidates: route.candidates.clone(),
                })
                .collect(),
        })
    }

    pub fn revision(&self) -> String {
        self.state
            .read()
            .ok()
            .and_then(|state| state.as_ref().map(|cache| cache.route_revision.clone()))
            .unwrap_or_else(|| "0".to_owned())
    }

    pub fn candidates(&self, host: &str) -> Vec<IpAddr> {
        self.state
            .read()
            .ok()
            .and_then(|state| state.clone())
            .and_then(|cache| {
                cache
                    .routes
                    .into_iter()
                    .find(|route| route.logical_host.eq_ignore_ascii_case(host))
            })
            .map(|route| {
                route
                    .candidates
                    .into_iter()
                    .filter_map(|value| value.parse().ok())
                    .collect()
            })
            .unwrap_or_default()
    }

    async fn fetch_and_store(&self) -> BooruResult<RouteCacheStateDto> {
        let client = super::tls::client_builder()
            .https_only(true)
            .connect_timeout(std::time::Duration::from_secs(10))
            .read_timeout(std::time::Duration::from_secs(15))
            .build()
            .map_err(|_| network_error())?;
        let old_routes = self
            .state
            .read()
            .map_err(|_| internal_error())?
            .as_ref()
            .map(|cache| cache.routes.clone())
            .unwrap_or_default();
        let mut routes = Vec::new();
        let mut updated_any = false;
        for host in &self.allowed_hosts {
            let mut candidates = BTreeSet::new();
            for record_type in ["A", "AAAA"] {
                let mut url = reqwest::Url::parse("https://cloudflare-dns.com/dns-query")
                    .map_err(|_| internal_error())?;
                url.query_pairs_mut()
                    .append_pair("name", host)
                    .append_pair("type", record_type);
                let mut headers = HeaderMap::new();
                headers.insert(ACCEPT, HeaderValue::from_static("application/dns-json"));
                let response = client.get(url).headers(headers).send().await;
                let Ok(response) = response else {
                    continue;
                };
                if !response.status().is_success() {
                    continue;
                }
                let Ok(json) = response.json::<serde_json::Value>().await else {
                    continue;
                };
                if let Some(answers) = json.get("Answer").and_then(|value| value.as_array()) {
                    for answer in answers {
                        if let Some(ip) = answer
                            .get("data")
                            .and_then(|value| value.as_str())
                            .and_then(|value| value.parse::<IpAddr>().ok())
                            .filter(|ip| is_public_ip(*ip))
                        {
                            candidates.insert(ip.to_string());
                        }
                    }
                }
            }
            let candidates = if candidates.is_empty() {
                old_routes
                    .iter()
                    .find(|route| route.logical_host == *host)
                    .map(|route| route.candidates.clone())
                    .unwrap_or_default()
            } else {
                updated_any = true;
                candidates.into_iter().take(8).collect()
            };
            if !candidates.is_empty() {
                routes.push(PersistedHostRoute {
                    logical_host: host.clone(),
                    https_port: 443,
                    candidates,
                });
            }
        }
        if !updated_any {
            return Err(network_error());
        }
        let previous_revision = self.revision();
        let cache = PersistedRouteCache {
            schema_version: SCHEMA_VERSION,
            route_revision: next_revision(&previous_revision),
            fetched_at_iso8601: now_iso8601(),
            provider: RouteProvider::CloudflareDnsJson,
            routes,
        };
        self.validate_cache_structure(&cache)?;
        if !self.is_complete(&cache) {
            return Err(network_error());
        }
        write_cache(&self.path, &cache).await?;
        *self.state.write().map_err(|_| internal_error())? = Some(cache);
        self.snapshot()
    }

    fn validate_cache_structure(&self, cache: &PersistedRouteCache) -> BooruResult<()> {
        if cache.schema_version != SCHEMA_VERSION
            || cache.routes.is_empty()
            || cache.route_revision.is_empty()
            || time::OffsetDateTime::parse(
                &cache.fetched_at_iso8601,
                &time::format_description::well_known::Rfc3339,
            )
            .is_err()
        {
            return Err(BooruErrorDto::new(
                BooruErrorCode::InvalidResponse,
                None,
                "booru.error.invalidRouteCache",
            ));
        }
        let mut seen = BTreeSet::new();
        for route in &cache.routes {
            if !self.allowed_hosts.contains(&route.logical_host)
                || route.https_port != 443
                || route.candidates.is_empty()
                || route.candidates.len() > 8
                || !seen.insert(&route.logical_host)
            {
                return Err(BooruErrorDto::new(
                    BooruErrorCode::InvalidResponse,
                    None,
                    "booru.error.invalidRouteCache",
                ));
            }
            for candidate in &route.candidates {
                let ip = candidate.parse::<IpAddr>().map_err(|_| {
                    BooruErrorDto::new(
                        BooruErrorCode::InvalidResponse,
                        None,
                        "booru.error.invalidRouteCache",
                    )
                })?;
                if !is_public_ip(ip) {
                    return Err(BooruErrorDto::new(
                        BooruErrorCode::InvalidResponse,
                        None,
                        "booru.error.invalidRouteCache",
                    ));
                }
            }
        }
        Ok(())
    }

    fn is_complete(&self, cache: &PersistedRouteCache) -> bool {
        let cached_hosts = cache
            .routes
            .iter()
            .map(|route| route.logical_host.as_str())
            .collect::<BTreeSet<_>>();
        self.allowed_hosts
            .iter()
            .all(|host| cached_hosts.contains(host.as_str()))
    }
}

async fn write_cache(path: &Path, cache: &PersistedRouteCache) -> BooruResult<()> {
    let parent = path.parent().ok_or_else(internal_error)?;
    tokio::fs::create_dir_all(parent)
        .await
        .map_err(|_| internal_error())?;
    let bytes = serde_json::to_vec_pretty(cache).map_err(|_| internal_error())?;
    let temporary = path.with_extension("json.tmp");
    let backup = path.with_extension("json.bak");
    let mut file = tokio::fs::File::create(&temporary)
        .await
        .map_err(|_| internal_error())?;
    use tokio::io::AsyncWriteExt;
    file.write_all(&bytes).await.map_err(|_| internal_error())?;
    file.flush().await.map_err(|_| internal_error())?;
    file.sync_all().await.map_err(|_| internal_error())?;
    drop(file);
    if tokio::fs::try_exists(path).await.unwrap_or(false) {
        let _ = tokio::fs::remove_file(&backup).await;
        tokio::fs::rename(path, &backup)
            .await
            .map_err(|_| internal_error())?;
    }
    if tokio::fs::rename(&temporary, path).await.is_err() {
        let _ = tokio::fs::rename(&backup, path).await;
        return Err(BooruErrorDto::new(
            BooruErrorCode::Internal,
            None,
            "booru.error.routeCacheWrite",
        ));
    }
    let _ = tokio::fs::remove_file(backup).await;
    Ok(())
}

fn is_public_ip(ip: IpAddr) -> bool {
    match ip {
        IpAddr::V4(ip) => {
            let [first, second, third, _] = ip.octets();
            !(ip.is_private()
                || ip.is_loopback()
                || ip.is_link_local()
                || ip.is_unspecified()
                || ip.is_multicast()
                || ip.is_broadcast()
                || ip.is_documentation()
                || first == 0
                || (first == 100 && (64..=127).contains(&second))
                || (first == 192 && second == 0 && third == 0)
                || (first == 198 && (18..=19).contains(&second))
                || first >= 240)
        }
        IpAddr::V6(ip) => {
            if let Some(ipv4) = ip.to_ipv4_mapped() {
                return is_public_ip(IpAddr::V4(ipv4));
            }
            let segments = ip.segments();
            !(ip.is_loopback()
                || ip.is_unspecified()
                || ip.is_multicast()
                || ip.is_unique_local()
                || ip.is_unicast_link_local()
                || (segments[0] == 0x2001 && segments[1] == 0x0db8)
                || (segments[0] & 0xffc0) == 0xfec0)
        }
    }
}

fn next_revision(previous: &str) -> String {
    let clock = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    let previous = previous.parse::<u128>().unwrap_or_default();
    clock.max(previous.saturating_add(1)).to_string()
}

fn unix_seconds() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn now_iso8601() -> String {
    time::OffsetDateTime::now_utc()
        .format(&time::format_description::well_known::Rfc3339)
        .unwrap_or_else(|_| unix_seconds().to_string())
}

fn internal_error() -> BooruErrorDto {
    BooruErrorDto::new(BooruErrorCode::Internal, None, "booru.error.internal")
}

fn network_error() -> BooruErrorDto {
    BooruErrorDto::new(
        BooruErrorCode::Network,
        None,
        "booru.error.routeRefreshFailed",
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::booru::source::builtin_sources;

    #[test]
    fn rejects_local_network_addresses() {
        for value in [
            "127.0.0.1",
            "10.0.0.1",
            "100.64.0.1",
            "192.168.1.1",
            "198.18.0.1",
            "240.0.0.1",
            "::1",
            "fe80::1",
            "2001:db8::1",
        ] {
            assert!(!is_public_ip(value.parse().unwrap()), "{value}");
        }
        assert!(is_public_ip("1.1.1.1".parse().unwrap()));
        assert!(is_public_ip("2606:4700:4700::1111".parse().unwrap()));
    }

    #[test]
    fn rejects_hosts_outside_builtin_allowlist() {
        let directory = tempfile::tempdir().unwrap();
        let cache = RouteCache::new(directory.path().to_str().unwrap(), &builtin_sources());
        let persisted = PersistedRouteCache {
            schema_version: 1,
            route_revision: "1".to_owned(),
            fetched_at_iso8601: "2026-01-01T00:00:00Z".to_owned(),
            provider: RouteProvider::CloudflareDnsJson,
            routes: vec![PersistedHostRoute {
                logical_host: "localhost".to_owned(),
                https_port: 443,
                candidates: vec!["1.1.1.1".to_owned()],
            }],
        };
        assert!(cache.validate_cache_structure(&persisted).is_err());
    }

    #[test]
    fn valid_but_incomplete_cache_requires_initialization() {
        let directory = tempfile::tempdir().unwrap();
        let cache = RouteCache::new(directory.path().to_str().unwrap(), &builtin_sources());
        let persisted = PersistedRouteCache {
            schema_version: SCHEMA_VERSION,
            route_revision: "1".to_owned(),
            fetched_at_iso8601: "2026-01-01T00:00:00Z".to_owned(),
            provider: RouteProvider::CloudflareDnsJson,
            routes: vec![PersistedHostRoute {
                logical_host: "yande.re".to_owned(),
                https_port: 443,
                candidates: vec!["1.1.1.1".to_owned()],
            }],
        };
        cache.validate_cache_structure(&persisted).unwrap();
        assert!(!cache.is_complete(&persisted));
    }

    #[test]
    fn revision_is_monotonic_even_within_one_clock_tick() {
        let first = next_revision("999999999999999999999999999999");
        assert_eq!(first, "1000000000000000000000000000000");
    }

    #[tokio::test]
    async fn complete_cache_is_loaded_without_provider_access() {
        let directory = tempfile::tempdir().unwrap();
        let sources = builtin_sources();
        let cache = RouteCache::new(directory.path().to_str().unwrap(), &sources);
        let routes = cache
            .allowed_hosts
            .iter()
            .map(|host| PersistedHostRoute {
                logical_host: host.clone(),
                https_port: 443,
                candidates: vec!["1.1.1.1".to_owned()],
            })
            .collect();
        let persisted = PersistedRouteCache {
            schema_version: SCHEMA_VERSION,
            route_revision: "42".to_owned(),
            fetched_at_iso8601: "2026-01-01T00:00:00Z".to_owned(),
            provider: RouteProvider::CloudflareDnsJson,
            routes,
        };
        write_cache(&cache.path, &persisted).await.unwrap();

        let reloaded = RouteCache::new(directory.path().to_str().unwrap(), &sources);
        let state = reloaded.initialize().await.unwrap();
        assert!(state.initialized);
        assert_eq!(state.route_revision, "42");
        assert_eq!(state.routes.len(), reloaded.allowed_hosts.len());
    }

    #[test]
    fn cache_rejects_invalid_timestamp() {
        let directory = tempfile::tempdir().unwrap();
        let cache = RouteCache::new(directory.path().to_str().unwrap(), &builtin_sources());
        let persisted = PersistedRouteCache {
            schema_version: SCHEMA_VERSION,
            route_revision: "1".to_owned(),
            fetched_at_iso8601: "not-a-time".to_owned(),
            provider: RouteProvider::CloudflareDnsJson,
            routes: vec![PersistedHostRoute {
                logical_host: "yande.re".to_owned(),
                https_port: 443,
                candidates: vec!["1.1.1.1".to_owned()],
            }],
        };
        assert!(cache.validate_cache_structure(&persisted).is_err());
    }
}
