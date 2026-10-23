use crate::api::booru_auth::{AuthState, AuthStatus, SourceCredentials, WebCookie};
use crate::api::booru_models::AuthKind;
use crate::booru::auth::credential::validate_credentials;
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::web_challenge::material::ValidatedChallenge;
use base64::Engine;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, COOKIE};
use reqwest::Url;
use std::collections::{BTreeSet, HashMap};
use std::sync::RwLock;

#[derive(Clone)]
enum AuthMaterial {
    Credentials(SourceCredentials),
    WebSession {
        cookies: Vec<WebCookie>,
        user_agent: String,
    },
}

#[derive(Clone)]
struct Session {
    material: AuthMaterial,
    status: AuthStatus,
    revision: u32,
}

#[derive(Default)]
pub struct SessionStore {
    inner: RwLock<StoreState>,
}

/// A validated, detached snapshot. Its construction never changes the live store.
#[derive(Clone)]
pub struct WebSessionSnapshot {
    pub cookies: Vec<WebCookie>,
    pub user_agent: String,
}

#[derive(Default, Clone)]
struct StoreState {
    sessions: HashMap<String, Session>,
    revisions: HashMap<String, u32>,
    challenges: HashMap<String, ValidatedChallenge>,
}

impl SessionStore {
    pub fn suspend_challenges(&self) -> BooruResult<()> {
        let mut inner = self.inner.write().map_err(|_| internal_error("network"))?;
        let sources = inner.challenges.keys().cloned().collect::<Vec<_>>();
        inner.challenges.clear();
        for source in sources {
            let revision = next_revision(&mut inner, &source);
            if let Some(session) = inner.sessions.get_mut(&source) {
                session.revision = revision;
            }
        }
        Ok(())
    }

    pub fn detached_with_challenge(&self, challenge: ValidatedChallenge) -> BooruResult<Self> {
        let mut inner = self
            .inner
            .read()
            .map_err(|_| internal_error(&challenge.source_id))?
            .clone();
        next_revision(&mut inner, &challenge.source_id);
        inner
            .challenges
            .insert(challenge.source_id.clone(), challenge);
        Ok(Self {
            inner: RwLock::new(inner),
        })
    }

    pub fn challenge(&self, source_id: &str) -> BooruResult<Option<ValidatedChallenge>> {
        Ok(self
            .inner
            .read()
            .map_err(|_| internal_error(source_id))?
            .challenges
            .get(source_id)
            .cloned())
    }

    pub fn publish_challenge(
        &self,
        challenge: ValidatedChallenge,
        expected_revision: u32,
        persist: impl FnOnce() -> BooruResult<()>,
    ) -> BooruResult<u32> {
        let mut inner = self
            .inner
            .write()
            .map_err(|_| internal_error(&challenge.source_id))?;
        if inner
            .revisions
            .get(&challenge.source_id)
            .copied()
            .unwrap_or(0)
            != expected_revision
        {
            return Err(BooruError::new(
                crate::booru::error::BooruErrorCode::Cancelled,
                Some(&challenge.source_id),
                "webChallenge.operationSuperseded",
            ));
        }
        inner.challenges.reserve(1);
        inner.revisions.reserve(1);
        let key = challenge.source_id.clone();
        let revision_key = key.clone();
        let revision = expected_revision.wrapping_add(1);
        persist()?;
        if let Some(session) = inner.sessions.get_mut(&key) {
            session.revision = revision;
        }
        inner.challenges.insert(key, challenge);
        inner.revisions.insert(revision_key, revision);
        Ok(revision)
    }

    pub fn clear_challenge(
        &self,
        source_id: &str,
        persist: impl FnOnce() -> BooruResult<()>,
    ) -> BooruResult<u32> {
        let mut inner = self.inner.write().map_err(|_| internal_error(source_id))?;
        inner.revisions.reserve(1);
        let key = source_id.to_owned();
        let revision = inner
            .revisions
            .get(source_id)
            .copied()
            .unwrap_or(0)
            .wrapping_add(1);
        persist()?;
        inner.challenges.remove(source_id);
        if let Some(session) = inner.sessions.get_mut(source_id) {
            session.revision = revision;
        }
        inner.revisions.insert(key, revision);
        Ok(revision)
    }

    pub fn web_snapshot(&self, source_id: &str) -> BooruResult<Option<WebSessionSnapshot>> {
        let inner = self.inner.read().map_err(|_| internal_error(source_id))?;
        Ok(inner
            .sessions
            .get(source_id)
            .and_then(|session| match &session.material {
                AuthMaterial::WebSession {
                    cookies,
                    user_agent,
                } => Some(WebSessionSnapshot {
                    cookies: cookies.clone(),
                    user_agent: user_agent.clone(),
                }),
                _ => None,
            }))
    }

    pub fn set_credentials(
        &self,
        source_id: &str,
        auth_kind: AuthKind,
        mut credentials: SourceCredentials,
    ) -> BooruResult<AuthState> {
        trim_option(&mut credentials.username);
        trim_option(&mut credentials.user_id);
        trim_option(&mut credentials.api_key);
        validate_credentials(source_id, auth_kind, &credentials)?;
        let mut inner = self.inner.write().map_err(|_| internal_error(source_id))?;
        let revision = next_revision(&mut inner, source_id);
        inner.sessions.insert(
            source_id.to_owned(),
            Session {
                material: AuthMaterial::Credentials(credentials),
                status: AuthStatus::ConfiguredUnverified,
                revision,
            },
        );
        state_from_session(source_id, &inner.sessions[source_id])
    }

    pub fn set_web_session(
        &self,
        source_id: &str,
        mut cookies: Vec<WebCookie>,
        user_agent: String,
    ) -> BooruResult<AuthState> {
        if cookies.is_empty()
            || cookies.len() > 128
            || user_agent.trim().is_empty()
            || user_agent.len() > 4096
            || HeaderValue::from_str(user_agent.trim()).is_err()
            || cookies
                .iter()
                .map(|cookie| {
                    cookie.name.len()
                        + cookie.value.len()
                        + cookie.domain.len()
                        + cookie.path.len()
                        + cookie.expires_at_iso8601.as_ref().map_or(0, String::len)
                })
                .sum::<usize>()
                > 64 * 1024
        {
            return Err(BooruError::invalid_request(Some(source_id)));
        }
        let user_agent = user_agent.trim().to_owned();
        let mut scopes = BTreeSet::new();
        for cookie in &cookies {
            if cookie.name.trim().is_empty()
                || !valid_cookie_domain(&cookie.domain)
                || !scopes.insert((cookie.name.as_str(), cookie.domain.to_ascii_lowercase(), cookie.path.as_str()))
                || !cookie.path.starts_with('/')
                || !cookie
                    .name
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'-' | b'.'))
                || cookie
                    .value
                    .bytes()
                    .any(|byte| !matches!(byte, 0x21 | 0x23..=0x2b | 0x2d..=0x3a | 0x3c..=0x5b | 0x5d..=0x7e))
                || cookie
                    .domain
                    .bytes()
                    .any(|byte| matches!(byte, b'/' | b'\\' | b'\r' | b'\n'))
                || cookie
                    .path
                    .bytes()
                    .any(|byte| matches!(byte, b'\r' | b'\n'))
                || cookie
                    .expires_at_iso8601
                    .as_deref()
                    .is_some_and(|value| parse_expiry(value).is_none())
            {
                return Err(BooruError::invalid_request(Some(source_id)));
            }
        }
        cookies.retain(|cookie| {
            cookie
                .expires_at_iso8601
                .as_deref()
                .and_then(parse_expiry)
                .is_none_or(|expires| expires > time::OffsetDateTime::now_utc())
        });
        if cookies.is_empty() {
            return Err(BooruError::invalid_request(Some(source_id)));
        }
        let mut inner = self.inner.write().map_err(|_| internal_error(source_id))?;
        let revision = next_revision(&mut inner, source_id);
        inner.sessions.insert(
            source_id.to_owned(),
            Session {
                material: AuthMaterial::WebSession {
                    cookies,
                    user_agent,
                },
                status: AuthStatus::ConfiguredUnverified,
                revision,
            },
        );
        state_from_session(source_id, &inner.sessions[source_id])
    }

    pub fn clear(&self, source_id: &str) -> BooruResult<()> {
        let mut inner = self.inner.write().map_err(|_| internal_error(source_id))?;
        inner.sessions.remove(source_id);
        next_revision(&mut inner, source_id);
        Ok(())
    }

    pub fn mark_verified(&self, source_id: &str) -> BooruResult<AuthState> {
        let mut inner = self.inner.write().map_err(|_| internal_error(source_id))?;
        let session = inner.sessions.get_mut(source_id).ok_or_else(|| {
            BooruError::new(
                crate::booru::error::BooruErrorCode::AuthenticationRequired,
                Some(source_id),
                "booru.error.authenticationRequired",
            )
        })?;
        session.status = AuthStatus::Verified;
        state_from_session(source_id, session)
    }

    pub fn mark_rejected(&self, source_id: &str) -> BooruResult<AuthState> {
        let mut inner = self.inner.write().map_err(|_| internal_error(source_id))?;
        let session = inner.sessions.get_mut(source_id).ok_or_else(|| {
            BooruError::new(
                crate::booru::error::BooruErrorCode::AuthenticationRequired,
                Some(source_id),
                "booru.error.authenticationRequired",
            )
        })?;
        session.status = AuthStatus::Rejected;
        state_from_session(source_id, session)
    }

    pub fn state(&self, source_id: &str) -> BooruResult<AuthState> {
        let inner = self.inner.read().map_err(|_| internal_error(source_id))?;
        if let Some(session) = inner.sessions.get(source_id) {
            state_from_session(source_id, session)
        } else {
            Ok(AuthState {
                source_id: source_id.to_owned(),
                status: AuthStatus::NotConfigured,
                username: None,
                auth_revision: inner.revisions.get(source_id).copied().unwrap_or(0),
            })
        }
    }

    pub fn is_configured(&self, source_id: &str) -> bool {
        self.inner
            .read()
            .ok()
            .is_some_and(|inner| inner.sessions.contains_key(source_id))
    }

    pub fn revision(&self, source_id: &str) -> u32 {
        self.inner
            .read()
            .ok()
            .and_then(|inner| inner.revisions.get(source_id).copied())
            .unwrap_or(0)
    }

    pub fn apply(
        &self,
        source_id: &str,
        auth_kind: AuthKind,
        url: &mut Url,
        headers: &mut HeaderMap,
        allow_api_credentials: bool,
    ) -> BooruResult<()> {
        let inner = self.inner.read().map_err(|_| internal_error(source_id))?;
        if let Some(challenge) = inner.challenges.get(source_id) {
            challenge.apply(url, headers)?;
        }
        let Some(session) = inner.sessions.get(source_id) else {
            return Ok(());
        };
        match (&session.material, auth_kind) {
            (AuthMaterial::Credentials(credentials), AuthKind::LoginApiKey)
                if allow_api_credentials =>
            {
                let username = credentials.username.as_deref().unwrap_or_default();
                let key = credentials.api_key.as_deref().unwrap_or_default();
                let encoded =
                    base64::engine::general_purpose::STANDARD.encode(format!("{username}:{key}"));
                let value = HeaderValue::from_str(&format!("Basic {encoded}"))
                    .map_err(|_| BooruError::invalid_request(Some(source_id)))?;
                headers.insert(AUTHORIZATION, value);
            }
            (AuthMaterial::Credentials(credentials), AuthKind::UserIdApiKey)
                if allow_api_credentials =>
            {
                let existing = url
                    .query_pairs()
                    .map(|(key, _)| key.into_owned())
                    .collect::<std::collections::BTreeSet<_>>();
                let mut query = url.query_pairs_mut();
                if !existing.contains("user_id") {
                    query.append_pair(
                        "user_id",
                        credentials.user_id.as_deref().unwrap_or_default(),
                    );
                }
                if !existing.contains("api_key") {
                    query.append_pair(
                        "api_key",
                        credentials.api_key.as_deref().unwrap_or_default(),
                    );
                }
            }
            (AuthMaterial::Credentials(credentials), AuthKind::ApiKey) if allow_api_credentials => {
                let value =
                    HeaderValue::from_str(credentials.api_key.as_deref().unwrap_or_default())
                        .map_err(|_| BooruError::invalid_request(Some(source_id)))?;
                headers.insert("x-api-key", value);
            }
            (
                AuthMaterial::WebSession {
                    cookies,
                    user_agent,
                },
                AuthKind::WebSession,
            ) => {
                let mut matching = cookies
                    .iter()
                    .filter(|cookie| cookie_matches(cookie, url))
                    .collect::<Vec<_>>();
                // A more specific path precedes a less specific path. Do not
                // collapse same-name cookies with distinct domain/path scope.
                matching.sort_by_key(|cookie| std::cmp::Reverse(cookie.path.len()));
                let values = matching
                    .into_iter()
                    .map(|cookie| (cookie.name.as_str(), cookie.value.as_str()));
                merge_cookie_header(headers, values, source_id)?;
                headers.insert(
                    reqwest::header::USER_AGENT,
                    HeaderValue::from_str(user_agent)
                        .map_err(|_| BooruError::invalid_request(Some(source_id)))?,
                );
            }
            _ => {}
        }
        if let Some(challenge) = inner.challenges.get(source_id) {
            challenge.apply_user_agent(url, headers)?;
        }
        Ok(())
    }
}

fn next_revision(inner: &mut StoreState, source_id: &str) -> u32 {
    let revision = inner.revisions.entry(source_id.to_owned()).or_insert(0);
    *revision = revision.wrapping_add(1);
    *revision
}

fn valid_cookie_domain(domain: &str) -> bool {
    let host = domain.strip_prefix('.').unwrap_or(domain);
    !host.is_empty()
        && host.len() <= 253
        && host.split('.').all(|label| {
            !label.is_empty()
                && label.len() <= 63
                && !label.starts_with('-')
                && !label.ends_with('-')
                && label
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-')
        })
}

fn state_from_session(source_id: &str, session: &Session) -> BooruResult<AuthState> {
    let username = match &session.material {
        AuthMaterial::Credentials(credentials) => credentials
            .username
            .clone()
            .or_else(|| credentials.user_id.clone()),
        AuthMaterial::WebSession { .. } => None,
    };
    Ok(AuthState {
        source_id: source_id.to_owned(),
        status: session.status,
        username,
        auth_revision: session.revision,
    })
}

pub(crate) fn cookie_matches(cookie: &WebCookie, url: &Url) -> bool {
    if cookie.secure && url.scheme() != "https" {
        return false;
    }
    let Some(host) = url.host_str() else {
        return false;
    };
    if cookie
        .expires_at_iso8601
        .as_deref()
        .and_then(parse_expiry)
        .is_some_and(|expires| expires <= time::OffsetDateTime::now_utc())
    {
        return false;
    }
    let raw_domain = cookie.domain.trim();
    let is_domain_cookie = raw_domain.starts_with('.');
    let domain = raw_domain.trim_start_matches('.').to_ascii_lowercase();
    let host = host.to_ascii_lowercase();
    let domain_matches = host == domain
        || (is_domain_cookie
            && host
                .strip_suffix(&domain)
                .is_some_and(|prefix| prefix.ends_with('.')));
    domain_matches && path_matches(&cookie.path, url.path())
}

fn path_matches(cookie_path: &str, request_path: &str) -> bool {
    request_path == cookie_path
        || request_path
            .strip_prefix(cookie_path)
            .is_some_and(|suffix| {
                cookie_path.ends_with('/') || suffix.as_bytes().first() == Some(&b'/')
            })
}

fn parse_expiry(value: &str) -> Option<time::OffsetDateTime> {
    time::OffsetDateTime::parse(value, &time::format_description::well_known::Rfc3339).ok()
}

pub(crate) fn merge_cookie_header<'a>(
    headers: &mut HeaderMap,
    cookies: impl Iterator<Item = (&'a str, &'a str)>,
    source_id: &str,
) -> BooruResult<()> {
    let existing = headers
        .get(COOKIE)
        .and_then(|value| value.to_str().ok())
        .unwrap_or_default();
    let mut values = existing
        .split(';')
        .map(str::trim)
        .filter(|value| value.contains('='))
        .map(str::to_owned)
        .collect::<Vec<_>>();
    let names = values
        .iter()
        .filter_map(|value| {
            value
                .split_once('=')
                .map(|(name, _)| name.trim().to_owned())
        })
        .collect::<BTreeSet<_>>();
    for (name, value) in cookies {
        // Only caller-supplied temporary cookies override the session by name.
        // Session cookies must not suppress one another merely by sharing a name.
        if !names.contains(name) {
            values.push(format!("{name}={value}"));
        }
    }
    if !values.is_empty() {
        headers.insert(
            COOKIE,
            HeaderValue::from_str(&values.join("; "))
                .map_err(|_| BooruError::invalid_request(Some(source_id)))?,
        );
    }
    Ok(())
}

fn internal_error(source_id: &str) -> BooruError {
    BooruError::new(
        crate::booru::error::BooruErrorCode::Internal,
        Some(source_id),
        "booru.error.internal",
    )
}

fn trim_option(value: &mut Option<String>) {
    if let Some(inner) = value {
        *inner = inner.trim().to_owned();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn invalid_replacement_preserves_session_and_revision() {
        let store = SessionStore::default();
        let cookie = WebCookie {
            name: "session".into(),
            value: "old==".into(),
            domain: ".anime-pictures.net".into(),
            path: "/".into(),
            secure: true,
            expires_at_iso8601: None,
        };
        let before = store
            .set_web_session("anime_pictures", vec![cookie.clone()], "Browser".into())
            .unwrap();
        let mut candidates = vec![vec![cookie.clone(); 129], vec![cookie.clone(); 2]];
        for value in [
            "bad\0value",
            "bad\tvalue",
            "bad\nvalue",
            "bad;value",
            "nonascii\u{ff}",
        ] {
            candidates.push(vec![WebCookie {
                value: value.into(),
                ..cookie.clone()
            }]);
        }
        for domain in [
            "..anime-pictures.net",
            "net/",
            "anime-pictures.net:443",
            " anime-pictures.net",
            "-host.net",
        ] {
            candidates.push(vec![WebCookie {
                domain: domain.into(),
                ..cookie.clone()
            }]);
        }
        for candidate in candidates {
            assert!(store
                .set_web_session("anime_pictures", candidate, "Browser".into())
                .is_err());
            assert_eq!(store.state("anime_pictures").unwrap(), before);
        }
        assert!(store
            .set_web_session("anime_pictures", vec![cookie], "bad\nUA".into())
            .is_err());
        assert_eq!(store.state("anime_pictures").unwrap(), before);
        let mut headers = HeaderMap::new();
        store
            .apply(
                "anime_pictures",
                AuthKind::WebSession,
                &mut Url::parse("https://api.anime-pictures.net/api/v3/users/me").unwrap(),
                &mut headers,
                true,
            )
            .unwrap();
        assert_eq!(headers.get(COOKIE).unwrap(), "session=old==");
    }

    #[test]
    fn concurrent_mutations_return_their_own_revision() {
        let store = std::sync::Arc::new(SessionStore::default());
        let workers = (0..8)
            .map(|_| {
                let store = store.clone();
                std::thread::spawn(move || {
                    (0..100)
                        .map(|_| {
                            store
                                .set_credentials(
                                    "wallhaven",
                                    AuthKind::ApiKey,
                                    SourceCredentials {
                                        api_key: Some("marker".into()),
                                        ..Default::default()
                                    },
                                )
                                .unwrap()
                                .auth_revision
                        })
                        .collect::<Vec<_>>()
                })
            })
            .collect::<Vec<_>>();
        let revisions = workers
            .into_iter()
            .flat_map(|worker| worker.join().unwrap())
            .collect::<BTreeSet<_>>();
        assert_eq!(revisions.len(), 800);
        assert_eq!(store.state("wallhaven").unwrap().auth_revision, 800);
        assert_eq!(store.revision("wallhaven"), 800);
    }

    #[test]
    fn cookie_scope_rejects_suffix_confusion_and_insecure_urls() {
        let cookie = WebCookie {
            name: "session".to_owned(),
            value: "marker".to_owned(),
            domain: ".anime-pictures.net".to_owned(),
            path: "/pictures".to_owned(),
            secure: true,
            expires_at_iso8601: None,
        };
        assert!(cookie_matches(
            &cookie,
            &Url::parse("https://api.anime-pictures.net/pictures/a").unwrap()
        ));
        assert!(!cookie_matches(
            &cookie,
            &Url::parse("https://evil-anime-pictures.net/pictures/a").unwrap()
        ));
        assert!(!cookie_matches(
            &cookie,
            &Url::parse("http://api.anime-pictures.net/pictures/a").unwrap()
        ));
        assert!(!cookie_matches(
            &WebCookie {
                domain: "api.anime-pictures.net".to_owned(),
                path: "/pictures".to_owned(),
                ..cookie.clone()
            },
            &Url::parse("https://cdn.api.anime-pictures.net/pictures/a").unwrap()
        ));
        assert!(!cookie_matches(
            &cookie,
            &Url::parse("https://api.anime-pictures.net/picturesque/a").unwrap()
        ));
    }

    #[test]
    fn expired_cookie_is_not_sent() {
        let cookie = WebCookie {
            name: "session".to_owned(),
            value: "marker".to_owned(),
            domain: ".anime-pictures.net".to_owned(),
            path: "/".to_owned(),
            secure: true,
            expires_at_iso8601: Some("2000-01-01T00:00:00Z".to_owned()),
        };
        assert!(!cookie_matches(
            &cookie,
            &Url::parse("https://api.anime-pictures.net/posts").unwrap()
        ));
    }

    #[test]
    fn temporary_cookie_wins_when_session_cookie_is_merged() {
        let mut headers = HeaderMap::new();
        headers.insert(COOKIE, HeaderValue::from_static("download=temporary"));
        merge_cookie_header(
            &mut headers,
            [("download", "stale"), ("session", "active")].into_iter(),
            "anime_pictures",
        )
        .unwrap();
        assert_eq!(
            headers.get(COOKIE).unwrap(),
            "download=temporary; session=active"
        );
    }

    #[test]
    fn matching_same_name_cookies_keep_scope_and_specific_path_first() {
        let store = SessionStore::default();
        let root = WebCookie {
            name: "session".to_owned(),
            value: "root==".to_owned(),
            domain: ".anime-pictures.net".to_owned(),
            path: "/".to_owned(),
            secure: true,
            expires_at_iso8601: None,
        };
        store
            .set_web_session(
                "anime_pictures",
                vec![
                    root.clone(),
                    WebCookie {
                        value: "api=value".to_owned(),
                        path: "/api".to_owned(),
                        ..root.clone()
                    },
                    WebCookie {
                        name: "preference".to_owned(),
                        value: String::new(),
                        ..root
                    },
                ],
                "Browser-UA".to_owned(),
            )
            .unwrap();
        let mut headers = HeaderMap::new();
        store
            .apply(
                "anime_pictures",
                AuthKind::WebSession,
                &mut Url::parse("https://api.anime-pictures.net/api/v3/users/me").unwrap(),
                &mut headers,
                true,
            )
            .unwrap();
        assert_eq!(
            headers.get(COOKIE).unwrap(),
            "session=api=value; session=root==; preference="
        );

        let mut headers = HeaderMap::new();
        headers.insert(COOKIE, HeaderValue::from_static("session=temporary"));
        store
            .apply(
                "anime_pictures",
                AuthKind::WebSession,
                &mut Url::parse("https://api.anime-pictures.net/api/v3/users/me").unwrap(),
                &mut headers,
                true,
            )
            .unwrap();
        assert_eq!(
            headers.get(COOKIE).unwrap(),
            "session=temporary; preference="
        );
    }

    #[test]
    fn web_session_preserves_the_browser_user_agent() {
        let store = SessionStore::default();
        store
            .set_web_session(
                "anime_pictures",
                vec![WebCookie {
                    name: "session".to_owned(),
                    value: "marker".to_owned(),
                    domain: ".anime-pictures.net".to_owned(),
                    path: "/".to_owned(),
                    secure: true,
                    expires_at_iso8601: None,
                }],
                "  Mozilla/5.0 Imported-Browser  ".to_owned(),
            )
            .unwrap();
        let mut headers = HeaderMap::new();
        store
            .apply(
                "anime_pictures",
                AuthKind::WebSession,
                &mut Url::parse("https://api.anime-pictures.net/api/v3/posts").unwrap(),
                &mut headers,
                true,
            )
            .unwrap();
        assert_eq!(
            headers.get(reqwest::header::USER_AGENT).unwrap(),
            "Mozilla/5.0 Imported-Browser"
        );
    }

    #[test]
    fn changing_credentials_increments_revision() {
        let store = SessionStore::default();
        let credentials = SourceCredentials {
            username: None,
            user_id: None,
            api_key: Some("marker".to_owned()),
        };
        let first = store
            .set_credentials("wallhaven", AuthKind::ApiKey, credentials.clone())
            .unwrap();
        let second = store
            .set_credentials("wallhaven", AuthKind::ApiKey, credentials)
            .unwrap();
        assert!(second.auth_revision > first.auth_revision);
        store.clear("wallhaven").unwrap();
        assert!(store.revision("wallhaven") > second.auth_revision);
    }

    #[test]
    fn injects_each_credential_protocol_without_cross_host_leakage() {
        let store = SessionStore::default();
        store
            .set_credentials(
                "danbooru",
                AuthKind::LoginApiKey,
                SourceCredentials {
                    username: Some("alice".to_owned()),
                    user_id: None,
                    api_key: Some("secret".to_owned()),
                },
            )
            .unwrap();
        let mut url = Url::parse("https://danbooru.donmai.us/posts.json").unwrap();
        let mut headers = HeaderMap::new();
        store
            .apply(
                "danbooru",
                AuthKind::LoginApiKey,
                &mut url,
                &mut headers,
                true,
            )
            .unwrap();
        assert!(headers
            .get(AUTHORIZATION)
            .unwrap()
            .to_str()
            .unwrap()
            .starts_with("Basic "));

        store
            .set_credentials(
                "gelbooru",
                AuthKind::UserIdApiKey,
                SourceCredentials {
                    username: None,
                    user_id: Some("42".to_owned()),
                    api_key: Some("key".to_owned()),
                },
            )
            .unwrap();
        let mut url = Url::parse("https://gelbooru.com/index.php?page=dapi").unwrap();
        store
            .apply(
                "gelbooru",
                AuthKind::UserIdApiKey,
                &mut url,
                &mut HeaderMap::new(),
                true,
            )
            .unwrap();
        let query = url.query_pairs().collect::<HashMap<_, _>>();
        assert_eq!(query.get("user_id").map(|value| value.as_ref()), Some("42"));
        assert_eq!(
            query.get("api_key").map(|value| value.as_ref()),
            Some("key")
        );

        store
            .set_credentials(
                "wallhaven",
                AuthKind::ApiKey,
                SourceCredentials {
                    username: None,
                    user_id: None,
                    api_key: Some("wall-key".to_owned()),
                },
            )
            .unwrap();
        let mut headers = HeaderMap::new();
        store
            .apply(
                "wallhaven",
                AuthKind::ApiKey,
                &mut Url::parse("https://wallhaven.cc/api/v1/search").unwrap(),
                &mut headers,
                true,
            )
            .unwrap();
        assert_eq!(headers.get("x-api-key").unwrap(), "wall-key");
        let mut cdn_headers = HeaderMap::new();
        store
            .apply(
                "wallhaven",
                AuthKind::ApiKey,
                &mut Url::parse("https://w.wallhaven.cc/full/a.jpg").unwrap(),
                &mut cdn_headers,
                false,
            )
            .unwrap();
        assert!(!cdn_headers.contains_key("x-api-key"));
    }
}
