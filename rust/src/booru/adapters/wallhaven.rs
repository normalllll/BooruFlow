use crate::api::booru_auth::{AuthState, AuthStatus};
use crate::api::booru_models::{
    ContentRating, MediaType, MediaVariantKind, SortOrder, TagCategory,
};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::common::{
    media, parse_json, rating, signed32, source_time, string, tag_list, unsigned, unsigned32,
    username, validate_media_hosts,
};
use crate::booru::discovery::wallhaven_purity_bits;
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use crate::booru::model::{Post, PostFlags, PostId, PostPage, SearchQuery, Tag};
use crate::booru::network::{RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use async_trait::async_trait;
use serde_json::Value;

pub struct WallhavenAdapter {
    definition: SourceDefinition,
}

impl WallhavenAdapter {
    pub fn new(definition: SourceDefinition) -> Self {
        Self { definition }
    }

    fn parse_post(&self, value: &Value) -> BooruResult<Post> {
        let id =
            string(value, "id").ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        if !id
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-')
        {
            return Err(BooruError::invalid_response(self.definition.id));
        }
        let width = unsigned32(value, "dimension_x");
        let height = unsigned32(value, "dimension_y");
        let mut variants = Vec::new();
        // The `small` and `large` thumbs are cropped to a fixed ratio; only the
        // `original` thumb keeps the wallpaper's shape.
        if let Some(item) = media(
            MediaVariantKind::Preview,
            value
                .get("thumbs")
                .and_then(|thumbs| string(thumbs, "original")),
            None,
            None,
            None,
            None,
            None,
            None,
        ) {
            variants.push(item);
        }
        if let Some(item) = media(
            MediaVariantKind::Original,
            string(value, "path"),
            width,
            height,
            unsigned(value, "file_size"),
            None,
            string(value, "file_type").and_then(|value| MediaType::from_mime(&value)),
            None,
        ) {
            variants.push(item);
        }
        if variants.is_empty() {
            return Err(BooruError::invalid_response(self.definition.id));
        }
        validate_media_hosts(&self.definition, &variants)?;
        let tags = value
            .get("tags")
            .and_then(Value::as_array)
            .map(|tags| {
                tags.iter()
                    .filter_map(|tag| {
                        string(tag, "name").map(|name| Tag {
                            name,
                            category: TagCategory::General,
                        })
                    })
                    .collect()
            })
            .unwrap_or_else(|| {
                tag_list(
                    string(value, "tags").as_deref().unwrap_or_default(),
                    TagCategory::General,
                )
            });
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            original_file_size: unsigned(value, "file_size"),
            original_file_extension: string(value, "file_ext"),
            original_checksum: None,
            width,
            height,
            id: PostId(id.clone()),
            web_url: string(value, "url")
                .or_else(|| Some(format!("{}/w/{id}", self.definition.web_base))),
            rating: rating(string(value, "purity").as_deref()),
            score: signed32(value, "favorites"),
            created_at_iso8601: source_time(string(value, "created_at")),
            author: username(value, "/uploader/username"),
            source_url: string(value, "source"),
            tags,
            media: variants,
            flags: PostFlags::default(),
        })
    }

    fn list_request(
        &self,
        query: &SearchQuery,
        page: u32,
        seed: Option<&str>,
    ) -> BooruResult<RequestSpec> {
        let (sorting, order) = sorting(query.sort)?;
        let url = reqwest::Url::parse(&format!("{}/search", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("sorting".to_owned(), sorting.to_owned()),
            ("order".to_owned(), order.to_owned()),
            ("q".to_owned(), query.text.trim().to_owned()),
            ("categories".to_owned(), "010".to_owned()),
            ("purity".to_owned(), wallhaven_purity_bits(&query.ratings)),
            ("page".to_owned(), page.to_string()),
        ];
        if let Some(seed) = seed {
            spec.query.push(("seed".to_owned(), seed.to_owned()));
        }
        Ok(spec)
    }

    fn parse_listing(&self, bytes: &[u8]) -> BooruResult<(Vec<Post>, u32, u32, Option<String>)> {
        let json = parse_json(self.definition.id, bytes)?;
        let values = json
            .get("data")
            .and_then(Value::as_array)
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        let meta = json
            .get("meta")
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        let current = unsigned32(meta, "current_page").unwrap_or(1);
        let last = unsigned32(meta, "last_page").unwrap_or(current);
        let seed = string(meta, "seed");
        let posts = values
            .iter()
            .map(|value| self.parse_post(value))
            .collect::<BooruResult<Vec<_>>>()?;
        Ok((posts, current, last, seed))
    }
}

#[async_trait]
impl BooruAdapter for WallhavenAdapter {
    fn definition(&self) -> &SourceDefinition {
        &self.definition
    }

    async fn search(&self, ctx: &RequestContext, query: SearchQuery) -> BooruResult<PostPage> {
        if query.ratings.contains(&ContentRating::Explicit)
            && ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured
        {
            return Err(BooruError::new(
                BooruErrorCode::AuthenticationRequired,
                Some(self.definition.id),
                "booru.error.authenticationRequired",
            ));
        }
        let (page, seed) = parse_cursor(query.cursor.as_deref())?;
        let spec = self.list_request(&query, page, seed.as_deref())?;
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let (items, current, last, response_seed) = self.parse_listing(&response.body)?;
        // Random pages are only reproducible with the seed the first page returns.
        let seed = response_seed.or(seed);
        if query.sort == SortOrder::Random && seed.is_none() {
            return Err(BooruError::invalid_response(self.definition.id));
        }
        let exhausted = current >= last || items.is_empty() || current == u32::MAX;
        Ok(PostPage {
            items,
            next_cursor: (!exhausted).then(|| format_cursor(current + 1, seed.as_deref())),
            exhausted,
        })
    }

    async fn feed(
        &self,
        ctx: &RequestContext,
        request: crate::api::booru_models::FeedRequest,
    ) -> BooruResult<PostPage> {
        use crate::api::booru_models::FeedKind;
        match request.kind {
            FeedKind::All => {
                return self
                    .search(ctx, crate::booru::discovery::all_query(request))
                    .await;
            }
            FeedKind::RecentPopular => {}
            FeedKind::HistoricalPopular => return Err(self.unsupported()),
        }
        if request.ratings.contains(&ContentRating::Explicit)
            && ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured
        {
            return Err(BooruError::new(
                BooruErrorCode::AuthenticationRequired,
                Some(self.definition.id),
                "booru.error.authenticationRequired",
            ));
        }
        let (page, _) = parse_cursor(request.cursor.as_deref())?;
        let url = reqwest::Url::parse(&format!("{}/search", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("sorting".into(), "toplist".into()),
            ("order".into(), "desc".into()),
            ("categories".into(), "010".into()),
            ("purity".into(), wallhaven_purity_bits(&request.ratings)),
            ("page".into(), page.to_string()),
        ];
        if let Some(range) = request.range {
            spec.query.push((
                "topRange".into(),
                crate::booru::discovery::period(range, true).into(),
            ));
        }
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let (items, current, last, _) = self.parse_listing(&response.body)?;
        let exhausted = current >= last || items.is_empty() || current == u32::MAX;
        Ok(PostPage {
            items,
            next_cursor: (!exhausted).then(|| format_cursor(current + 1, None)),
            exhausted,
        })
    }

    async fn get_post(&self, ctx: &RequestContext, id: &PostId) -> BooruResult<Post> {
        if id.0.is_empty()
            || !id
                .0
                .bytes()
                .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-')
        {
            return Err(BooruError::invalid_request(Some(self.definition.id)));
        }
        let url = reqwest::Url::parse(&format!("{}/w/{}", self.definition.api_base, id.0))
            .map_err(|_| BooruError::invalid_request(Some(self.definition.id)))?;
        let response = ctx
            .runtime
            .execute(&self.definition, RequestSpec::get(url, ResponseKind::Json))
            .await?;
        let json = parse_json(self.definition.id, &response.body)?;
        let data = json
            .get("data")
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        self.parse_post(data)
    }

    async fn verify_auth(&self, ctx: &RequestContext) -> BooruResult<AuthState> {
        if ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured {
            return Err(BooruError::new(
                BooruErrorCode::AuthenticationRequired,
                Some(self.definition.id),
                "booru.error.authenticationRequired",
            ));
        }
        let url = reqwest::Url::parse(&format!("{}/settings", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        match ctx
            .runtime
            .execute(&self.definition, RequestSpec::get(url, ResponseKind::Json))
            .await
        {
            Ok(_) => ctx.runtime.mark_auth_verified(self.definition.id),
            Err(error) if error.code == BooruErrorCode::AuthenticationRejected => {
                let _ = ctx.runtime.mark_auth_rejected(self.definition.id);
                Err(error)
            }
            Err(error) => Err(error),
        }
    }
}

/// The `sorting` and `order` parameters for a sort.
pub fn sorting(sort: SortOrder) -> BooruResult<(&'static str, &'static str)> {
    Ok(match sort {
        SortOrder::Latest => ("date_added", "desc"),
        SortOrder::Oldest => ("date_added", "asc"),
        SortOrder::Relevance => ("relevance", "desc"),
        SortOrder::Hot => ("hot", "desc"),
        SortOrder::Views => ("views", "desc"),
        SortOrder::Favorites => ("favorites", "desc"),
        SortOrder::Random => ("random", "desc"),
        _ => return Err(BooruError::invalid_request(Some("wallhaven"))),
    })
}

fn parse_cursor(cursor: Option<&str>) -> BooruResult<(u32, Option<String>)> {
    let Some(cursor) = cursor else {
        return Ok((1, None));
    };
    let mut parts = cursor.splitn(2, ':');
    let page = parts
        .next()
        .and_then(|value| value.parse::<u32>().ok())
        .filter(|page| *page > 0)
        .ok_or_else(|| BooruError::invalid_request(Some("wallhaven")))?;
    let seed = parts
        .next()
        .filter(|value| !value.is_empty())
        .map(str::to_owned);
    if seed
        .as_deref()
        .is_some_and(|seed| !seed.bytes().all(|byte| byte.is_ascii_alphanumeric()))
    {
        return Err(BooruError::invalid_request(Some("wallhaven")));
    }
    Ok((page, seed))
}

fn format_cursor(page: u32, seed: Option<&str>) -> String {
    match seed {
        Some(seed) => format!("{page}:{seed}"),
        None => page.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::booru::source::builtin_sources;

    fn adapter() -> WallhavenAdapter {
        WallhavenAdapter::new(
            builtin_sources()
                .into_iter()
                .find(|source| source.id == "wallhaven")
                .unwrap(),
        )
    }

    #[test]
    fn list_requests_carry_sorting_order_page_and_seed() {
        let query = |sort, text: &str| SearchQuery {
            text: text.into(),
            sort,
            ratings: vec![ContentRating::General],
            page_size: 24,
            cursor: None,
        };
        let params = |sort, seed| {
            adapter()
                .list_request(&query(sort, "sky"), 2, seed)
                .unwrap()
                .query
                .into_iter()
                .collect::<std::collections::BTreeMap<_, _>>()
        };
        let latest = params(SortOrder::Latest, None);
        assert_eq!(latest["sorting"], "date_added");
        assert_eq!(latest["order"], "desc");
        assert_eq!(latest["q"], "sky");
        assert_eq!(latest["page"], "2");
        assert!(!latest.contains_key("seed"));
        let oldest = params(SortOrder::Oldest, None);
        assert_eq!(
            (oldest["sorting"].as_str(), oldest["order"].as_str()),
            ("date_added", "asc")
        );
        for (sort, sorting) in [
            (SortOrder::Relevance, "relevance"),
            (SortOrder::Hot, "hot"),
            (SortOrder::Views, "views"),
            (SortOrder::Favorites, "favorites"),
            (SortOrder::Random, "random"),
        ] {
            assert_eq!(params(sort, None)["sorting"], sorting);
        }
        assert_eq!(params(SortOrder::Random, Some("abc123"))["seed"], "abc123");
    }

    #[test]
    fn preserves_source_username_in_api_model() {
        let fixture = serde_json::json!({"id":"94x38z","path":"https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg","uploader":{"username":" Alice "}});
        let post = adapter().parse_post(&fixture).unwrap();
        assert_eq!(post.author.as_deref(), Some("Alice"));
        assert_eq!(post.into_api().author.as_deref(), Some("Alice"));
    }
    #[test]
    fn parses_alphanumeric_id_and_pagination_seed() {
        let fixture = br#"{"data":[{"id":"94x38z","url":"https://wallhaven.cc/w/94x38z","purity":"sketchy","dimension_x":1920,"dimension_y":1080,"file_size":123,"file_type":"image/jpeg","path":"https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg","thumbs":{"large":"https://th.wallhaven.cc/lg/94/94x38z.jpg","original":"https://th.wallhaven.cc/orig/94/94x38z.jpg","small":"https://th.wallhaven.cc/small/94/94x38z.jpg"}}],"meta":{"current_page":1,"last_page":2,"seed":"abc123"}}"#;
        let (posts, current, last, seed) = adapter().parse_listing(fixture).unwrap();
        assert_eq!(posts[0].id.0, "94x38z");
        assert_eq!(posts[0].rating, ContentRating::Sensitive);
        assert_eq!((current, last, seed.as_deref()), (1, 2, Some("abc123")));
        let post = posts.into_iter().next().unwrap().into_api();
        assert_eq!((post.width, post.height), (Some(1920), Some(1080)));
        assert_eq!(post.original_file_size_decimal.as_deref(), Some("123"));
        assert_eq!(post.original_file_extension.as_deref(), Some("jpg"));
        assert_eq!(post.media.len(), 2);
        assert_eq!(
            post.media[0].url,
            "https://th.wallhaven.cc/orig/94/94x38z.jpg"
        );
        assert_eq!(post.media[0].width, None);
        assert_eq!(post.media[1].media_type, Some(MediaType::Jpeg));
    }

    #[test]
    fn purity_mapping_combines_sensitive_and_questionable() {
        assert_eq!(wallhaven_purity_bits(&[]), "110");
        assert_eq!(
            wallhaven_purity_bits(&[ContentRating::Questionable, ContentRating::Explicit]),
            "011"
        );
    }

    #[test]
    fn each_declared_sort_maps_to_sorting_and_order() {
        let source = adapter();
        for option in source
            .definition
            .capabilities
            .sorts
            .search
            .iter()
            .chain(&source.definition.capabilities.sorts.feed)
        {
            assert!(sorting(option.order).is_ok(), "{:?}", option.order);
        }
        assert_eq!(sorting(SortOrder::Latest).unwrap(), ("date_added", "desc"));
        assert_eq!(sorting(SortOrder::Oldest).unwrap(), ("date_added", "asc"));
        assert_eq!(sorting(SortOrder::Hot).unwrap().0, "hot");
        assert!(sorting(SortOrder::Score).is_err());
    }

    #[test]
    fn random_cursor_keeps_the_seed_between_pages() {
        assert_eq!(format_cursor(2, Some("abc123")), "2:abc123");
        assert_eq!(
            parse_cursor(Some("2:abc123")).unwrap(),
            (2, Some("abc123".into()))
        );
        assert_eq!(parse_cursor(Some("3")).unwrap(), (3, None));
    }

    #[test]
    fn cursor_rejects_unsafe_seed() {
        assert!(parse_cursor(Some("2:abc123")).is_ok());
        assert!(parse_cursor(Some("2:../bad")).is_err());
    }

    #[test]
    fn empty_and_invalid_list_fixtures_are_distinct() {
        let (posts, current, last, _) = adapter()
            .parse_listing(br#"{"data":[],"meta":{"current_page":1,"last_page":1}}"#)
            .unwrap();
        assert!(posts.is_empty());
        assert_eq!((current, last), (1, 1));
        assert!(adapter().parse_listing(b"not-json").is_err());
    }
}
