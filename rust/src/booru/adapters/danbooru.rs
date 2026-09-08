use crate::api::booru_auth::AuthState;
use crate::api::booru_models::{BooruTagSuggestion, ContentRating, MediaVariantKind, TagCategory};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::common::{
    boolean, media, parse_json, signed32, string, tag_list, unsigned, unsigned32, username,
    validate_media_hosts,
};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use crate::booru::model::{Post, PostFlags, PostId, PostPage, SearchQuery, Tag};
use crate::booru::network::{RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use async_trait::async_trait;
use serde_json::Value;

// Danbooru's `only` projection does not expand `*`: `*,uploader[name]`
// returns only the uploader association on both Danbooru and AIBooru.
// Keep every field consumed by parse_post explicit when adding associations.
const POST_FIELDS: &str = "id,image_width,image_height,file_ext,md5,preview_file_url,large_file_url,file_url,file_size,tag_string_artist,tag_string_copyright,tag_string_character,tag_string_general,tag_string_meta,rating,score,created_at,uploader[name],uploader_name,source,has_children,parent_id,status,is_deleted";

pub struct DanbooruAdapter {
    definition: SourceDefinition,
}

struct ParsedPostPage {
    items: Vec<Post>,
    raw_count: usize,
    last_id: Option<String>,
}

impl DanbooruAdapter {
    pub fn new(definition: SourceDefinition) -> Self {
        Self { definition }
    }

    fn parse_posts(&self, bytes: &[u8]) -> BooruResult<ParsedPostPage> {
        let json = parse_json(self.definition.id, bytes)?;
        let values = json
            .as_array()
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        let mut items = Vec::with_capacity(values.len());
        let mut last_id = None;
        for value in values {
            let id = string(value, "id")
                .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
            last_id = Some(id);
            if media_is_hidden(value) {
                continue;
            }
            items.push(self.parse_post(value)?);
        }
        Ok(ParsedPostPage {
            items,
            raw_count: values.len(),
            last_id,
        })
    }

    fn parse_post(&self, value: &Value) -> BooruResult<Post> {
        let id =
            string(value, "id").ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        let width = unsigned32(value, "image_width");
        let height = unsigned32(value, "image_height");
        let extension = string(value, "file_ext");
        let md5 = string(value, "md5");
        let mut variants = Vec::new();
        if let Some(media) = media(
            MediaVariantKind::Thumbnail,
            string(value, "preview_file_url"),
            None,
            None,
            None,
            None,
            None,
            None,
        ) {
            variants.push(media);
        }
        if let Some(media) = media(
            MediaVariantKind::Sample,
            string(value, "large_file_url"),
            None,
            None,
            None,
            None,
            None,
            None,
        ) {
            variants.push(media);
        }
        if let Some(media) = media(
            MediaVariantKind::Original,
            string(value, "file_url"),
            width,
            height,
            unsigned(value, "file_size"),
            extension,
            None,
            md5,
        ) {
            variants.push(media);
        }
        if variants.is_empty() {
            if !media_is_hidden(value) {
                return Err(BooruError::invalid_response(self.definition.id));
            }
            return Err(BooruError::new(
                BooruErrorCode::PermissionDenied,
                Some(self.definition.id),
                "booru.error.permissionDenied",
            ));
        }
        validate_media_hosts(&self.definition, &variants)?;
        let mut tags = Vec::new();
        append_tags(value, "tag_string_artist", TagCategory::Artist, &mut tags);
        append_tags(
            value,
            "tag_string_copyright",
            TagCategory::Copyright,
            &mut tags,
        );
        append_tags(
            value,
            "tag_string_character",
            TagCategory::Character,
            &mut tags,
        );
        append_tags(value, "tag_string_general", TagCategory::General, &mut tags);
        append_tags(value, "tag_string_meta", TagCategory::Meta, &mut tags);
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            id: PostId(id.clone()),
            web_url: Some(format!("{}/posts/{id}", self.definition.web_base)),
            rating: danbooru_rating(string(value, "rating").as_deref()),
            score: signed32(value, "score"),
            created_at_iso8601: string(value, "created_at"),
            author: username(value, "/uploader/name").or_else(|| username(value, "/uploader_name")),
            source_url: string(value, "source"),
            tags,
            media: variants,
            flags: PostFlags {
                has_children: boolean(value, "has_children"),
                parent_id: string(value, "parent_id").map(PostId),
                is_pending: string(value, "status").as_deref() == Some("pending"),
                is_deleted: boolean(value, "is_deleted")
                    || string(value, "status").as_deref() == Some("deleted"),
                is_ai_generated: self.definition.is_ai_source,
            },
        })
    }
}

#[async_trait]
impl BooruAdapter for DanbooruAdapter {
    fn definition(&self) -> &SourceDefinition {
        &self.definition
    }

    async fn search(&self, ctx: &RequestContext, query: SearchQuery) -> BooruResult<PostPage> {
        let limit = query.page_size.clamp(1, self.definition.max_page_size);
        let mut cursor = query.cursor.clone();
        let mut result = Vec::new();
        let mut exhausted = false;
        for _ in 0..3 {
            let url = reqwest::Url::parse(&format!("{}/posts.json", self.definition.api_base))
                .map_err(|_| BooruError::invalid_response(self.definition.id))?;
            let mut spec = RequestSpec::get(url, ResponseKind::Json);
            spec.query = vec![
                ("only".to_owned(), POST_FIELDS.to_owned()),
                ("tags".to_owned(), query.text.trim().to_owned()),
                (
                    "limit".to_owned(),
                    (limit as usize - result.len()).to_string(),
                ),
            ];
            if let Some(cursor_value) = cursor.as_deref() {
                validate_danbooru_cursor(cursor_value)?;
                spec.query
                    .push(("page".to_owned(), cursor_value.to_owned()));
            }
            let response = ctx.runtime.execute(&self.definition, spec).await?;
            let upstream = self.parse_posts(&response.body)?;
            if upstream.raw_count == 0 {
                exhausted = true;
                break;
            }
            cursor = upstream.last_id.map(|id| format!("b{id}"));
            let upstream_len = upstream.raw_count;
            let requested_count = limit as usize - result.len();
            for post in upstream.items {
                if rating_selected(post.rating, &query.ratings)
                    && !result.iter().any(|existing: &Post| existing.id == post.id)
                {
                    result.push(post);
                    if result.len() >= limit as usize {
                        break;
                    }
                }
            }
            if result.len() >= limit as usize {
                break;
            }
            if upstream_len < requested_count {
                exhausted = true;
                break;
            }
        }
        Ok(PostPage {
            items: result,
            next_cursor: (!exhausted).then_some(cursor).flatten(),
            exhausted,
        })
    }

    async fn feed(
        &self,
        ctx: &RequestContext,
        request: crate::api::booru_models::FeedRequest,
    ) -> BooruResult<PostPage> {
        use crate::api::booru_models::FeedKind;
        use crate::booru::discovery::{latest_query, scale, RankingCursor};
        if request.kind == FeedKind::Latest {
            return self.search(ctx, latest_query(request)).await;
        }
        if !matches!(
            request.kind,
            FeedKind::RecentPopular | FeedKind::HistoricalPopular
        ) {
            return Err(self.unsupported());
        }
        let cursor = RankingCursor::new(&request)?;
        let limit = request.page_size.min(self.definition.max_page_size);
        let url = reqwest::Url::parse(&format!(
            "{}/explore/posts/popular.json",
            self.definition.api_base
        ))
        .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("only".to_owned(), POST_FIELDS.to_owned()),
            ("scale".into(), scale(request.range.unwrap()).into()),
            ("date".into(), cursor.date.clone()),
            ("page".into(), cursor.page.to_string()),
            ("limit".into(), limit.to_string()),
        ];
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let parsed = self.parse_posts(&response.body)?;
        let exhausted = parsed.raw_count < limit as usize;
        let items = parsed
            .items
            .into_iter()
            .filter(|post| rating_selected(post.rating, &request.ratings))
            .collect();
        let next_cursor = if exhausted { None } else { cursor.next() };
        Ok(PostPage {
            items,
            exhausted: next_cursor.is_none(),
            next_cursor,
        })
    }

    async fn get_post(&self, ctx: &RequestContext, id: &PostId) -> BooruResult<Post> {
        validate_post_id(id)?;
        let url = reqwest::Url::parse(&format!("{}/posts/{}.json", self.definition.api_base, id.0))
            .map_err(|_| BooruError::invalid_request(Some(self.definition.id)))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query.push(("only".to_owned(), POST_FIELDS.to_owned()));
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let json = parse_json(self.definition.id, &response.body)?;
        self.parse_post(&json)
    }

    async fn autocomplete(
        &self,
        ctx: &RequestContext,
        text: &str,
    ) -> BooruResult<Vec<BooruTagSuggestion>> {
        let url = reqwest::Url::parse(&format!("{}/autocomplete.json", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("search[query]".to_owned(), text.trim().to_owned()),
            ("search[type]".to_owned(), "tag_query".to_owned()),
            ("limit".to_owned(), "20".to_owned()),
        ];
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let json = parse_json(self.definition.id, &response.body)?;
        let values = json
            .as_array()
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        Ok(values
            .iter()
            .filter_map(|item| {
                let value = string(item, "value")?;
                Some(BooruTagSuggestion {
                    label: string(item, "label").unwrap_or_else(|| value.clone()),
                    value,
                    category: TagCategory::General,
                    post_count_decimal: string(item, "post_count"),
                })
            })
            .collect())
    }

    async fn verify_auth(&self, ctx: &RequestContext) -> BooruResult<AuthState> {
        if ctx.runtime.auth_state(self.definition.id)?.status
            == crate::api::booru_auth::AuthStatus::NotConfigured
        {
            return Err(BooruError::new(
                BooruErrorCode::AuthenticationRequired,
                Some(self.definition.id),
                "booru.error.authenticationRequired",
            ));
        }
        let url = reqwest::Url::parse(&format!("{}/profile.json", self.definition.api_base))
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

fn append_tags(value: &Value, key: &str, category: TagCategory, output: &mut Vec<Tag>) {
    output.extend(tag_list(
        string(value, key).as_deref().unwrap_or_default(),
        category,
    ));
}

fn media_is_hidden(value: &Value) -> bool {
    // Danbooru omits file URLs for posts the current user cannot view,
    // including posts with none of the banned/deleted/pending flags set.
    ["preview_file_url", "large_file_url", "file_url"]
        .iter()
        .all(|key| {
            matches!(value.get(key), None | Some(Value::Null))
                || value.get(key).and_then(Value::as_str) == Some("")
        })
}

fn rating_selected(rating: ContentRating, selected: &[ContentRating]) -> bool {
    selected.is_empty() || selected.contains(&rating)
}

fn danbooru_rating(value: Option<&str>) -> ContentRating {
    match value.unwrap_or_default().to_ascii_lowercase().as_str() {
        "g" | "general" => ContentRating::General,
        "s" | "sensitive" => ContentRating::Sensitive,
        "q" | "questionable" => ContentRating::Questionable,
        "e" | "explicit" => ContentRating::Explicit,
        _ => ContentRating::Unknown,
    }
}

fn validate_danbooru_cursor(cursor: &str) -> BooruResult<()> {
    let valid = cursor
        .strip_prefix('b')
        .is_some_and(|value| !value.is_empty() && value.bytes().all(|byte| byte.is_ascii_digit()));
    if valid {
        Ok(())
    } else {
        Err(BooruError::invalid_request(None))
    }
}

fn validate_post_id(id: &PostId) -> BooruResult<()> {
    if !id.0.is_empty() && id.0.bytes().all(|byte| byte.is_ascii_digit()) {
        Ok(())
    } else {
        Err(BooruError::invalid_request(None))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::booru::source::builtin_sources;

    fn adapter(source_id: &str) -> DanbooruAdapter {
        DanbooruAdapter::new(
            builtin_sources()
                .into_iter()
                .find(|source| source.id == source_id)
                .unwrap(),
        )
    }

    #[tokio::test]
    #[ignore = "requires the public Danbooru and AIBooru APIs; JSON only"]
    async fn live_projected_posts_include_media_and_uploader() {
        rustls::crypto::ring::default_provider()
            .install_default()
            .ok();
        let client = reqwest::Client::builder()
            .user_agent("BooruFlow/0.10.0")
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .unwrap();
        for source_id in ["danbooru", "aibooru"] {
            let adapter = adapter(source_id);
            for path in ["/posts.json", "/explore/posts/popular.json"] {
                let mut url =
                    reqwest::Url::parse(&format!("{}{path}", adapter.definition.api_base)).unwrap();
                url.query_pairs_mut()
                    .append_pair("only", POST_FIELDS)
                    .append_pair("limit", "3");
                let bytes = client
                    .get(url)
                    .send()
                    .await
                    .unwrap()
                    .error_for_status()
                    .unwrap()
                    .bytes()
                    .await
                    .unwrap();
                let page = adapter
                    .parse_posts(&bytes)
                    .unwrap_or_else(|error| panic!("{source_id}{path}: {error}"));
                assert!(
                    !page.items.is_empty(),
                    "{source_id}{path}: no visible posts"
                );
                let post = &page.items[0];
                assert!(post.author.is_some(), "{source_id}{path}: missing uploader");
                let mut url = reqwest::Url::parse(&format!(
                    "{}/posts/{}.json",
                    adapter.definition.api_base, post.id.0
                ))
                .unwrap();
                url.query_pairs_mut().append_pair("only", POST_FIELDS);
                let bytes = client
                    .get(url)
                    .send()
                    .await
                    .unwrap()
                    .error_for_status()
                    .unwrap()
                    .bytes()
                    .await
                    .unwrap();
                let detail = adapter
                    .parse_post(&parse_json(source_id, &bytes).unwrap())
                    .unwrap();
                assert_eq!(detail.id, post.id);
                assert_eq!(detail.author, post.author);
                assert!(!detail.media.is_empty());
                eprintln!("{source_id}{path}: list and detail parsed with uploader and media");
            }
        }
    }

    #[test]
    fn preserves_source_username_in_api_model() {
        let fixture = serde_json::json!({"id":1,"file_url":"https://cdn.aibooru.online/a.jpg","uploader":{"name":" Alice "},"tag_string_artist":"someone_else"});
        let post = adapter("aibooru").parse_post(&fixture).unwrap();
        assert_eq!(post.author.as_deref(), Some("Alice"));
        assert_eq!(post.into_api().author.as_deref(), Some("Alice"));
    }
    #[test]
    fn parses_tag_categories_and_ai_flag() {
        let fixture = br#"[{"id":8123456,"rating":"e","score":12,"image_width":1200,"image_height":800,"file_size":99,"file_ext":"png","file_url":"https://cdn.aibooru.online/a.png","preview_file_url":"https://cdn.aibooru.online/p.jpg","tag_string_artist":"alice","tag_string_character":"miku","tag_string_copyright":"vocaloid","tag_string_general":"solo","tag_string_meta":"highres"}]"#;
        let posts = adapter("aibooru").parse_posts(fixture).unwrap().items;
        assert!(posts[0].flags.is_ai_generated);
        assert_eq!(posts[0].rating, ContentRating::Explicit);
        assert!(posts[0]
            .tags
            .iter()
            .any(|tag| tag.category == TagCategory::Artist));
    }

    #[test]
    fn cursor_is_opaque_and_validated() {
        assert!(validate_danbooru_cursor("b8123456").is_ok());
        assert!(validate_danbooru_cursor("2").is_err());
    }

    #[test]
    fn sensitive_rating_is_not_downgraded_to_general() {
        let posts = adapter("danbooru")
            .parse_posts(
                br#"[{"id":1,"rating":"s","preview_file_url":"https://cdn.donmai.us/p.jpg"}]"#,
            )
            .unwrap()
            .items;
        assert_eq!(posts[0].rating, ContentRating::Sensitive);
    }

    #[test]
    fn empty_and_invalid_list_fixtures_are_distinct() {
        assert!(adapter("danbooru")
            .parse_posts(b"[]")
            .unwrap()
            .items
            .is_empty());
        assert!(adapter("danbooru").parse_posts(b"not-json").is_err());
    }

    #[test]
    fn skips_banned_posts_with_hidden_media_without_losing_the_cursor() {
        let parsed = adapter("danbooru")
            .parse_posts(
                br#"[{"id":2,"is_banned":true},{"id":1,"preview_file_url":"https://cdn.donmai.us/p.jpg"}]"#,
            )
            .unwrap();
        assert_eq!(parsed.raw_count, 2);
        assert_eq!(parsed.last_id.as_deref(), Some("1"));
        assert_eq!(parsed.items.len(), 1);
        assert_eq!(parsed.items[0].id.0, "1");
    }

    #[test]
    fn skips_unflagged_hidden_posts_and_keeps_raw_pagination() {
        let parsed = adapter("danbooru")
            .parse_posts(br#"[{"id":12145229,"preview_file_url":"https://cdn.donmai.us/p.jpg"},{"id":12145228,"rating":"e","is_banned":false,"is_deleted":false,"is_pending":false,"media_asset":{}}]"#)
            .unwrap();
        assert_eq!(parsed.items.len(), 1);
        assert_eq!(parsed.raw_count, 2);
        assert_eq!(parsed.last_id.as_deref(), Some("12145228"));
    }

    #[test]
    fn all_hidden_page_keeps_cursor_and_detail_reports_access_denied() {
        let adapter = adapter("danbooru");
        let parsed = adapter
            .parse_posts(br#"[{"id":2},{"id":1,"file_url":null,"preview_file_url":""}]"#)
            .unwrap();
        assert!(parsed.items.is_empty());
        assert_eq!(parsed.raw_count, 2);
        assert_eq!(parsed.last_id.as_deref(), Some("1"));
        assert_eq!(
            adapter
                .parse_post(&serde_json::json!({"id":1}))
                .unwrap_err()
                .code,
            BooruErrorCode::PermissionDenied
        );
    }

    #[test]
    fn malformed_records_and_unsafe_media_are_not_silently_skipped() {
        let adapter = adapter("danbooru");
        for bytes in [
            br#"[{}]"#.as_slice(),
            br#"[null]"#,
            br#"[{"id":1,"file_url":123}]"#,
            br#"[{"id":1,"file_url":"https://example.com/p.jpg"}]"#,
        ] {
            assert!(adapter.parse_posts(bytes).is_err());
        }
    }
}
