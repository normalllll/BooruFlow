use crate::api::booru_models::{ContentRating, FeedKind, FeedRequest, SearchRequest};
use crate::booru::adapters::common::with_sort_tag;
use crate::booru::adapters::{anime_pictures, danbooru, gelbooru, moebooru, wallhaven};
use crate::booru::discovery::{
    parse_date, period, scale, validate_feed, validate_search_sort, wallhaven_purity_bits,
};
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
    validate_search_sort(source, request.sort)?;
    let query = request.query_text.trim();
    let mut url = match source.family {
        ProtocolFamily::Moebooru => {
            let mut url = website(source, "/post")?;
            let mut tags = with_sort_tag(query, moebooru::order_tag(request.sort)?, "order:");
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
            let tags = with_sort_tag(query, danbooru::order_tag(request.sort)?, "order:");
            if !tags.is_empty() {
                url.query_pairs_mut().append_pair("tags", &tags);
            }
            url
        }
        ProtocolFamily::Gelbooru => {
            let mut url = website(source, "/index.php")?;
            let tags = with_sort_tag(
                query,
                gelbooru::sort_tag(request.sort, None)?.as_deref(),
                "sort:",
            );
            url.query_pairs_mut()
                .append_pair("page", "post")
                .append_pair("s", "list")
                .append_pair("tags", if tags.is_empty() { "all" } else { &tags });
            url
        }
        ProtocolFamily::Wallhaven => {
            let (sorting, order) = wallhaven::sorting(request.sort)?;
            let mut url = wallhaven_search(source, &request.ratings)?;
            url.query_pairs_mut()
                .append_pair("sorting", sorting)
                .append_pair("order", order);
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
            if let Some(order_by) = anime_pictures::order_by(request.sort)? {
                url.query_pairs_mut().append_pair("order_by", order_by);
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
    if request.kind == FeedKind::All {
        return search_url(
            source,
            &SearchRequest {
                source_id: request.source_id.clone(),
                query_text: String::new(),
                sort: request.sort.unwrap_or_default(),
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
            if request.kind != FeedKind::RecentPopular {
                return Err(BooruError::invalid_request(Some(source.id)));
            }
            let mut url = wallhaven_search(source, &request.ratings)?;
            url.query_pairs_mut()
                .append_pair("sorting", "toplist")
                .append_pair("order", "desc");
            if let Some(range) = request.range {
                url.query_pairs_mut()
                    .append_pair("topRange", period(range, true));
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
        .append_pair("purity", &wallhaven_purity_bits(ratings));
    Ok(url)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::booru_models::{PopularRange, SortOrder};
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
            sort: SortOrder::Latest,
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
            sort: (kind == FeedKind::All).then_some(SortOrder::Latest),
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
            let request = feed(definition.id, FeedKind::All, None);
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
    fn wallhaven_keeps_all_popular_ranges() {
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
    }
    #[test]
    fn every_declared_sort_reaches_the_search_and_feed_links() {
        for definition in builtin_sources() {
            let tags_key = match definition.family {
                ProtocolFamily::Wallhaven => "q",
                ProtocolFamily::AnimePictures => "search_tag",
                ProtocolFamily::Gelbooru | ProtocolFamily::Danbooru | ProtocolFamily::Moebooru => {
                    "tags"
                }
            };
            let mut distinct = std::collections::BTreeSet::new();
            for option in &definition.capabilities.sorts.search {
                let mut request = search(definition.id);
                request.sort = option.order;
                let (_, params) = parts(&search_url(&definition, &request).unwrap());
                assert_eq!(params[tags_key].split(' ').next(), Some("sky"));
                let sorting = match definition.family {
                    ProtocolFamily::Wallhaven => {
                        format!("{}/{}", params["sorting"], params["order"])
                    }
                    ProtocolFamily::AnimePictures => {
                        params.get("order_by").cloned().unwrap_or_default()
                    }
                    _ => params[tags_key].replace("sky 色彩 #blue & score:>10", ""),
                };
                assert!(
                    distinct.insert(sorting.clone()),
                    "{} {:?} repeats another sort",
                    definition.id,
                    option.order
                );
            }
            for option in &definition.capabilities.sorts.feed {
                let mut request = feed(definition.id, FeedKind::All, None);
                request.sort = Some(option.order);
                assert!(feed_url(&definition, &request).is_ok());
            }
        }
    }
    #[test]
    fn sort_parameters_follow_each_protocol() {
        let link = |id: &str, sort: SortOrder| {
            let mut request = search(id);
            request.sort = sort;
            parts(&search_url(&source(id), &request).unwrap()).1
        };
        assert_eq!(
            link("danbooru", SortOrder::Hot)["tags"],
            "sky 色彩 #blue & score:>10 order:rank"
        );
        assert_eq!(
            link("yande", SortOrder::Oldest)["tags"],
            "sky 色彩 #blue & score:>10 order:id"
        );
        assert_eq!(
            link("gelbooru", SortOrder::Score)["tags"],
            "sky 色彩 #blue & score:>10 sort:score:desc"
        );
        let wallhaven = link("wallhaven", SortOrder::Oldest);
        assert_eq!(
            (wallhaven["sorting"].as_str(), wallhaven["order"].as_str()),
            ("date_added", "asc")
        );
        assert_eq!(link("wallhaven", SortOrder::Views)["sorting"], "views");
        assert_eq!(
            link("anime_pictures", SortOrder::TagCount)["order_by"],
            "tag_num"
        );
        assert!(!link("anime_pictures", SortOrder::Latest).contains_key("order_by"));
        let user_sorted = |id: &str, text: &str| {
            let mut request = search(id);
            request.query_text = text.into();
            request.sort = SortOrder::Score;
            parts(&search_url(&source(id), &request).unwrap()).1["tags"].clone()
        };
        assert_eq!(
            user_sorted("danbooru", "sky order:views"),
            "sky order:views"
        );
        assert_eq!(
            user_sorted("gelbooru", "sky sort:id:asc"),
            "sky sort:id:asc"
        );
        let mut request = feed("gelbooru", FeedKind::All, None);
        request.sort = Some(SortOrder::Updated);
        assert_eq!(
            parts(&feed_url(&source("gelbooru"), &request).unwrap()).1["tags"],
            "sort:updated:desc"
        );
        let mut request = search("yande");
        request.sort = SortOrder::Hot;
        assert!(search_url(&source("yande"), &request).is_err());
        let mut request = feed("wallhaven", FeedKind::All, None);
        request.sort = Some(SortOrder::Relevance);
        assert!(feed_url(&source("wallhaven"), &request).is_err());
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
