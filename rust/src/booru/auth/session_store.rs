use crate::api::booru_auth::{AuthStateDto, AuthStatus, SourceCredentialsDto, WebCookieDto};
use crate::api::booru_models::AuthKind;
use crate::booru::auth::credential::validate_credentials;
use crate::booru::error::{BooruErrorDto, BooruResult};
use base64::Engine;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, COOKIE};
use reqwest::Url;
use std::collections::{BTreeSet, HashMap};
use std::sync::RwLock;

#[derive(Clone)]
enum AuthMaterial {
    Credentials(SourceCredentialsDto),
    WebSession {
        cookies: Vec<WebCookieDto>,
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
    sessions: RwLock<HashMap<String, Session>>,
    revisions: RwLock<HashMap<String, u32>>,
}

impl SessionStore {
    pub fn set_credentials(
        &self,
        source_id: &str,
        auth_kind: AuthKind,
        mut credentials: SourceCredentialsDto,
    ) -> BooruResult<AuthStateDto> {
        trim_option(&mut credentials.username);
        trim_option(&mut credentials.user_id);
        trim_option(&mut credentials.api_key);
        validate_credentials(source_id, auth_kind, &credentials)?;
        let revision = self.next_revision(source_id)?;
        self.sessions
            .write()
            .map_err(|_| internal_error(source_id))?
            .insert(
                source_id.to_owned(),
                Session {
                    material: AuthMaterial::Credentials(credentials),
                    status: AuthStatus::ConfiguredUnverified,
                    revision,
                },
            );
        self.state(source_id)
    }

    pub fn set_web_session(
        &self,
        source_id: &str,
        mut cookies: Vec<WebCookieDto>,
        user_agent: String,
    ) -> BooruResult<AuthStateDto> {
        if cookies.is_empty() || user_agent.trim().is_empty() {
            return Err(BooruErrorDto::invalid_request(Some(source_id)));
        }
        let user_agent = user_agent.trim().to_owned();
        for cookie in &cookies {
            if cookie.name.trim().is_empty()
                || cookie.value.is_empty()
                || cookie.domain.trim().is_empty()
                || !cookie.path.starts_with('/')
                || !cookie
                    .name
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'-' | b'.'))
                || cookie
                    .value
                    .bytes()
                    .any(|byte| matches!(byte, b';' | b'\r' | b'\n'))
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
                return Err(BooruErrorDto::invalid_request(Some(source_id)));
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
            return Err(BooruErrorDto::invalid_request(Some(source_id)));
        }
        let revision = self.next_revision(source_id)?;
        self.sessions
            .write()
            .map_err(|_| internal_error(source_id))?
            .insert(
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
        self.state(source_id)
    }

    pub fn clear(&self, source_id: &str) -> BooruResult<()> {
        self.sessions
            .write()
            .map_err(|_| internal_error(source_id))?
            .remove(source_id);
        self.next_revision(source_id)?;
        Ok(())
    }

    pub fn mark_verified(&self, source_id: &str) -> BooruResult<AuthStateDto> {
        let mut sessions = self
            .sessions
            .write()
            .map_err(|_| internal_error(source_id))?;
        let session = sessions.get_mut(source_id).ok_or_else(|| {
            BooruErrorDto::new(
                crate::booru::error::BooruErrorCode::AuthenticationRequired,
                Some(source_id),
                "booru.error.authenticationRequired",
            )
        })?;
        session.status = AuthStatus::Verified;
        state_from_session(source_id, session)
    }

    pub fn mark_rejected(&self, source_id: &str) -> BooruResult<AuthStateDto> {
        let mut sessions = self
            .sessions
            .write()
            .map_err(|_| internal_error(source_id))?;
        let session = sessions.get_mut(source_id).ok_or_else(|| {
            BooruErrorDto::new(
                crate::booru::error::BooruErrorCode::AuthenticationRequired,
                Some(source_id),
                "booru.error.authenticationRequired",
            )
        })?;
        session.status = AuthStatus::Rejected;
        state_from_session(source_id, session)
    }

    pub fn state(&self, source_id: &str) -> BooruResult<AuthStateDto> {
        let sessions = self
            .sessions
            .read()
            .map_err(|_| internal_error(source_id))?;
        if let Some(session) = sessions.get(source_id) {
            state_from_session(source_id, session)
        } else {
            Ok(AuthStateDto {
                source_id: source_id.to_owned(),
                status: AuthStatus::NotConfigured,
                username: None,
                auth_revision: self.revision(source_id),
            })
        }
    }

    pub fn is_configured(&self, source_id: &str) -> bool {
        self.sessions
            .read()
            .ok()
            .is_some_and(|sessions| sessions.contains_key(source_id))
    }

    pub fn revision(&self, source_id: &str) -> u32 {
        self.revisions
            .read()
            .ok()
            .and_then(|revisions| revisions.get(source_id).copied())
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
        let sessions = self
            .sessions
            .read()
            .map_err(|_| internal_error(source_id))?;
        let Some(session) = sessions.get(source_id) else {
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
                    .map_err(|_| BooruErrorDto::invalid_request(Some(source_id)))?;
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
                        .map_err(|_| BooruErrorDto::invalid_request(Some(source_id)))?;
                headers.insert("x-api-key", value);
            }
            (
                AuthMaterial::WebSession {
                    cookies,
                    user_agent,
                },
                AuthKind::WebSession,
            ) => {
                let values = cookies
                    .iter()
                    .filter(|cookie| cookie_matches(cookie, url))
                    .map(|cookie| (cookie.name.as_str(), cookie.value.as_str()));
                merge_cookie_header(headers, values, source_id)?;
                headers.insert(
                    reqwest::header::USER_AGENT,
                    HeaderValue::from_str(user_agent)
                        .map_err(|_| BooruErrorDto::invalid_request(Some(source_id)))?,
                );
            }
            _ => {}
        }
        Ok(())
    }

    fn next_revision(&self, source_id: &str) -> BooruResult<u32> {
        let mut revisions = self
            .revisions
            .write()
            .map_err(|_| internal_error(source_id))?;
        let revision = revisions.entry(source_id.to_owned()).or_insert(0);
        *revision = revision.wrapping_add(1);
        Ok(*revision)
    }
}

fn state_from_session(source_id: &str, session: &Session) -> BooruResult<AuthStateDto> {
    let username = match &session.material {
        AuthMaterial::Credentials(credentials) => credentials
            .username
            .clone()
            .or_else(|| credentials.user_id.clone()),
        AuthMaterial::WebSession { .. } => None,
    };
    Ok(AuthStateDto {
        source_id: source_id.to_owned(),
        status: session.status,
        username,
        auth_revision: session.revision,
    })
}

fn cookie_matches(cookie: &WebCookieDto, url: &Url) -> bool {
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

fn merge_cookie_header<'a>(
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
    let mut names = values
        .iter()
        .filter_map(|value| {
            value
                .split_once('=')
                .map(|(name, _)| name.trim().to_owned())
        })
        .collect::<BTreeSet<_>>();
    for (name, value) in cookies {
        if names.insert(name.to_owned()) {
            values.push(format!("{name}={value}"));
        }
    }
    if !values.is_empty() {
        headers.insert(
            COOKIE,
            HeaderValue::from_str(&values.join("; "))
                .map_err(|_| BooruErrorDto::invalid_request(Some(source_id)))?,
        );
    }
    Ok(())
}

fn internal_error(source_id: &str) -> BooruErrorDto {
    BooruErrorDto::new(
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
    fn cookie_scope_rejects_suffix_confusion_and_insecure_urls() {
        let cookie = WebCookieDto {
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
            &WebCookieDto {
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
        let cookie = WebCookieDto {
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
    fn web_session_preserves_the_browser_user_agent() {
        let store = SessionStore::default();
        store
            .set_web_session(
                "anime_pictures",
                vec![WebCookieDto {
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
        let credentials = SourceCredentialsDto {
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
                SourceCredentialsDto {
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
                SourceCredentialsDto {
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
                SourceCredentialsDto {
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
