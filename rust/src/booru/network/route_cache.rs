use crate::api::booru_models::{
    PersistedHostRoute as ApiPersistedHostRoute, RouteCacheState, RouteDiagnostic, RouteProvider,
};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use crate::booru::source::SourceDefinition;
use futures_util::{stream, StreamExt};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};
use std::net::IpAddr;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::RwLock;
use std::time::{Instant, SystemTime, UNIX_EPOCH};

const SCHEMA_VERSION: u32 = 2;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PersistedRouteCache {
    schema_version: u32,
    route_revision: String,
    fetched_at_iso8601: String,
    provider: RouteProvider,
    routes: Vec<StoredHostRoute>,
    diagnostics: Vec<RouteDiagnostic>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredHostRoute {
    logical_host: String,
    https_port: u16,
    candidates: Vec<String>,
}

#[derive(Debug)]
pub struct RouteCache {
    path: PathBuf,
    provider: RouteProvider,
    sources: Vec<SourceDefinition>,
    diagnostics: RwLock<BTreeMap<String, RouteDiagnostic>>,
    state: RwLock<Option<PersistedRouteCache>>,
    refreshing: AtomicBool,
    refresh_lock: tokio::sync::Mutex<()>,
}

impl RouteCache {
    #[cfg(test)]
    pub fn new(directory: &str, sources: &[SourceDefinition]) -> Self {
        Self::with_provider(directory, sources, RouteProvider::UncensoredDns)
    }

    pub fn with_provider(
        directory: &str,
        sources: &[SourceDefinition],
        provider: RouteProvider,
    ) -> Self {
        let mut cache = Self {
            path: PathBuf::from(directory)
                .join("network")
                .join(format!("routes-v2-{provider:?}.json")),
            provider,
            sources: sources.to_vec(),
            diagnostics: RwLock::new(BTreeMap::new()),
            state: RwLock::new(None),
            refreshing: AtomicBool::new(false),
            refresh_lock: tokio::sync::Mutex::new(()),
        };
        let hosts: BTreeSet<_> = sources
            .iter()
            .flat_map(|s| s.allowed_hosts.iter().copied())
            .collect();
        let reports = hosts
            .into_iter()
            .map(|host| (host.to_owned(), cache.pending(host)))
            .collect();
        *cache.diagnostics.get_mut().unwrap() = reports;
        cache
    }

    fn pending(&self, host: &str) -> RouteDiagnostic {
        RouteDiagnostic {
            source_ids: self
                .sources
                .iter()
                .filter(|s| s.allows_host(host))
                .map(|s| s.id.to_owned())
                .collect(),
            logical_host: host.to_owned(),
            status: "pending".into(),
            candidates: Vec::new(),
            error: None,
            elapsed_ms: None,
            updated_at_iso8601: None,
        }
    }

    /// Only read saved state. Startup never performs an invisible DNS refresh.
    pub async fn initialize(&self) -> BooruResult<RouteCacheState> {
        if let Ok(bytes) = tokio::fs::read(&self.path).await {
            if let Ok(cache) = serde_json::from_slice::<PersistedRouteCache>(&bytes) {
                if self.validate_cache_structure(&cache).is_ok() {
                    let mut reports = self.diagnostics.write().map_err(|_| internal_error())?;
                    for mut report in cache.diagnostics.clone() {
                        if report.status == "resolved" {
                            report.status = "cached".into();
                        }
                        reports.insert(report.logical_host.clone(), report);
                    }
                    *self.state.write().map_err(|_| internal_error())? = Some(cache);
                }
            }
        }
        self.snapshot()
    }

    pub async fn refresh(&self) -> BooruResult<RouteCacheState> {
        let _guard = self.refresh_lock.lock().await;
        self.refreshing.store(true, Ordering::Release);
        let result = self.fetch_and_store().await;
        self.refreshing.store(false, Ordering::Release);
        result?;
        self.snapshot()
    }

    pub fn snapshot(&self) -> BooruResult<RouteCacheState> {
        let diagnostics = self
            .diagnostics
            .read()
            .map_err(|_| internal_error())?
            .values()
            .cloned()
            .collect();
        let state = self.state.read().map_err(|_| internal_error())?;
        Ok(RouteCacheState {
            initialized: state.is_some(),
            refreshing: self.refreshing.load(Ordering::Acquire),
            route_revision: state
                .as_ref()
                .map(|s| s.route_revision.clone())
                .unwrap_or_else(|| "0".into()),
            fetched_at_iso8601: state.as_ref().map(|s| s.fetched_at_iso8601.clone()),
            provider: Some(self.provider),
            routes: state
                .as_ref()
                .map(|s| {
                    s.routes
                        .iter()
                        .map(|r| ApiPersistedHostRoute {
                            logical_host: r.logical_host.clone(),
                            https_port: r.https_port,
                            candidates: r.candidates.clone(),
                        })
                        .collect()
                })
                .unwrap_or_default(),
            diagnostics,
        })
    }

    pub fn revision(&self) -> String {
        self.state
            .read()
            .ok()
            .and_then(|s| s.as_ref().map(|s| s.route_revision.clone()))
            .unwrap_or_else(|| "0".into())
    }

    pub fn candidates(&self, host: &str) -> Vec<IpAddr> {
        self.state
            .read()
            .ok()
            .and_then(|s| {
                s.as_ref().and_then(|s| {
                    s.routes
                        .iter()
                        .find(|r| r.logical_host.eq_ignore_ascii_case(host))
                        .cloned()
                })
            })
            .map(|r| r.candidates.iter().filter_map(|s| s.parse().ok()).collect())
            .unwrap_or_default()
    }

    /// Newly discovered CDN hosts become visible pending entries. Only the
    /// explicit refresh action acquires addresses; requests never resolve silently.
    pub async fn ensure_candidates(
        &self,
        source: &SourceDefinition,
        host: &str,
    ) -> BooruResult<Vec<IpAddr>> {
        let host = host.trim_end_matches('.').to_ascii_lowercase();
        if !source.allows_host(&host) || !self.host_is_allowed(&host) {
            return Err(BooruError::invalid_request(Some(source.id)));
        }
        self.diagnostics
            .write()
            .map_err(|_| internal_error())?
            .entry(host.clone())
            .or_insert_with(|| self.pending(&host));
        let candidates = self.candidates(&host);
        if candidates.is_empty() {
            return Err(network_error());
        }
        Ok(candidates)
    }

    fn host_is_allowed(&self, host: &str) -> bool {
        self.sources.iter().any(|s| s.allows_host(host))
    }

    async fn fetch_and_store(&self) -> BooruResult<()> {
        self.fetch_with(|host| async move { super::doh::resolve(self.provider, &host).await })
            .await
    }

    async fn fetch_with<F, Fut>(&self, resolve: F) -> BooruResult<()>
    where
        F: Fn(String) -> Fut + Copy,
        Fut: std::future::Future<Output = Result<Vec<String>, String>>,
    {
        let hosts: Vec<_> = self
            .diagnostics
            .read()
            .map_err(|_| internal_error())?
            .keys()
            .cloned()
            .collect();
        {
            let mut reports = self.diagnostics.write().map_err(|_| internal_error())?;
            for host in &hosts {
                reports.insert(host.clone(), self.pending(host));
            }
        }
        let mut cache = PersistedRouteCache {
            schema_version: SCHEMA_VERSION,
            route_revision: next_revision(&self.revision()),
            fetched_at_iso8601: now_iso8601(),
            provider: self.provider,
            routes: Vec::new(),
            diagnostics: Vec::new(),
        };
        // Clear and persist first: failures cannot reuse old IPs after a restart.
        *self.state.write().map_err(|_| internal_error())? = Some(cache.clone());
        write_cache(&self.path, &cache).await?;
        let results: Vec<_> = stream::iter(hosts.into_iter().map(|host| async move {
            let mut report = self.pending(&host);
            report.status = "resolving".into();
            if let Ok(mut reports) = self.diagnostics.write() {
                reports.insert(host.clone(), report.clone());
            }
            let start = Instant::now();
            match resolve(host.clone()).await {
                Ok(ips) => {
                    report.status = "resolved".into();
                    report.candidates = ips;
                    report.updated_at_iso8601 = Some(now_iso8601());
                }
                Err(error) => {
                    report.status = "failed".into();
                    report.error = Some(error);
                }
            }
            report.elapsed_ms = Some(start.elapsed().as_millis().min(u128::from(u32::MAX)) as u32);
            if let Ok(mut reports) = self.diagnostics.write() {
                reports.insert(host, report.clone());
            }
            report
        }))
        .buffer_unordered(6)
        .collect()
        .await;
        cache.routes = results
            .iter()
            .filter(|r| r.status == "resolved")
            .map(|r| StoredHostRoute {
                logical_host: r.logical_host.clone(),
                https_port: 443,
                candidates: r.candidates.clone(),
            })
            .collect();
        cache.diagnostics = results;
        cache.fetched_at_iso8601 = now_iso8601();
        self.validate_cache_structure(&cache)?;
        if let Err(error) = write_cache(&self.path, &cache).await {
            let mut reports = self.diagnostics.write().map_err(|_| internal_error())?;
            for report in reports.values_mut().filter(|r| r.status == "resolved") {
                report.status = "failed".into();
                report.error = Some("Unable to save IP cache".into());
                report.updated_at_iso8601 = None;
            }
            return Err(error);
        }
        *self.state.write().map_err(|_| internal_error())? = Some(cache);
        Ok(())
    }

    fn validate_cache_structure(&self, cache: &PersistedRouteCache) -> BooruResult<()> {
        if cache.schema_version != SCHEMA_VERSION
            || cache.provider != self.provider
            || cache.route_revision.is_empty()
            || time::OffsetDateTime::parse(
                &cache.fetched_at_iso8601,
                &time::format_description::well_known::Rfc3339,
            )
            .is_err()
        {
            return Err(internal_error());
        }
        let mut seen = BTreeSet::new();
        for route in &cache.routes {
            if !self.host_is_allowed(&route.logical_host)
                || route.https_port != 443
                || route.candidates.is_empty()
                || route.candidates.len() > 8
                || !seen.insert(&route.logical_host)
                || route
                    .candidates
                    .iter()
                    .any(|ip| ip.parse::<IpAddr>().map_or(true, |ip| !is_public_ip(ip)))
            {
                return Err(internal_error());
            }
        }
        for report in &cache.diagnostics {
            if !self.host_is_allowed(&report.logical_host) {
                return Err(internal_error());
            }
        }
        Ok(())
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
        return Err(BooruError::new(
            BooruErrorCode::Internal,
            None,
            "booru.error.routeCacheWrite",
        ));
    }
    let _ = tokio::fs::remove_file(backup).await;
    Ok(())
}

pub(super) fn is_public_ip(ip: IpAddr) -> bool {
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

fn internal_error() -> BooruError {
    BooruError::new(BooruErrorCode::Internal, None, "booru.error.internal")
}

fn network_error() -> BooruError {
    BooruError::new(
        BooruErrorCode::Network,
        None,
        "booru.error.routeRefreshFailed",
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::booru::source::builtin_sources;

    #[tokio::test]
    async fn startup_and_new_cdn_hosts_never_query_dns() {
        let directory = tempfile::tempdir().unwrap();
        let sources = builtin_sources();
        let cache = RouteCache::new(directory.path().to_str().unwrap(), &sources);
        let state = cache.initialize().await.unwrap();
        assert!(!state.initialized);
        assert_eq!(
            state
                .diagnostics
                .iter()
                .flat_map(|r| r.source_ids.iter())
                .collect::<BTreeSet<_>>()
                .len(),
            7
        );
        let gel = sources.iter().find(|s| s.id == "gelbooru").unwrap();
        assert!(cache
            .ensure_candidates(gel, "img4.gelbooru.com")
            .await
            .is_err());
        assert!(cache
            .snapshot()
            .unwrap()
            .diagnostics
            .iter()
            .any(|r| r.logical_host == "img4.gelbooru.com" && r.status == "pending"));
        assert!(cache
            .ensure_candidates(gel, "gelbooru.com.evil.test")
            .await
            .is_err());
        assert!(!cache.path.exists());
    }

    #[tokio::test]
    async fn cache_keeps_timestamps_isolates_providers_and_removes_failed_routes() {
        let directory = tempfile::tempdir().unwrap();
        let sources = builtin_sources();
        let cache = RouteCache::new(directory.path().to_str().unwrap(), &sources);
        cache
            .fetch_with(|_| async { Ok(vec!["8.8.8.8".into()]) })
            .await
            .unwrap();
        let stamp = cache.snapshot().unwrap().diagnostics[0]
            .updated_at_iso8601
            .clone();
        assert!(stamp.is_some());
        let reloaded = RouteCache::new(directory.path().to_str().unwrap(), &sources);
        let state = reloaded.initialize().await.unwrap();
        assert!(state.diagnostics.iter().all(|r| r.status == "cached"));
        assert_eq!(state.diagnostics[0].updated_at_iso8601, stamp);
        let other = RouteCache::with_provider(
            directory.path().to_str().unwrap(),
            &sources,
            RouteProvider::DohSb,
        );
        assert!(!other.initialize().await.unwrap().initialized);
        cache
            .fetch_with(|host| async move {
                if host == "yande.re" {
                    Err("DNS timed out".into())
                } else {
                    Ok(vec!["1.1.1.1".into()])
                }
            })
            .await
            .unwrap();
        assert!(cache.candidates("yande.re").is_empty());
        assert!(!cache.candidates("danbooru.donmai.us").is_empty());
        let fresh = RouteCache::new(directory.path().to_str().unwrap(), &sources);
        let state = fresh.initialize().await.unwrap();
        let failed = state
            .diagnostics
            .iter()
            .find(|r| r.logical_host == "yande.re")
            .unwrap();
        assert_eq!(failed.status, "failed");
        assert_eq!(failed.error.as_deref(), Some("DNS timed out"));
        assert!(fresh.candidates("yande.re").is_empty());
        cache
            .fetch_with(|_| async { Err("DNS HTTP 503".into()) })
            .await
            .unwrap();
        assert!(cache.snapshot().unwrap().routes.is_empty());
        assert!(cache
            .snapshot()
            .unwrap()
            .diagnostics
            .iter()
            .all(|r| r.status == "failed"));
    }

    #[test]
    fn rejects_private_and_reserved_addresses() {
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
    }

    #[tokio::test]
    #[ignore = "requires the selected live DNS service; prints diagnostics only"]
    async fn live_selected_dns_reports_all_hosts() {
        let directory = tempfile::tempdir().unwrap();
        let provider = if std::env::var("BOORUFLOW_TEST_DNS").as_deref() == Ok("doh.sb") {
            RouteProvider::DohSb
        } else {
            RouteProvider::UncensoredDns
        };
        let cache = RouteCache::with_provider(
            directory.path().to_str().unwrap(),
            &builtin_sources(),
            provider,
        );
        let state = cache.refresh().await.unwrap();
        for report in &state.diagnostics {
            println!("{}", serde_json::to_string(report).unwrap());
        }
        assert!(state
            .diagnostics
            .iter()
            .all(|r| r.status == "resolved" || r.status == "failed"));
        if provider == RouteProvider::UncensoredDns {
            assert!(!state.routes.is_empty());
        }
    }
}
