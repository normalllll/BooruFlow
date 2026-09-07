#[cfg(test)]
use crate::api::booru_models::{ChecksumAlgorithm, ChecksumDto};
use crate::api::booru_models::{
    ContentRating, MediaType, MediaVariantKind, TagCategory, TagSuggestionDto,
};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::common::{
    boolean, media, parse_json, rating, signed32, string, tag_list, unix_to_iso8601, unsigned,
    unsigned32, username, validate_media_hosts,
};
use crate::booru::error::{BooruErrorDto, BooruResult};
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
        let items = json
            .as_array()
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        items.iter().map(|value| self.parse_post(value)).collect()
    }

    fn parse_post(&self, value: &Value) -> BooruResult<Post> {
        let id = string(value, "id")
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        let md5 = string(value, "md5");
        let file_ext = string(value, "file_ext");
        let mut variants = Vec::new();
        if let Some(value) = media(
            MediaVariantKind::Thumbnail,
            string(value, "preview_url"),
            unsigned32(value, "preview_width")
                .or_else(|| unsigned32(value, "actual_preview_width")),
            unsigned32(value, "preview_height")
                .or_else(|| unsigned32(value, "actual_preview_height")),
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
            return Err(BooruErrorDto::invalid_response(self.definition.id));
        }
        validate_media_hosts(&self.definition, &variants)?;
        Ok(Post {
            source_id: self.definition.id.to_owned(),
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
                parent_id: string(value, "parent_id").map(PostId),
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
            .map_err(|_| BooruErrorDto::invalid_request(Some(self.definition.id)))?;
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
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("tags".to_owned(), tags),
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
        request: crate::api::booru_models::FeedRequestDto,
    ) -> BooruResult<PostPage> {
        use crate::api::booru_models::FeedKind;
        use crate::booru::discovery::{latest_query, parse_date, period, scale};
        if request.kind == FeedKind::Latest {
            return self.search(ctx, latest_query(request)).await;
        }
        if request.cursor.is_some() {
            return Err(BooruErrorDto::invalid_request(Some(self.definition.id)));
        }
        let range = request
            .range
            .ok_or_else(|| BooruErrorDto::invalid_request(Some(self.definition.id)))?;
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
        .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
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
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("tags".to_owned(), format!("id:{}", id.0)),
            ("limit".to_owned(), "1".to_owned()),
        ];
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        self.parse_posts(&response.body)?
            .into_iter()
            .next()
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))
    }

    async fn autocomplete(
        &self,
        ctx: &RequestContext,
        text: &str,
    ) -> BooruResult<Vec<TagSuggestionDto>> {
        let url = reqwest::Url::parse(&format!("{}/tag.json", self.definition.api_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
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
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
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
                Some(TagSuggestionDto {
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
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
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
        Err(BooruErrorDto::invalid_request(Some(source_id)))
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
    fn preserves_source_username_in_dto() {
        let fixture = serde_json::json!({"id":1,"file_url":"https://files.yande.re/a.jpg","author":" Alice "});
        let post = adapter().parse_post(&fixture).unwrap();
        assert_eq!(post.author.as_deref(), Some("Alice"));
        assert_eq!(post.into_dto().author.as_deref(), Some("Alice"));
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
            Some(ChecksumDto {
                algorithm: ChecksumAlgorithm::Md5,
                value: "0123456789abcdef0123456789abcdef".to_owned(),
            })
        );
    }

    #[test]
    fn missing_media_is_invalid() {
        assert!(adapter().parse_posts(br#"[{"id":1}]"#).is_err());
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
