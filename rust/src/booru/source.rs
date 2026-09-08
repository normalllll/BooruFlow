use crate::api::booru_models::{
    AuthKind, BooruProtocol, BooruSource, ContentRating, SourceCapabilities,
};
use crate::booru::capabilities::capabilities;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProtocolFamily {
    Moebooru,
    Danbooru,
    Gelbooru,
    Wallhaven,
    AnimePictures,
}

#[derive(Debug, Clone)]
pub struct SourceDefinition {
    pub id: &'static str,
    pub display_name: &'static str,
    pub family: ProtocolFamily,
    pub api_base: &'static str,
    pub web_base: &'static str,
    pub referer: &'static str,
    pub allowed_hosts: &'static [&'static str],
    pub allowed_host_suffixes: &'static [&'static str],
    pub max_page_size: u32,
    pub requests_per_minute: u32,
    pub max_concurrency: u32,
    pub enabled_by_default: bool,
    pub is_ai_source: bool,
    pub capabilities: SourceCapabilities,
}

impl SourceDefinition {
    pub fn to_api(&self) -> BooruSource {
        BooruSource {
            source_id: self.id.to_owned(),
            display_name: self.display_name.to_owned(),
            protocol: match self.family {
                ProtocolFamily::Moebooru => BooruProtocol::Moebooru,
                ProtocolFamily::Danbooru => BooruProtocol::Danbooru,
                ProtocolFamily::Gelbooru => BooruProtocol::GelbooruDapi,
                ProtocolFamily::Wallhaven => BooruProtocol::WallhavenV1,
                ProtocolFamily::AnimePictures => BooruProtocol::AnimePicturesV3,
            },
            enabled_by_default: self.enabled_by_default,
            is_ai_source: self.is_ai_source,
            capabilities: self.capabilities.clone(),
        }
    }

    pub fn allows_host(&self, host: &str) -> bool {
        let normalized = host.trim_end_matches('.').to_ascii_lowercase();
        self.allowed_hosts
            .iter()
            .any(|allowed| normalized == *allowed)
            || self.allowed_host_suffixes.iter().any(|suffix| {
                normalized.ends_with(suffix)
                    && normalized
                        .strip_suffix(suffix)
                        .is_some_and(|prefix| prefix.ends_with('.'))
            })
    }
}

pub fn builtin_sources() -> Vec<SourceDefinition> {
    let moebooru_ratings = vec![
        ContentRating::General,
        ContentRating::Questionable,
        ContentRating::Explicit,
    ];
    let all_ratings = vec![
        ContentRating::General,
        ContentRating::Sensitive,
        ContentRating::Questionable,
        ContentRating::Explicit,
    ];
    let mut sources = vec![
        SourceDefinition {
            id: "yande",
            display_name: "Yande.re",
            family: ProtocolFamily::Moebooru,
            api_base: "https://yande.re",
            web_base: "https://yande.re",
            referer: "https://yande.re/",
            allowed_hosts: &["yande.re", "files.yande.re", "assets.yande.re"],
            allowed_host_suffixes: &[],
            max_page_size: 100,
            requests_per_minute: 60,
            max_concurrency: 4,
            enabled_by_default: true,
            is_ai_source: false,
            capabilities: capabilities(moebooru_ratings.clone(), AuthKind::None, true, true, false),
        },
        SourceDefinition {
            id: "konachan_net",
            display_name: "Konachan.net",
            family: ProtocolFamily::Moebooru,
            api_base: "https://konachan.net",
            web_base: "https://konachan.net",
            referer: "https://konachan.net/",
            allowed_hosts: &["konachan.net"],
            allowed_host_suffixes: &["konachan.net"],
            max_page_size: 100,
            requests_per_minute: 60,
            max_concurrency: 4,
            enabled_by_default: true,
            is_ai_source: false,
            capabilities: capabilities(moebooru_ratings.clone(), AuthKind::None, true, true, false),
        },
        SourceDefinition {
            id: "konachan_com",
            display_name: "Konachan.com",
            family: ProtocolFamily::Moebooru,
            api_base: "https://konachan.com",
            web_base: "https://konachan.com",
            referer: "https://konachan.com/",
            allowed_hosts: &["konachan.com", "www.konachan.com"],
            allowed_host_suffixes: &["konachan.com"],
            max_page_size: 100,
            requests_per_minute: 60,
            max_concurrency: 4,
            enabled_by_default: true,
            is_ai_source: false,
            capabilities: capabilities(moebooru_ratings, AuthKind::None, true, true, false),
        },
        SourceDefinition {
            id: "danbooru",
            display_name: "Danbooru",
            family: ProtocolFamily::Danbooru,
            api_base: "https://danbooru.donmai.us",
            web_base: "https://danbooru.donmai.us",
            referer: "https://danbooru.donmai.us/",
            allowed_hosts: &["danbooru.donmai.us", "cdn.donmai.us"],
            allowed_host_suffixes: &["donmai.us"],
            max_page_size: 200,
            requests_per_minute: 60,
            max_concurrency: 4,
            enabled_by_default: true,
            is_ai_source: false,
            capabilities: capabilities(
                all_ratings.clone(),
                AuthKind::LoginApiKey,
                true,
                false,
                false,
            ),
        },
        SourceDefinition {
            id: "aibooru",
            display_name: "AIBooru",
            family: ProtocolFamily::Danbooru,
            api_base: "https://aibooru.online",
            web_base: "https://aibooru.online",
            referer: "https://aibooru.online/",
            allowed_hosts: &["aibooru.online", "cdn.aibooru.download"],
            allowed_host_suffixes: &["aibooru.online", "aibooru.download"],
            max_page_size: 200,
            requests_per_minute: 60,
            max_concurrency: 4,
            enabled_by_default: true,
            is_ai_source: true,
            capabilities: capabilities(
                all_ratings.clone(),
                AuthKind::LoginApiKey,
                true,
                false,
                false,
            ),
        },
        SourceDefinition {
            id: "gelbooru",
            display_name: "Gelbooru",
            family: ProtocolFamily::Gelbooru,
            api_base: "https://gelbooru.com",
            web_base: "https://gelbooru.com",
            referer: "https://gelbooru.com/",
            allowed_hosts: &["gelbooru.com", "www.gelbooru.com"],
            allowed_host_suffixes: &["gelbooru.com"],
            max_page_size: 100,
            requests_per_minute: 30,
            max_concurrency: 3,
            enabled_by_default: true,
            is_ai_source: false,
            capabilities: capabilities(
                all_ratings.clone(),
                AuthKind::UserIdApiKey,
                false,
                false,
                false,
            ),
        },
        SourceDefinition {
            id: "wallhaven",
            display_name: "Wallhaven",
            family: ProtocolFamily::Wallhaven,
            api_base: "https://wallhaven.cc/api/v1",
            web_base: "https://wallhaven.cc",
            referer: "https://wallhaven.cc/",
            allowed_hosts: &["wallhaven.cc", "w.wallhaven.cc", "th.wallhaven.cc"],
            allowed_host_suffixes: &["wallhaven.cc"],
            max_page_size: 24,
            requests_per_minute: 45,
            max_concurrency: 3,
            enabled_by_default: true,
            is_ai_source: false,
            capabilities: capabilities(
                vec![
                    ContentRating::General,
                    ContentRating::Sensitive,
                    ContentRating::Explicit,
                ],
                AuthKind::ApiKey,
                false,
                false,
                false,
            ),
        },
        SourceDefinition {
            id: "anime_pictures",
            display_name: "Anime-Pictures",
            family: ProtocolFamily::AnimePictures,
            api_base: "https://api.anime-pictures.net/api/v3",
            web_base: "https://anime-pictures.net",
            referer: "https://anime-pictures.net/",
            allowed_hosts: &[
                "api.anime-pictures.net",
                "anime-pictures.net",
                "opreviews.anime-pictures.net",
            ],
            allowed_host_suffixes: &["anime-pictures.net"],
            max_page_size: 80,
            requests_per_minute: 60,
            max_concurrency: 3,
            enabled_by_default: true,
            is_ai_source: false,
            capabilities: capabilities(all_ratings, AuthKind::WebSession, false, false, true),
        },
    ];
    for source in &mut sources {
        source.capabilities.discovery = crate::booru::discovery::capabilities(source);
        if source.family == ProtocolFamily::Gelbooru {
            source.capabilities.supports_autocomplete = true;
        }
    }
    sources
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn registry_has_eight_unique_sources() {
        let sources = builtin_sources();
        let mut ids = sources.iter().map(|source| source.id).collect::<Vec<_>>();
        ids.sort_unstable();
        ids.dedup();
        assert_eq!(sources.len(), 8);
        assert_eq!(ids.len(), 8);
    }

    #[test]
    fn host_allowlist_requires_a_label_boundary() {
        let source = builtin_sources()
            .into_iter()
            .find(|source| source.id == "wallhaven")
            .unwrap();
        assert!(source.allows_host("th.wallhaven.cc"));
        assert!(source.allows_host("a.th.wallhaven.cc"));
        assert!(!source.allows_host("evilwallhaven.cc"));
    }
}
