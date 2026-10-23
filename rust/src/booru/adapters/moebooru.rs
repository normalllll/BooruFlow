use crate::api::booru_models::{
    BooruTagSuggestion, ContentRating, MediaType, MediaVariantKind, TagCategory,
};
#[cfg(test)]
use crate::api::booru_models::{Checksum, ChecksumAlgorithm};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::common::{
    boolean, md5_checksum, media, parent_id, parse_json, rating, signed32, string, tag_list,
    unix_to_iso8601, unsigned, unsigned32, username, validate_media_hosts,
};
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::model::{Post, PostFlags, PostId, PostPage, SearchQuery};
use crate::booru::network::{RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use async_trait::async_trait;
use serde_json::Value;
use std::collections::BTreeSet;

pub struct MoebooruAdapter {
    definition: SourceDefinition,
}

impl MoebooruAdapter {
    pub fn new(definition: SourceDefinition) -> Self {
        Self { definition }
    }

    fn parse_posts(&self, bytes: &[u8]) -> BooruResult<Vec<Post>> {
        let json = parse_json(self.definition.id, bytes)?;
        // API v2 includes all category names in the same response. Keep v1
        // array decoding for popular endpoints and older compatible servers.
        let items = json
            .get("posts")
            .unwrap_or(&json)
            .as_array()
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        items
            .iter()
            .map(|value| {
                let mut post = self.parse_post(value)?;
                if let Some(categories) = json.get("tags").and_then(Value::as_object) {
                    for tag in &mut post.tags {
                        if let Some(category) = categories.get(&tag.name).and_then(Value::as_str) {
                            tag.category = match category {
                                "artist" => TagCategory::Artist,
                                "copyright" => TagCategory::Copyright,
                                "character" => TagCategory::Character,
                                "meta" => TagCategory::Meta,
                                _ => TagCategory::General,
                            };
                        }
                    }
                }
                Ok(post)
            })
            .collect()
    }

    fn parse_post(&self, value: &Value) -> BooruResult<Post> {
        let id =
            string(value, "id").ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        let md5 = string(value, "md5");
        let file_ext = string(value, "file_ext");
        let mut variants = Vec::new();
        // preview_* is the website's CSS size; actual_preview_* describes
        // the file. Select a complete pair rather than combining both sizes.
        let (preview_width, preview_height) = match (
            unsigned32(value, "actual_preview_width"),
            unsigned32(value, "actual_preview_height"),
        ) {
            (Some(width), Some(height)) if width > 0 && height > 0 => (Some(width), Some(height)),
            _ => (
                unsigned32(value, "preview_width"),
                unsigned32(value, "preview_height"),
            ),
        };
        if let Some(value) = media(
            MediaVariantKind::Thumbnail,
            string(value, "preview_url"),
            preview_width,
            preview_height,
            None,
            None,
            None,
            None,
        ) {
            variants.push(value);
        }
        if let Some(value) = media(
            MediaVariantKind::Sample,
            string(value, "sample_url"),
            unsigned32(value, "sample_width"),
            unsigned32(value, "sample_height"),
            unsigned(value, "sample_file_size"),
            None,
            None,
            None,
        ) {
            variants.push(value);
        }
        if let Some(value) = media(
            MediaVariantKind::Preview,
            string(value, "jpeg_url"),
            unsigned32(value, "jpeg_width"),
            unsigned32(value, "jpeg_height"),
            unsigned(value, "jpeg_file_size"),
            Some("jpg".to_owned()),
            Some(MediaType::Jpeg),
            None,
        ) {
            variants.push(value);
        }
        if let Some(value) = media(
            MediaVariantKind::Original,
            string(value, "file_url"),
            unsigned32(value, "width"),
            unsigned32(value, "height"),
            unsigned(value, "file_size"),
            file_ext,
            None,
            md5,
        ) {
            variants.push(value);
        }
        if variants.is_empty() {
            return Err(BooruError::invalid_response(self.definition.id));
        }
        validate_media_hosts(&self.definition, &variants)?;
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            original_file_size: unsigned(value, "file_size"),
            original_file_extension: string(value, "file_ext"),
            original_checksum: md5_checksum(string(value, "md5")),
            width: unsigned32(value, "width"),
            height: unsigned32(value, "height"),
            id: PostId(id.clone()),
            web_url: Some(format!("{}/post/show/{id}", self.definition.web_base)),
            rating: rating(string(value, "rating").as_deref()),
            score: signed32(value, "score"),
            created_at_iso8601: unix_to_iso8601(unsigned(value, "created_at")),
            author: username(value, "/author"),
            source_url: string(value, "source"),
            tags: tag_list(
                string(value, "tags").as_deref().unwrap_or_default(),
                TagCategory::General,
            ),
            media: variants,
            flags: PostFlags {
                has_children: boolean(value, "has_children"),
                parent_id: parent_id(value),
                is_pending: boolean(value, "is_pending"),
                is_deleted: string(value, "status").as_deref() == Some("deleted"),
                is_ai_generated: self.definition.is_ai_source,
            },
        })
    }
}

#[async_trait]
impl BooruAdapter for MoebooruAdapter {
    fn definition(&self) -> &SourceDefinition {
        &self.definition
    }

    async fn search(&self, ctx: &RequestContext, query: SearchQuery) -> BooruResult<PostPage> {
        let page = query
            .cursor
            .as_deref()
            .unwrap_or("1")
            .parse::<u32>()
            .map_err(|_| BooruError::invalid_request(Some(self.definition.id)))?;
        let limit = query.page_size.clamp(1, self.definition.max_page_size);
        let mut tags = query.text.trim().to_owned();
        if query.ratings.len() == 1 {
            let filter = match query.ratings[0] {
                ContentRating::General | ContentRating::Sensitive => Some("rating:s"),
                ContentRating::Questionable => Some("rating:q"),
                ContentRating::Explicit => Some("rating:e"),
                ContentRating::Unknown => None,
            };
            if let Some(filter) = filter {
                if !tags.is_empty() {
                    tags.push(' ');
                }
                tags.push_str(filter);
            }
        }
        let url = reqwest::Url::parse(&format!("{}/post.json", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("tags".to_owned(), tags),
            ("api_version".to_owned(), "2".to_owned()),
            ("include_tags".to_owned(), "1".to_owned()),
            ("limit".to_owned(), limit.to_string()),
            ("page".to_owned(), page.to_string()),
        ];
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let mut items = self.parse_posts(&response.body)?;
        let exhausted = items.len() < limit as usize || page == u32::MAX;
        if !query.ratings.is_empty() {
            items.retain(|post| query.ratings.contains(&post.rating));
        }
        Ok(PostPage {
            next_cursor: (!exhausted).then(|| (page + 1).to_string()),
            exhausted,
            items,
        })
    }

    async fn feed(
        &self,
        ctx: &RequestContext,
        request: crate::api::booru_models::FeedRequest,
    ) -> BooruResult<PostPage> {
        use crate::api::booru_models::FeedKind;
        use crate::booru::discovery::{latest_query, parse_date, period, scale};
        if request.kind == FeedKind::Latest {
            return self.search(ctx, latest_query(request)).await;
        }
        if request.cursor.is_some() {
            return Err(BooruError::invalid_request(Some(self.definition.id)));
        }
        let range = request
            .range
            .ok_or_else(|| BooruError::invalid_request(Some(self.definition.id)))?;
        let (endpoint, query) = match request.kind {
            FeedKind::RecentPopular => (
                "popular_recent".to_owned(),
                vec![("period".into(), period(range, false).into())],
            ),
            FeedKind::HistoricalPopular => {
                let date = parse_date(
                    self.definition.id,
                    request.date.as_deref().unwrap_or_default(),
                )?;
                (
                    format!("popular_by_{}", scale(range)),
                    vec![
                        ("year".into(), date.year().to_string()),
                        ("month".into(), (date.month() as u8).to_string()),
                        ("day".into(), date.day().to_string()),
                    ],
                )
            }
            _ => return Err(self.unsupported()),
        };
        let url = reqwest::Url::parse(&format!(
            "{}/post/{endpoint}.json",
            self.definition.api_base
        ))
        .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = query;
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let mut items = self.parse_posts(&response.body)?;
        items.retain(|post| request.ratings.contains(&post.rating));
        Ok(PostPage {
            items,
            next_cursor: None,
            exhausted: true,
        })
    }

    async fn get_post(&self, ctx: &RequestContext, id: &PostId) -> BooruResult<Post> {
        validate_post_id(id, self.definition.id)?;
        let url = reqwest::Url::parse(&format!("{}/post.json", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("tags".to_owned(), format!("id:{}", id.0)),
            ("api_version".to_owned(), "2".to_owned()),
            ("include_tags".to_owned(), "1".to_owned()),
            ("limit".to_owned(), "1".to_owned()),
        ];
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        self.parse_posts(&response.body)?
            .into_iter()
            .next()
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))
    }

    async fn autocomplete(
        &self,
        ctx: &RequestContext,
        text: &str,
    ) -> BooruResult<Vec<BooruTagSuggestion>> {
        let url = reqwest::Url::parse(&format!("{}/tag.json", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("name".to_owned(), format!("{}*", text.trim())),
            ("limit".to_owned(), "20".to_owned()),
            ("order".to_owned(), "count".to_owned()),
        ];
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let json = parse_json(self.definition.id, &response.body)?;
        let values = json
            .as_array()
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        Ok(values
            .iter()
            .filter_map(|value| {
                let value_text = string(value, "name")?;
                let category = match unsigned(value, "type") {
                    Some(1) => TagCategory::Artist,
                    Some(3) => TagCategory::Copyright,
                    Some(4) => TagCategory::Character,
                    Some(5) => TagCategory::Meta,
                    _ => TagCategory::General,
                };
                Some(BooruTagSuggestion {
                    label: value_text.clone(),
                    value: value_text,
                    category,
                    post_count_decimal: string(value, "count"),
                })
            })
            .collect())
    }

    async fn related_posts(&self, ctx: &RequestContext, id: &PostId) -> BooruResult<Vec<Post>> {
        validate_post_id(id, self.definition.id)?;
        let url = reqwest::Url::parse(&format!("{}/post/similar.json", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![("id".to_owned(), id.0.clone())];
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let json = parse_json(self.definition.id, &response.body)?;
        let mut posts = Vec::new();
        if let Some(source) = json.get("source") {
            posts.push(self.parse_post(source)?);
        }
        if let Some(values) = json.get("posts").and_then(Value::as_array) {
            for value in values {
                posts.push(self.parse_post(value)?);
            }
        }
        let mut seen = BTreeSet::new();
        posts.retain(|post| seen.insert(post.id.0.clone()));
        Ok(posts)
    }
}

fn validate_post_id(id: &PostId, source_id: &str) -> BooruResult<()> {
    if !id.0.is_empty() && id.0.bytes().all(|byte| byte.is_ascii_digit()) {
        Ok(())
    } else {
        Err(BooruError::invalid_request(Some(source_id)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::booru::source::builtin_sources;

    fn adapter() -> MoebooruAdapter {
        MoebooruAdapter::new(
            builtin_sources()
                .into_iter()
                .find(|source| source.id == "yande")
                .unwrap(),
        )
    }

    #[test]
    fn preserves_source_username_in_api_model() {
        let fixture = serde_json::json!({"id":1,"file_url":"https://files.yande.re/a.jpg","author":" Alice "});
        let post = adapter().parse_post(&fixture).unwrap();
        assert_eq!(post.author.as_deref(), Some("Alice"));
        assert_eq!(post.into_api().author.as_deref(), Some("Alice"));
    }
    #[test]
    fn parses_moebooru_post_and_variants() {
        let fixture = br#"[{"id":123,"tags":"artist character","created_at":1700000000,"score":8,"md5":"0123456789abcdef0123456789abcdef","file_size":500,"file_ext":"jpg","file_url":"https://files.yande.re/a.jpg","preview_url":"https://assets.yande.re/p.jpg","preview_width":150,"preview_height":200,"width":1000,"height":2000,"rating":"q","has_children":true}]"#;
        let posts = adapter().parse_posts(fixture).unwrap();
        assert_eq!(posts[0].id.0, "123");
        assert_eq!(posts[0].rating, ContentRating::Questionable);
        assert_eq!(posts[0].media.len(), 2);
        assert_eq!(
            posts[0].media.last().unwrap().checksum,
            Some(Checksum {
                algorithm: ChecksumAlgorithm::Md5,
                value: "0123456789abcdef0123456789abcdef".to_owned(),
            })
        );
    }

    #[test]
    fn public_yande_1270930_uses_batch_category_map() {
        // Public read-only API response, 2026-10-20. No media is downloaded.
        let fixture = include_bytes!("fixtures/yande_1270930_tags.json");
        let posts = adapter().parse_posts(fixture).unwrap();
        let post = &posts[0];
        assert_eq!(post.id.0, "1270930");
        assert_eq!(
            (post.media[0].width, post.media[0].height),
            (Some(175), Some(300))
        );
        for (name, category) in [
            ("nanoda002_(saber427)", TagCategory::Artist),
            ("anastasya_feodorovna_snezhnaya", TagCategory::Character),
            ("genshin_impact", TagCategory::Copyright),
            ("tattoo", TagCategory::General),
        ] {
            assert_eq!(
                post.tags
                    .iter()
                    .find(|tag| tag.name == name)
                    .unwrap()
                    .category,
                category
            );
        }
        let api = posts.into_iter().next().unwrap().into_api();
        assert_eq!((api.width, api.height), (Some(1129), Some(1934)));
        assert_eq!(api.original_file_size_decimal.as_deref(), Some("1968721"));
        assert_eq!(api.original_file_extension.as_deref(), Some("jpg"));
        assert!(api.original_checksum.is_some());
        assert!(api
            .tags
            .iter()
            .any(|tag| tag.category == TagCategory::Artist));
    }

    #[test]
    fn missing_media_is_invalid() {
        assert!(adapter().parse_posts(br#"[{"id":1}]"#).is_err());
    }

    #[test]
    fn all_moebooru_sources_keep_original_facts_with_only_a_thumbnail() {
        for source_id in ["yande", "konachan_net", "konachan_com"] {
            let definition = builtin_sources()
                .into_iter()
                .find(|source| source.id == source_id)
                .unwrap();
            let host = definition.allowed_hosts[0];
            let source = MoebooruAdapter::new(definition);
            let value = serde_json::json!({
                "id": 42, "width": 2400, "height": 3600,
                "preview_url": format!("https://{host}/preview.jpg"),
                "preview_width": 100, "preview_height": 150,
                "actual_preview_width": 200, "actual_preview_height": 300,
                "file_size": 4000000, "file_ext": "png",
                "md5": "0123456789abcdef0123456789abcdef", "parent_id": 7
            });
            let post = source.parse_post(&value).unwrap().into_api();
            assert_eq!((post.width, post.height), (Some(2400), Some(3600)));
            assert_eq!(
                (post.media[0].width, post.media[0].height),
                (Some(200), Some(300))
            );
            assert_eq!(post.original_file_size_decimal.as_deref(), Some("4000000"));
            assert_eq!(post.original_file_extension.as_deref(), Some("png"));
            assert!(post.original_checksum.is_some());
            assert!(post.media[0].checksum.is_none());
            assert_eq!(post.flags.parent_id.as_deref(), Some("7"));
            let mut partial = value;
            partial
                .as_object_mut()
                .unwrap()
                .remove("actual_preview_height");
            let post = source.parse_post(&partial).unwrap();
            assert_eq!(
                (post.media[0].width, post.media[0].height),
                (Some(100), Some(150))
            );
        }
    }

    #[test]
    fn unknown_fields_are_ignored() {
        let fixture = br#"[{"id":1,"preview_url":"https://assets.yande.re/p.jpg","unknown":{"nested":true}}]"#;
        assert_eq!(adapter().parse_posts(fixture).unwrap().len(), 1);
    }

    #[test]
    fn empty_and_invalid_list_fixtures_are_distinct() {
        assert!(adapter().parse_posts(b"[]").unwrap().is_empty());
        assert!(adapter().parse_posts(b"<html>").is_err());
    }

    #[test]
    fn media_host_cannot_escape_source_allowlist() {
        let fixture = br#"[{"id":1,"preview_url":"https://example.com/p.jpg"}]"#;
        assert!(adapter().parse_posts(fixture).is_err());
    }
}
