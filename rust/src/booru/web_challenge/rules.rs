use crate::api::web_challenge::{WebChallengeSpec, WebChallengeTarget};
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::source::SourceDefinition;

pub const RULES_VERSION: u32 = 1;

pub struct Rules {
    pub cookie_domains: &'static [&'static str],
    pub request_hosts: &'static [&'static str],
}

pub fn rules(source: &str) -> BooruResult<Rules> {
    let (cookie_domains, request_hosts): (&[_], &[_]) = match source {
        "yande" => (
            &["yande.re", "files.yande.re", "assets.yande.re"],
            &["yande.re", "files.yande.re", "assets.yande.re"],
        ),
        "konachan_net" => (
            &["konachan.net", "www.konachan.net"],
            &["konachan.net", "www.konachan.net"],
        ),
        "konachan_com" => (
            &["konachan.com", "www.konachan.com"],
            &["konachan.com", "www.konachan.com"],
        ),
        "danbooru" => (
            &["donmai.us", "danbooru.donmai.us", "cdn.donmai.us"],
            &["danbooru.donmai.us", "cdn.donmai.us"],
        ),
        "aibooru" => (
            &["aibooru.online", "cdn.aibooru.download"],
            &["aibooru.online", "cdn.aibooru.download"],
        ),
        "gelbooru" => (
            &["gelbooru.com", "www.gelbooru.com"],
            &["gelbooru.com", "www.gelbooru.com"],
        ),
        "wallhaven" => (
            &["wallhaven.cc", "w.wallhaven.cc", "th.wallhaven.cc"],
            &["wallhaven.cc", "w.wallhaven.cc", "th.wallhaven.cc"],
        ),
        "anime_pictures" => (
            &[
                "anime-pictures.net",
                "api.anime-pictures.net",
                "opreviews.anime-pictures.net",
                "oimages.anime-pictures.net",
            ],
            &[
                "anime-pictures.net",
                "api.anime-pictures.net",
                "opreviews.anime-pictures.net",
                "oimages.anime-pictures.net",
            ],
        ),
        _ => return Err(BooruError::invalid_request(Some(source))),
    };
    Ok(Rules {
        cookie_domains,
        request_hosts,
    })
}

impl Rules {
    pub fn allows_cookie_domain(&self, domain: &str) -> bool {
        let host = domain.strip_prefix('.').unwrap_or(domain);
        self.cookie_domains
            .iter()
            .any(|allowed| host.eq_ignore_ascii_case(allowed))
    }

    pub fn allows_request(&self, url: &reqwest::Url) -> bool {
        url.scheme() == "https"
            && url.port_or_known_default() == Some(443)
            && url.username().is_empty()
            && url.password().is_none()
            && url
                .host_str()
                .is_some_and(|host| self.request_hosts.contains(&host))
    }
}

pub fn spec(source: &SourceDefinition) -> BooruResult<WebChallengeSpec> {
    let rules = rules(source.id)?;
    Ok(WebChallengeSpec {
        source_id: source.id.into(),
        display_name: source.display_name.into(),
        entry_url: source.referer.into(),
        navigation_hosts: rules
            .request_hosts
            .iter()
            .map(|value| (*value).into())
            .collect(),
        capture_targets: rules
            .request_hosts
            .iter()
            .map(|host| WebChallengeTarget {
                // A root-URL snapshot is confined to this explicitly approved HTTPS
                // host. Other hosts' snapshots are never merged into it.
                id: (*host).into(),
                url: format!("https://{host}/"),
            })
            .collect(),
        timeout_seconds: 600,
    })
}

#[cfg(all(windows, feature = "web-challenge-window"))]
pub fn navigation_allowed(spec: &WebChallengeSpec, value: &str) -> bool {
    reqwest::Url::parse(value).ok().is_some_and(|url| {
        url.scheme() == "https"
            && url.port_or_known_default() == Some(443)
            && url.username().is_empty()
            && url.password().is_none()
            && url
                .host_str()
                .is_some_and(|host| spec.navigation_hosts.iter().any(|allowed| host == allowed))
    })
}
