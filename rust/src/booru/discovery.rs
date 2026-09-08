use crate::api::booru_models::*;
use crate::booru::adapter::RequestContext;
use crate::booru::adapters::common::{parse_json, string, unsigned};
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::model::SearchQuery;
use crate::booru::network::{RequestSpec, ResponseKind};
use crate::booru::source::{ProtocolFamily, SourceDefinition};
use serde::{Deserialize, Serialize};

pub fn unsupported_capabilities() -> DiscoveryCapabilities {
    DiscoveryCapabilities {
        popular: CapabilityAvailability::Unsupported,
        common_tags: CapabilityAvailability::Unsupported,
        popular_ranges: vec![],
        historical_ranges: vec![],
        time_basis: PopularTimeBasis::IndexTimeWindow,
        finite_popular_limit: None,
        additional_feeds: vec![],
        autocomplete_min_chars: 1,
    }
}

pub fn capabilities(source: &SourceDefinition) -> DiscoveryCapabilities {
    use CapabilityAvailability::*;
    use PopularRange::*;
    let mut caps = unsupported_capabilities();
    match source.family {
        ProtocolFamily::Moebooru => {
            caps.popular = Available;
            caps.common_tags = Available;
            caps.popular_ranges = vec![Day, Week, Month, Year];
            caps.historical_ranges = vec![Day, Week, Month];
            caps.finite_popular_limit = Some(40);
        }
        ProtocolFamily::Danbooru => {
            caps.popular = if source.is_ai_source {
                RequiresProbe
            } else {
                Available
            };
            caps.common_tags = caps.popular;
            caps.popular_ranges = vec![Day, Week, Month];
            caps.historical_ranges = vec![Day, Week, Month];
            caps.time_basis = PopularTimeBasis::CalendarUploadPeriod;
        }
        ProtocolFamily::Gelbooru => {
            caps.common_tags = RequiresProbe;
            caps.autocomplete_min_chars = 2;
        }
        ProtocolFamily::Wallhaven => {
            caps.popular = Available;
            caps.popular_ranges = vec![Day, ThreeDays, Week, Month, ThreeMonths, SixMonths, Year];
            caps.time_basis = PopularTimeBasis::SourceActivityWindow;
            caps.additional_feeds = vec![
                FeedKind::Random,
                FeedKind::LifetimeViews,
                FeedKind::LifetimeFavorites,
            ];
        }
        ProtocolFamily::AnimePictures => {}
    }
    caps
}

pub fn latest_query(request: FeedRequest) -> SearchQuery {
    SearchQuery {
        text: String::new(),
        ratings: request.ratings,
        page_size: request.page_size,
        cursor: request.cursor,
    }
}

/// An empty selection means all ratings available to this source/session.
/// Explicit selections retain their meaning, including authentication errors.
pub fn resolve_ratings(
    source: &SourceDefinition,
    selected: Vec<ContentRating>,
    authenticated: bool,
) -> Vec<ContentRating> {
    if !selected.is_empty() {
        return selected;
    }
    source
        .capabilities
        .ratings
        .iter()
        .copied()
        .filter(|rating| {
            !(source.family == ProtocolFamily::Wallhaven
                && !authenticated
                && *rating == ContentRating::Explicit)
        })
        .collect()
}

pub fn validate_feed(source: &SourceDefinition, request: &FeedRequest) -> BooruResult<()> {
    let invalid = || BooruError::invalid_request(Some(source.id));
    if request.page_size == 0
        || request
            .ratings
            .iter()
            .any(|r| !source.capabilities.ratings.contains(r))
    {
        return Err(invalid());
    }
    let caps = &source.capabilities.discovery;
    match request.kind {
        FeedKind::Latest => {
            if request.range.is_some() || request.date.is_some() || request.seed.is_some() {
                return Err(invalid());
            }
        }
        FeedKind::RecentPopular | FeedKind::HistoricalPopular => {
            if caps.popular == CapabilityAvailability::Unsupported {
                return Err(unsupported(source.id));
            }
            let ranges = if request.kind == FeedKind::HistoricalPopular {
                &caps.historical_ranges
            } else {
                &caps.popular_ranges
            };
            if !request.range.is_some_and(|r| ranges.contains(&r)) || request.seed.is_some() {
                return Err(invalid());
            }
            if request.kind == FeedKind::HistoricalPopular {
                parse_date(source.id, request.date.as_deref().ok_or_else(invalid)?)?;
            } else if request.date.is_some() {
                return Err(invalid());
            }
        }
        _ => {
            if !caps.additional_feeds.contains(&request.kind) {
                return Err(unsupported(source.id));
            }
            if request.range.is_some() || request.date.is_some() {
                return Err(invalid());
            }
            if let Some(seed) = &request.seed {
                if request.kind != FeedKind::Random
                    || seed.len() != 6
                    || !seed.bytes().all(|b| b.is_ascii_alphanumeric())
                {
                    return Err(invalid());
                }
            }
        }
    }
    Ok(())
}

pub fn unsupported(source: &str) -> BooruError {
    BooruError::new(
        crate::booru::error::BooruErrorCode::UnsupportedCapability,
        Some(source),
        "booru.error.unsupportedCapability",
    )
}

pub fn parse_date(source: &str, value: &str) -> BooruResult<time::Date> {
    let format =
        time::format_description::parse_borrowed::<2>("[year]-[month]-[day]").expect("date format");
    let date =
        time::Date::parse(value, &format).map_err(|_| BooruError::invalid_request(Some(source)))?;
    if date.to_string() != value {
        return Err(BooruError::invalid_request(Some(source)));
    }
    Ok(date)
}

pub fn period(range: PopularRange, wallhaven: bool) -> &'static str {
    match range {
        PopularRange::Day => "1d",
        PopularRange::ThreeDays => "3d",
        PopularRange::Week => "1w",
        PopularRange::Month if wallhaven => "1M",
        PopularRange::Month => "1m",
        PopularRange::ThreeMonths => "3M",
        PopularRange::SixMonths => "6M",
        PopularRange::Year => "1y",
    }
}

pub fn scale(range: PopularRange) -> &'static str {
    match range {
        PopularRange::Day => "day",
        PopularRange::Week => "week",
        _ => "month",
    }
}

#[derive(Serialize, Deserialize)]
pub struct RankingCursor {
    pub page: u32,
    pub date: String,
    source: String,
    kind: FeedKind,
    range: PopularRange,
    size: u32,
}

impl RankingCursor {
    pub fn new(request: &FeedRequest) -> BooruResult<Self> {
        if let Some(raw) = &request.cursor {
            let cursor: Self = serde_json::from_str(raw)
                .map_err(|_| BooruError::invalid_request(Some(&request.source_id)))?;
            if cursor.page == 0
                || cursor.source != request.source_id
                || cursor.kind != request.kind
                || Some(cursor.range) != request.range
                || cursor.size != request.page_size
                || request.date.as_ref().is_some_and(|d| *d != cursor.date)
            {
                return Err(BooruError::invalid_request(Some(&request.source_id)));
            }
            parse_date(&request.source_id, &cursor.date)?;
            return Ok(cursor);
        }
        Ok(Self {
            page: 1,
            // Danbooru's server calendar is UTC. Keep the date across pagination.
            date: request
                .date
                .clone()
                .unwrap_or_else(|| time::OffsetDateTime::now_utc().date().to_string()),
            source: request.source_id.clone(),
            kind: request.kind,
            range: request
                .range
                .ok_or_else(|| BooruError::invalid_request(Some(&request.source_id)))?,
            size: request.page_size,
        })
    }
    pub fn next(mut self) -> Option<String> {
        self.page = self.page.checked_add(1)?;
        serde_json::to_string(&self).ok()
    }
}

pub async fn tags(
    ctx: &RequestContext,
    source: &SourceDefinition,
    prefix: Option<&str>,
    page: u32,
    limit: u32,
) -> BooruResult<CommonTagsPage> {
    if page == 0 || limit == 0 || limit > 100 {
        return Err(BooruError::invalid_request(Some(source.id)));
    }
    let spec = tag_request(source, prefix, page, limit)?;
    // Never reuse the empty-autocomplete path for recommendations.
    let response = ctx.runtime.execute(source, spec).await?;
    let json = parse_json(source.id, &response.body)?;
    let values = json
        .as_array()
        .or_else(|| json.get("tag").and_then(serde_json::Value::as_array))
        .ok_or_else(|| BooruError::invalid_response(source.id))?;
    let items = values
        .iter()
        .map(|value| {
            let name =
                string(value, "name").ok_or_else(|| BooruError::invalid_response(source.id))?;
            let category = match unsigned(value, "category").or_else(|| unsigned(value, "type")) {
                Some(1) => TagCategory::Artist,
                Some(3) => TagCategory::Copyright,
                Some(4) => TagCategory::Character,
                Some(5) => TagCategory::Meta,
                _ => TagCategory::General,
            };
            Ok(BooruTagSuggestion {
                value: name.clone(),
                label: name,
                category,
                post_count_decimal: string(value, "post_count").or_else(|| string(value, "count")),
            })
        })
        .collect::<BooruResult<Vec<_>>>()?;
    Ok(CommonTagsPage {
        next_page: if items.len() >= limit as usize {
            page.checked_add(1)
        } else {
            None
        },
        items,
    })
}

pub fn tag_request(
    source: &SourceDefinition,
    prefix: Option<&str>,
    page: u32,
    limit: u32,
) -> BooruResult<RequestSpec> {
    let (path, mut query) = match source.family {
        ProtocolFamily::Moebooru => (
            "/tag.json",
            vec![
                ("order".into(), "count".into()),
                ("page".into(), page.to_string()),
            ],
        ),
        ProtocolFamily::Danbooru => (
            "/tags.json",
            vec![
                ("search[order]".into(), "count".into()),
                ("page".into(), page.to_string()),
            ],
        ),
        ProtocolFamily::Gelbooru => (
            "/index.php",
            vec![
                ("page".into(), "dapi".into()),
                ("s".into(), "tag".into()),
                ("q".into(), "index".into()),
                ("json".into(), "1".into()),
                ("orderby".into(), "count".into()),
                ("order".into(), "DESC".into()),
                ("pid".into(), (page - 1).to_string()),
            ],
        ),
        _ => return Err(unsupported(source.id)),
    };
    query.push(("limit".into(), limit.to_string()));
    if let Some(prefix) = prefix {
        let key = match source.family {
            ProtocolFamily::Moebooru => "name",
            ProtocolFamily::Danbooru => "search[name_matches]",
            _ => "name_pattern",
        };
        query.push((key.into(), format!("{prefix}*")));
    }
    let url = reqwest::Url::parse(&format!("{}{path}", source.api_base))
        .map_err(|_| BooruError::invalid_response(source.id))?;
    let mut spec = RequestSpec::get(url, ResponseKind::Json);
    spec.query = query;
    Ok(spec)
}

#[cfg(test)]
mod tests {
    use super::*;
    fn request(source: &str) -> FeedRequest {
        FeedRequest {
            source_id: source.into(),
            kind: FeedKind::RecentPopular,
            range: Some(PopularRange::Day),
            date: None,
            seed: None,
            ratings: vec![ContentRating::General],
            page_size: 40,
            cursor: None,
        }
    }
    #[test]
    fn source_capabilities_and_validation_agree() {
        for source in crate::booru::source::builtin_sources() {
            assert_eq!(
                validate_feed(&source, &request(source.id)).is_ok(),
                source.capabilities.discovery.popular != CapabilityAvailability::Unsupported
            );
        }
    }
    #[test]
    fn dates_and_irrelevant_fields_are_rejected() {
        assert!(parse_date("danbooru", "2026-02-29").is_err());
        assert!(parse_date("danbooru", "2024-02-29").is_ok());
        let source = crate::booru::source::builtin_sources().remove(0);
        let mut req = request(source.id);
        req.kind = FeedKind::Latest;
        assert!(validate_feed(&source, &req).is_err());
        req.range = None;
        assert!(validate_feed(&source, &req).is_ok());
        req.ratings.clear();
        assert!(validate_feed(&source, &req).is_ok());
    }
    #[test]
    fn default_ratings_cover_each_source_without_requesting_anonymous_nsfw() {
        for source in crate::booru::source::builtin_sources() {
            let ratings = resolve_ratings(&source, vec![], false);
            assert!(!ratings.is_empty(), "{}", source.id);
            if source.family == ProtocolFamily::Wallhaven {
                assert_eq!(
                    ratings,
                    vec![ContentRating::General, ContentRating::Sensitive]
                );
                assert!(resolve_ratings(&source, vec![], true).contains(&ContentRating::Explicit));
                assert_eq!(
                    resolve_ratings(&source, vec![ContentRating::Explicit], false),
                    vec![ContentRating::Explicit]
                );
            } else {
                assert_eq!(ratings, source.capabilities.ratings);
            }
        }
    }
    #[test]
    fn ranking_cursor_pins_date_and_rejects_other_queries() {
        let mut req = request("danbooru");
        let cursor = RankingCursor::new(&req).unwrap();
        let date = cursor.date.clone();
        req.cursor = cursor.next();
        let next = RankingCursor::new(&req).unwrap();
        assert_eq!(next.page, 2);
        assert_eq!(next.date, date);
        req.range = Some(PopularRange::Month);
        assert!(RankingCursor::new(&req).is_err());
    }
    #[test]
    fn common_tags_have_separate_parameters() {
        for source in crate::booru::source::builtin_sources().into_iter().take(5) {
            let spec = tag_request(&source, None, 1, 12).unwrap();
            assert!(!spec.query.iter().any(|(_, value)| value.contains('*')));
        }
        assert_eq!(period(PopularRange::Month, false), "1m");
        assert_eq!(period(PopularRange::Month, true), "1M");
    }
}
