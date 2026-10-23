use crate::api::booru_models::{ContentRating, FeedKind, FeedRequest, SearchRequest};
use crate::booru::discovery::{parse_date, period, scale, validate_feed, wallhaven_purity_bits};
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::source::{ProtocolFamily, SourceDefinition};
use url::Url;

pub fn search_url(source: &SourceDefinition, request: &SearchRequest) -> BooruResult<String> {
    if request.source_id != source.id
        || request.page_size == 0
        || request
            .ratings
            .iter()
            .any(|r| !source.capabilities.ratings.contains(r))
    {
        return Err(BooruError::invalid_request(Some(source.id)));
    }
    let query = request.query_text.trim();
    let mut url = match source.family {
        ProtocolFamily::Moebooru => {
            let mut url = website(source, "/post")?;
            let mut tags = query.to_owned();
            // Match the upstream adapter's single-rating query. Multiple ratings
            // are filtered locally and have no equivalent on this website page.
            if request.ratings.len() == 1 {
                let rating = match request.ratings[0] {
                    ContentRating::General | ContentRating::Sensitive => "rating:s",
                    ContentRating::Questionable => "rating:q",
                    ContentRating::Explicit => "rating:e",
                    ContentRating::Unknown => {
                        return Err(BooruError::invalid_request(Some(source.id)))
                    }
                };
                if !tags.is_empty() {
                    tags.push(' ');
                }
                tags.push_str(rating);
            }
            if !tags.is_empty() {
                url.query_pairs_mut().append_pair("tags", &tags);
            }
            url
        }
        ProtocolFamily::Danbooru => {
            let mut url = website(source, "/posts")?;
            if !query.is_empty() {
                url.query_pairs_mut().append_pair("tags", query);
            }
            url
        }
        ProtocolFamily::Gelbooru => {
            let mut url = website(source, "/index.php")?;
            url.query_pairs_mut()
                .append_pair("page", "post")
                .append_pair("s", "list")
                .append_pair("tags", if query.is_empty() { "all" } else { query });
            url
        }
        ProtocolFamily::Wallhaven => {
            let mut url = wallhaven_search(source, &request.ratings)?;
            url.query_pairs_mut().append_pair("sorting", "date_added");
            if !query.is_empty() {
                url.query_pairs_mut().append_pair("q", query);
            }
            url
        }
        ProtocolFamily::AnimePictures => {
            let mut url = website(source, "/posts")?;
            if !query.is_empty() {
                url.query_pairs_mut().append_pair("search_tag", query);
            }
            url
        }
    };
    url.set_fragment(None);
    Ok(url.into())
}

pub fn feed_url(source: &SourceDefinition, request: &FeedRequest) -> BooruResult<String> {
    if request.source_id != source.id {
        return Err(BooruError::invalid_request(Some(source.id)));
    }
    validate_feed(source, request)?;
    if request.kind == FeedKind::Latest {
        return search_url(
            source,
            &SearchRequest {
                source_id: request.source_id.clone(),
                query_text: String::new(),
                ratings: request.ratings.clone(),
                page_size: request.page_size,
                cursor: None,
            },
        );
    }
    let url = match source.family {
        ProtocolFamily::Moebooru => {
            let range = request
                .range
                .ok_or_else(|| BooruError::invalid_request(Some(source.id)))?;
            if request.kind == FeedKind::RecentPopular {
                let mut url = website(source, "/post/popular_recent")?;
                url.query_pairs_mut()
                    .append_pair("period", period(range, false));
                url
            } else {
                let date = parse_date(source.id, request.date.as_deref().unwrap_or_default())?;
                let mut url = website(source, &format!("/post/popular_by_{}", scale(range)))?;
                url.query_pairs_mut()
                    .append_pair("year", &date.year().to_string())
                    .append_pair("month", &(date.month() as u8).to_string())
                    .append_pair("day", &date.day().to_string());
                url
            }
        }
        ProtocolFamily::Danbooru => {
            let range = request
                .range
                .ok_or_else(|| BooruError::invalid_request(Some(source.id)))?;
            let mut url = website(source, "/explore/posts/popular")?;
            url.query_pairs_mut().append_pair("scale", scale(range));
            // Omit date for a live recent feed; historical dates stay explicit.
            if let Some(date) = &request.date {
                url.query_pairs_mut().append_pair("date", date);
            }
            url
        }
        ProtocolFamily::Wallhaven => {
            let mut url = wallhaven_search(source, &request.ratings)?;
            let sorting = match request.kind {
                FeedKind::RecentPopular => "toplist",
                FeedKind::Random => "random",
                FeedKind::LifetimeViews => "views",
                FeedKind::LifetimeFavorites => "favorites",
                _ => return Err(BooruError::invalid_request(Some(source.id))),
            };
            url.query_pairs_mut().append_pair("sorting", sorting);
            if let Some(range) = request.range {
                url.query_pairs_mut()
                    .append_pair("topRange", period(range, true));
            }
            if let Some(seed) = &request.seed {
                url.query_pairs_mut().append_pair("seed", seed);
            }
            url
        }
        _ => return Err(crate::booru::discovery::unsupported(source.id)),
    };
    Ok(url.into())
}

fn website(source: &SourceDefinition, path: &str) -> BooruResult<Url> {
    Url::parse(source.web_base)
        .and_then(|url| url.join(path))
        .map_err(|_| BooruError::invalid_response(source.id))
}

fn wallhaven_search(source: &SourceDefinition, ratings: &[ContentRating]) -> BooruResult<Url> {
    let mut url = website(source, "/search")?;
    url.query_pairs_mut()
        .append_pair("categories", "010")
        .append_pair("purity", &wallhaven_purity_bits(ratings))
        .append_pair("order", "desc");
    Ok(url)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::booru_models::PopularRange;
    use crate::booru::error::BooruErrorCode;
    use crate::booru::source::builtin_sources;
    use std::collections::BTreeMap;

    fn source(id: &str) -> SourceDefinition {
        builtin_sources().into_iter().find(|s| s.id == id).unwrap()
    }
    fn search(id: &str) -> SearchRequest {
        SearchRequest {
            source_id: id.into(),
            query_text: "  sky 色彩 #blue & score:>10  ".into(),
            ratings: vec![],
            page_size: 30,
            cursor: Some("private-api-cursor".into()),
        }
    }
    fn feed(id: &str, kind: FeedKind, range: Option<PopularRange>) -> FeedRequest {
        FeedRequest {
            source_id: id.into(),
            kind,
            range,
            date: None,
            seed: None,
            ratings: vec![],
            page_size: 30,
            cursor: Some("private-api-cursor".into()),
        }
    }
    fn parts(raw: &str) -> (String, BTreeMap<String, String>) {
        let url = Url::parse(raw).unwrap();
        (
            url.path().into(),
            url.query_pairs()
                .map(|(k, v)| (k.into_owned(), v.into_owned()))
                .collect(),
        )
    }

    #[test]
    fn all_sources_use_website_origin_and_lossless_query_without_api_state() {
        for definition in builtin_sources() {
            let raw = search_url(&definition, &search(definition.id)).unwrap();
            let url = Url::parse(&raw).unwrap();
            assert_eq!(
                url.origin(),
                Url::parse(definition.web_base).unwrap().origin()
            );
            assert_eq!(url.username(), "");
            assert!(url.password().is_none() && url.fragment().is_none());
            assert!(!raw.contains("private-api-cursor") && !raw.contains("api_key"));
            let (_, params) = parts(&raw);
            let key = match definition.family {
                ProtocolFamily::Wallhaven => "q",
                ProtocolFamily::AnimePictures => "search_tag",
                _ => "tags",
            };
            assert_eq!(params[key], "sky 色彩 #blue & score:>10");
        }
    }
    #[test]
    fn latest_feeds_and_single_rating_keep_protocol_rules() {
        for definition in builtin_sources() {
            let request = feed(definition.id, FeedKind::Latest, None);
            assert!(feed_url(&definition, &request).is_ok());
        }
        let mut request = search("yande");
        request.ratings = vec![ContentRating::Questionable];
        assert!(
            parts(&search_url(&source("yande"), &request).unwrap()).1["tags"]
                .ends_with(" rating:q")
        );
        request = search("wallhaven");
        request.ratings = vec![ContentRating::Explicit];
        assert_eq!(
            parts(&search_url(&source("wallhaven"), &request).unwrap()).1["purity"],
            "001"
        );
    }
    #[test]
    fn moebooru_and_danbooru_keep_recent_and_historical_ranges() {
        let request = feed("yande", FeedKind::RecentPopular, Some(PopularRange::Year));
        assert_eq!(
            parts(&feed_url(&source("yande"), &request).unwrap()),
            (
                "/post/popular_recent".into(),
                BTreeMap::from([("period".into(), "1y".into())])
            )
        );
        for id in ["yande", "danbooru", "aibooru"] {
            let definition = source(id);
            for range in [PopularRange::Day, PopularRange::Week, PopularRange::Month] {
                let mut request = feed(id, FeedKind::HistoricalPopular, Some(range));
                request.date = Some("2026-10-15".into());
                let (path, params) = parts(&feed_url(&definition, &request).unwrap());
                if definition.family == ProtocolFamily::Moebooru {
                    assert_eq!(path, format!("/post/popular_by_{}", scale(range)));
                    assert_eq!(params["year"], "2026");
                    assert_eq!(params["month"], "10");
                    assert_eq!(params["day"], "15");
                } else {
                    assert_eq!(path, "/explore/posts/popular");
                    assert_eq!(params["date"], "2026-10-15");
                    assert_eq!(params["scale"], scale(range));
                }
            }
        }
    }
    #[test]
    fn wallhaven_keeps_all_ranges_sorting_and_explicit_random_seed() {
        let definition = source("wallhaven");
        for range in definition
            .capabilities
            .discovery
            .popular_ranges
            .iter()
            .copied()
        {
            let request = feed("wallhaven", FeedKind::RecentPopular, Some(range));
            let (_, params) = parts(&feed_url(&definition, &request).unwrap());
            assert_eq!(params["sorting"], "toplist");
            assert_eq!(params["topRange"], period(range, true));
        }
        for (kind, sorting) in [
            (FeedKind::Random, "random"),
            (FeedKind::LifetimeViews, "views"),
            (FeedKind::LifetimeFavorites, "favorites"),
        ] {
            let mut request = feed("wallhaven", kind, None);
            if kind == FeedKind::Random {
                request.seed = Some("ab1234".into());
            }
            let (_, params) = parts(&feed_url(&definition, &request).unwrap());
            assert_eq!(params["sorting"], sorting);
            if kind == FeedKind::Random {
                assert_eq!(params["seed"], "ab1234");
            }
        }
    }
    #[test]
    fn rejects_unsupported_modes_bad_dates_ranges_and_mismatched_sources() {
        let invalid = feed("gelbooru", FeedKind::RecentPopular, Some(PopularRange::Day));
        assert_eq!(
            feed_url(&source("gelbooru"), &invalid).unwrap_err().code,
            BooruErrorCode::UnsupportedCapability
        );
        let mut invalid = feed(
            "danbooru",
            FeedKind::HistoricalPopular,
            Some(PopularRange::Day),
        );
        invalid.date = Some("2026-02-30".into());
        assert!(feed_url(&source("danbooru"), &invalid).is_err());
        invalid.range = Some(PopularRange::Year);
        assert!(feed_url(&source("danbooru"), &invalid).is_err());
        assert!(search_url(&source("yande"), &search("wallhaven")).is_err());
        let mut invalid = search("yande");
        invalid.ratings = vec![ContentRating::Sensitive];
        assert!(search_url(&source("yande"), &invalid).is_err());
    }
}
