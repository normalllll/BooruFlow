use crate::api::booru_auth::{AuthStateDto, AuthStatus};
use crate::api::booru_models::{MediaVariantKind, TagCategory};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::common::{
    media, parse_json, rating, signed32, string, tag_list, unix_to_iso8601, unsigned, unsigned32,
    validate_media_hosts,
};
use crate::booru::error::{BooruErrorCode, BooruErrorDto, BooruResult};
use crate::booru::model::{Post, PostFlags, PostId, PostPage, SearchQuery};
use crate::booru::network::{RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use async_trait::async_trait;
use serde_json::Value;

pub struct GelbooruAdapter {
    definition: SourceDefinition,
}

impl GelbooruAdapter {
    pub fn new(definition: SourceDefinition) -> Self {
        Self { definition }
    }

    fn parse_posts(&self, bytes: &[u8]) -> BooruResult<Vec<Post>> {
        let json = parse_json(self.definition.id, bytes)?;
        let values = match &json {
            Value::Array(values) => values,
            Value::Object(_) => json
                .get("post")
                .and_then(Value::as_array)
                .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?,
            _ => return Err(BooruErrorDto::invalid_response(self.definition.id)),
        };
        values.iter().map(|value| self.parse_post(value)).collect()
    }

    fn parse_post(&self, value: &Value) -> BooruResult<Post> {
        let id = string(value, "id")
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        let width = unsigned32(value, "width");
        let height = unsigned32(value, "height");
        let md5 = string(value, "md5");
        let mut variants = Vec::new();
        if let Some(item) = media(
            MediaVariantKind::Thumbnail,
            string(value, "preview_url"),
            unsigned32(value, "preview_width"),
            unsigned32(value, "preview_height"),
            None,
            None,
            None,
            None,
        ) {
            variants.push(item);
        }
        if let Some(item) = media(
            MediaVariantKind::Sample,
            string(value, "sample_url"),
            unsigned32(value, "sample_width"),
            unsigned32(value, "sample_height"),
            None,
            None,
            None,
            None,
        ) {
            variants.push(item);
        }
        if let Some(item) = media(
            MediaVariantKind::Original,
            string(value, "file_url"),
            width,
            height,
            unsigned(value, "file_size"),
            None,
            None,
            md5,
        ) {
            variants.push(item);
        }
        if variants.is_empty() {
            return Err(BooruErrorDto::invalid_response(self.definition.id));
        }
        validate_media_hosts(&self.definition, &variants)?;
        let created_at_iso8601 =
            string(value, "created_at").or_else(|| unix_to_iso8601(unsigned(value, "change")));
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            id: PostId(id.clone()),
            web_url: Some(format!(
                "{}/index.php?page=post&s=view&id={id}",
                self.definition.web_base
            )),
            rating: rating(string(value, "rating").as_deref()),
            score: signed32(value, "score"),
            created_at_iso8601,
            source_url: string(value, "source"),
            tags: tag_list(
                string(value, "tags").as_deref().unwrap_or_default(),
                TagCategory::General,
            ),
            media: variants,
            flags: PostFlags {
                is_deleted: string(value, "status").as_deref() == Some("deleted"),
                ..PostFlags::default()
            },
        })
    }

    fn request(&self, tags: &str, limit: u32, page: u32) -> BooruResult<RequestSpec> {
        let url = reqwest::Url::parse(&format!("{}/index.php", self.definition.api_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("page".to_owned(), "dapi".to_owned()),
            ("s".to_owned(), "post".to_owned()),
            ("q".to_owned(), "index".to_owned()),
            ("json".to_owned(), "1".to_owned()),
            ("tags".to_owned(), tags.to_owned()),
            ("limit".to_owned(), limit.to_string()),
            ("pid".to_owned(), page.to_string()),
        ];
        Ok(spec)
    }

    fn public_listing_request(&self, tags: &str, offset: u32) -> BooruResult<RequestSpec> {
        let url = reqwest::Url::parse(&format!("{}/index.php", self.definition.web_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Html);
        spec.query = vec![
            ("page".to_owned(), "post".to_owned()),
            ("s".to_owned(), "list".to_owned()),
            (
                "tags".to_owned(),
                if tags.trim().is_empty() {
                    "all".to_owned()
                } else {
                    tags.trim().to_owned()
                },
            ),
            ("pid".to_owned(), offset.to_string()),
        ];
        Ok(spec)
    }

    fn public_detail_request(&self, id: &PostId) -> BooruResult<RequestSpec> {
        if id.0.is_empty() || !id.0.bytes().all(|byte| byte.is_ascii_digit()) {
            return Err(BooruErrorDto::invalid_request(Some(self.definition.id)));
        }
        let url = reqwest::Url::parse(&format!("{}/index.php", self.definition.web_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Html);
        spec.query = vec![
            ("page".to_owned(), "post".to_owned()),
            ("s".to_owned(), "view".to_owned()),
            ("id".to_owned(), id.0.clone()),
        ];
        Ok(spec)
    }

    fn parse_public_listing(&self, bytes: &[u8], limit: usize) -> BooruResult<Vec<Post>> {
        let html = std::str::from_utf8(bytes)
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let ids = html.split("s=view&amp;id=").skip(1).filter_map(|tail| {
            let id = tail
                .bytes()
                .take_while(u8::is_ascii_digit)
                .map(char::from)
                .collect::<String>();
            (!id.is_empty()).then_some(id)
        });
        let previews = html
            .split("src=\"")
            .skip(1)
            .filter_map(|tail| tail.split_once('"').map(|(url, _)| url))
            .filter(|url| url.contains("/thumbnails/"));
        let mut posts = Vec::new();
        for (id, preview) in ids.zip(previews).take(limit) {
            let preview = media(
                MediaVariantKind::Thumbnail,
                Some(preview.to_owned()),
                None,
                None,
                None,
                None,
                None,
                None,
            )
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
            validate_media_hosts(&self.definition, std::slice::from_ref(&preview))?;
            posts.push(Post {
                source_id: self.definition.id.to_owned(),
                id: PostId(id.clone()),
                web_url: Some(format!(
                    "{}/index.php?page=post&s=view&id={id}",
                    self.definition.web_base
                )),
                rating: crate::api::booru_models::ContentRating::Unknown,
                score: None,
                created_at_iso8601: None,
                source_url: None,
                tags: Vec::new(),
                media: vec![preview],
                flags: PostFlags::default(),
            });
        }
        if posts.is_empty() {
            Err(BooruErrorDto::invalid_response(self.definition.id))
        } else {
            Ok(posts)
        }
    }

    fn parse_public_detail(&self, id: &PostId, bytes: &[u8]) -> BooruResult<Post> {
        let html = std::str::from_utf8(bytes)
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let original_url = html
            .split("property=\"og:image\" content=\"")
            .nth(1)
            .and_then(|tail| tail.split_once('"').map(|(url, _)| url))
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        let original = media(
            MediaVariantKind::Original,
            Some(original_url.to_owned()),
            None,
            None,
            None,
            None,
            None,
            None,
        )
        .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        validate_media_hosts(&self.definition, std::slice::from_ref(&original))?;
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            id: id.clone(),
            web_url: Some(format!(
                "{}/index.php?page=post&s=view&id={}",
                self.definition.web_base, id.0
            )),
            rating: crate::api::booru_models::ContentRating::Unknown,
            score: None,
            created_at_iso8601: None,
            source_url: None,
            tags: Vec::new(),
            media: vec![original],
            flags: PostFlags::default(),
        })
    }
}

#[async_trait]
impl BooruAdapter for GelbooruAdapter {
    fn definition(&self) -> &SourceDefinition {
        &self.definition
    }

    async fn search(&self, ctx: &RequestContext, query: SearchQuery) -> BooruResult<PostPage> {
        let page = query
            .cursor
            .as_deref()
            .unwrap_or("0")
            .parse::<u32>()
            .map_err(|_| BooruErrorDto::invalid_request(Some(self.definition.id)))?;
        let limit = query.page_size.clamp(1, self.definition.max_page_size);
        if ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured {
            let response = ctx
                .runtime
                .execute(
                    &self.definition,
                    self.public_listing_request(query.text.trim(), page)?,
                )
                .await?;
            let mut items = self.parse_public_listing(&response.body, limit as usize)?;
            if !query.ratings.is_empty() {
                items.retain(|post| query.ratings.contains(&post.rating));
            }
            let item_count = u32::try_from(items.len()).unwrap_or(0);
            return Ok(PostPage {
                exhausted: item_count < limit,
                next_cursor: (item_count >= limit)
                    .then(|| page.saturating_add(item_count).to_string()),
                items,
            });
        }
        let response = ctx
            .runtime
            .execute(
                &self.definition,
                self.request(query.text.trim(), limit, page)?,
            )
            .await?;
        let mut items = self.parse_posts(&response.body)?;
        let exhausted = items.len() < limit as usize || page == u32::MAX;
        if !query.ratings.is_empty() {
            items.retain(|post| query.ratings.contains(&post.rating));
        }
        Ok(PostPage {
            items,
            next_cursor: (!exhausted).then(|| (page + 1).to_string()),
            exhausted,
        })
    }

    async fn get_post(&self, ctx: &RequestContext, id: &PostId) -> BooruResult<Post> {
        if id.0.is_empty() || !id.0.bytes().all(|byte| byte.is_ascii_digit()) {
            return Err(BooruErrorDto::invalid_request(Some(self.definition.id)));
        }
        if ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured {
            let response = ctx
                .runtime
                .execute(&self.definition, self.public_detail_request(id)?)
                .await?;
            return self.parse_public_detail(id, &response.body);
        }
        let mut spec = self.request("", 1, 0)?;
        spec.query.push(("id".to_owned(), id.0.clone()));
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        self.parse_posts(&response.body)?
            .into_iter()
            .next()
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))
    }

    async fn verify_auth(&self, ctx: &RequestContext) -> BooruResult<AuthStateDto> {
        if ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured {
            return Err(BooruErrorDto::new(
                BooruErrorCode::AuthenticationRequired,
                Some(self.definition.id),
                "booru.error.authenticationRequired",
            ));
        }
        match ctx
            .runtime
            .execute(&self.definition, self.request("", 1, 0)?)
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::booru_models::ContentRating;
    use crate::booru::source::builtin_sources;

    fn adapter() -> GelbooruAdapter {
        GelbooruAdapter::new(
            builtin_sources()
                .into_iter()
                .find(|source| source.id == "gelbooru")
                .unwrap(),
        )
    }

    #[test]
    fn parses_wrapped_response_and_string_numbers() {
        let fixture = br#"{"@attributes":{"count":1},"post":[{"id":"42","width":"1000","height":"800","rating":"general","tags":"alice solo","file_url":"https://img3.gelbooru.com/a.jpg","file_size":"99"}]}"#;
        let posts = adapter().parse_posts(fixture).unwrap();
        assert_eq!(posts[0].id.0, "42");
        assert_eq!(posts[0].rating, ContentRating::General);
        assert_eq!(posts[0].media[0].byte_length, Some(99));
    }

    #[test]
    fn accepts_legacy_array_shape() {
        let fixture = br#"[{"id":42,"file_url":"https://img3.gelbooru.com/a.jpg"}]"#;
        assert_eq!(adapter().parse_posts(fixture).unwrap().len(), 1);
    }

    #[test]
    fn empty_and_invalid_list_fixtures_are_distinct() {
        assert!(adapter().parse_posts(br#"{"post":[]}"#).unwrap().is_empty());
        assert!(adapter().parse_posts(b"<html>").is_err());
    }

    #[test]
    fn parses_anonymous_public_listing() {
        let fixture = br#"<a href="index.php?page=post&amp;s=view&amp;id=42"><img src="https://img3.gelbooru.com/thumbnails/aa/bb/thumbnail.jpg"></a>"#;
        let posts = adapter().parse_public_listing(fixture, 5).unwrap();
        assert_eq!(posts.len(), 1);
        assert_eq!(posts[0].id.0, "42");
        assert_eq!(posts[0].media[0].kind, MediaVariantKind::Thumbnail);
    }

    #[test]
    fn parses_anonymous_public_detail_original() {
        let fixture = br#"<meta property="og:image" content="https://img3.gelbooru.com/images/aa/bb/original.png">"#;
        let post = adapter()
            .parse_public_detail(&PostId("42".to_owned()), fixture)
            .unwrap();
        assert_eq!(post.media[0].kind, MediaVariantKind::Original);
        assert!(post.media[0].url.ends_with("/original.png"));
    }
}
