use crate::api::booru_auth::{AuthStateDto, AuthStatus};
use crate::api::booru_models::{ContentRating, MediaType, MediaVariantKind, TagCategory};
use crate::booru::adapter::{BooruAdapter, PreparedMedia, RequestContext};
use crate::booru::adapters::common::{
    media, parse_json, signed32, string, unsigned, unsigned32, username, validate_media_hosts,
};
use crate::booru::error::{BooruErrorCode, BooruErrorDto, BooruResult};
use crate::booru::model::{Post, PostFlags, PostId, PostPage, SearchQuery, Tag};
use crate::booru::network::{RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use async_trait::async_trait;
use serde_json::Value;

pub struct AnimePicturesAdapter {
    definition: SourceDefinition,
}

impl AnimePicturesAdapter {
    pub fn new(definition: SourceDefinition) -> Self {
        Self { definition }
    }

    fn parse_listing(&self, bytes: &[u8]) -> BooruResult<(Vec<Post>, Option<u32>)> {
        let json = parse_json(self.definition.id, bytes)?;
        let values = json
            .get("posts")
            .and_then(Value::as_array)
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        let pages = unsigned32(&json, "max_pages")
            .or_else(|| unsigned32(&json, "pages"))
            .or_else(|| unsigned32(&json, "page_count"));
        let posts = values
            .iter()
            .map(|value| self.parse_post(value, false))
            .collect::<BooruResult<Vec<_>>>()?;
        Ok((posts, pages))
    }

    fn parse_post(&self, value: &Value, detail: bool) -> BooruResult<Post> {
        let id = string(value, "id")
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        let md5 = string(value, "md5");
        let extension = string(value, "ext").map(|value| value.trim_start_matches('.').to_owned());
        let width = unsigned32(value, "width");
        let height = unsigned32(value, "height");
        let mut variants = Vec::new();
        if let Some(md5) = md5
            .as_deref()
            .filter(|value| value.len() == 32 && value.bytes().all(|byte| byte.is_ascii_hexdigit()))
        {
            let prefix = &md5[..3];
            variants.push(
                media(
                    MediaVariantKind::Thumbnail,
                    Some(format!(
                        "https://opreviews.anime-pictures.net/{prefix}/{md5}_cp.avif"
                    )),
                    None,
                    None,
                    None,
                    Some("avif".to_owned()),
                    Some(MediaType::Avif),
                    None,
                )
                .expect("generated preview URL is non-empty"),
            );
            variants.push(
                media(
                    MediaVariantKind::Sample,
                    Some(format!(
                        "https://opreviews.anime-pictures.net/{prefix}/{md5}_bp.avif"
                    )),
                    None,
                    None,
                    None,
                    Some("avif".to_owned()),
                    Some(MediaType::Avif),
                    None,
                )
                .expect("generated sample URL is non-empty"),
            );
        }
        if detail {
            if let Some(file_url) = string(value, "file_url") {
                let original = self.original_url(&file_url)?;
                if let Some(item) = media(
                    MediaVariantKind::Original,
                    Some(original),
                    width,
                    height,
                    unsigned(value, "size"),
                    extension.clone(),
                    None,
                    md5.clone(),
                ) {
                    variants.push(item);
                }
            }
        }
        if variants.is_empty() {
            return Err(BooruErrorDto::invalid_response(self.definition.id));
        }
        validate_media_hosts(&self.definition, &variants)?;
        let tags = value
            .get("tags")
            .and_then(Value::as_array)
            .map(|values| parse_tags(values))
            .unwrap_or_default();
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            id: PostId(id.clone()),
            web_url: Some(format!("{}/posts/{id}", self.definition.web_base)),
            rating: anime_rating(unsigned(value, "erotics")),
            score: signed32(value, "score"),
            created_at_iso8601: string(value, "pubtime").map(normalize_time),
            author: username(value, "/user/name").or_else(|| username(value, "/user_name")),
            source_url: string(value, "source"),
            tags,
            media: variants,
            flags: PostFlags::default(),
        })
    }

    fn original_url(&self, file_url: &str) -> BooruResult<String> {
        if file_url.starts_with("https://") {
            let parsed = reqwest::Url::parse(file_url)
                .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
            if parsed
                .host_str()
                .is_some_and(|host| self.definition.allows_host(host))
            {
                return Ok(parsed.to_string());
            }
            return Err(BooruErrorDto::invalid_response(self.definition.id));
        }
        let segments = file_url
            .trim_start_matches('/')
            .split('/')
            .filter(|segment| !segment.is_empty())
            .collect::<Vec<_>>();
        if segments.is_empty()
            || segments
                .iter()
                .any(|segment| matches!(*segment, "." | ".."))
        {
            return Err(BooruErrorDto::invalid_response(self.definition.id));
        }
        let mut url =
            reqwest::Url::parse("https://api.anime-pictures.net/pictures/download_image/")
                .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut path = url
            .path_segments_mut()
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        path.pop_if_empty().extend(segments);
        drop(path);
        Ok(url.to_string())
    }
}

#[async_trait]
impl BooruAdapter for AnimePicturesAdapter {
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
        let url = reqwest::Url::parse(&format!("{}/posts", self.definition.api_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut spec = RequestSpec::get(url, ResponseKind::Json);
        spec.query = vec![
            ("page".to_owned(), page.to_string()),
            ("lang".to_owned(), "en".to_owned()),
            ("ldate".to_owned(), "0".to_owned()),
        ];
        if !query.text.trim().is_empty() {
            spec.query
                .push(("search_tag".to_owned(), query.text.trim().to_owned()));
        }
        let response = ctx.runtime.execute(&self.definition, spec).await?;
        let (mut items, max_pages) = self.parse_listing(&response.body)?;
        let upstream_was_empty = items.is_empty();
        if !query.ratings.is_empty() {
            items.retain(|post| query.ratings.contains(&post.rating));
        }
        let exhausted = upstream_was_empty
            || page == u32::MAX
            || max_pages.is_some_and(|pages| page.saturating_add(1) >= pages);
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
        let url = reqwest::Url::parse(&format!("{}/posts/{}", self.definition.api_base, id.0))
            .map_err(|_| BooruErrorDto::invalid_request(Some(self.definition.id)))?;
        let response = ctx
            .runtime
            .execute(&self.definition, RequestSpec::get(url, ResponseKind::Json))
            .await?;
        let json = parse_json(self.definition.id, &response.body)?;
        let mut post = json.get("post").cloned().unwrap_or_else(|| json.clone());
        let post_object = post
            .as_object_mut()
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        for key in ["file_url", "tags", "user", "user_name"] {
            if let Some(value) = json.get(key) {
                post_object.insert(key.to_owned(), value.clone());
            }
        }
        if let Some(source_url) = json
            .get("source")
            .and_then(|source| source.get("url"))
            .and_then(Value::as_str)
        {
            post_object.insert("source".to_owned(), Value::String(source_url.to_owned()));
        }
        self.parse_post(&post, true)
    }

    async fn prepare_media(
        &self,
        ctx: &RequestContext,
        id: &PostId,
        variant: MediaVariantKind,
    ) -> BooruResult<PreparedMedia> {
        let post = self.get_post(ctx, id).await?;
        let media = crate::booru::adapter::select_media(&post.media, variant)
            .ok_or_else(|| self.unsupported())?;
        let url = reqwest::Url::parse(&media.url)
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        Ok(PreparedMedia {
            headers: ctx.runtime.prepared_headers(&self.definition, &url)?,
            media,
            allow_disk_cache: variant != MediaVariantKind::Original,
        })
    }

    async fn verify_auth(&self, ctx: &RequestContext) -> BooruResult<AuthStateDto> {
        if ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured {
            return Err(BooruErrorDto::new(
                BooruErrorCode::AuthenticationRequired,
                Some(self.definition.id),
                "booru.error.authenticationRequired",
            ));
        }
        let url = reqwest::Url::parse(&format!("{}/users/me", self.definition.api_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
        match ctx
            .runtime
            .execute(&self.definition, RequestSpec::get(url, ResponseKind::Json))
            .await
        {
            Ok(_) => ctx.runtime.mark_auth_verified(self.definition.id),
            Err(error)
                if matches!(
                    error.code,
                    BooruErrorCode::AuthenticationRejected | BooruErrorCode::PermissionDenied
                ) =>
            {
                let _ = ctx.runtime.mark_auth_rejected(self.definition.id);
                Err(error)
            }
            Err(error) => Err(error),
        }
    }
}

fn parse_tags(values: &[Value]) -> Vec<Tag> {
    values
        .iter()
        .filter_map(|value| {
            let tag_value = value.get("tag").unwrap_or(value);
            string(tag_value, "tag")
                .or_else(|| string(tag_value, "name"))
                .map(|name| Tag {
                    name,
                    category: TagCategory::General,
                })
        })
        .collect()
}

fn anime_rating(value: Option<u64>) -> ContentRating {
    match value.unwrap_or(0) {
        0 => ContentRating::General,
        1 => ContentRating::Sensitive,
        2 => ContentRating::Questionable,
        _ => ContentRating::Explicit,
    }
}

fn normalize_time(value: String) -> String {
    if value.contains('T') {
        value
    } else {
        format!("{}Z", value.replace(' ', "T"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::booru::source::builtin_sources;

    fn adapter() -> AnimePicturesAdapter {
        AnimePicturesAdapter::new(
            builtin_sources()
                .into_iter()
                .find(|source| source.id == "anime_pictures")
                .unwrap(),
        )
    }

    #[test]
    fn preserves_source_username_in_dto() {
        let fixture = serde_json::json!({"id":1,"md5":"abcdef0123456789abcdef0123456789","user":{"name":" Alice "}});
        let post = adapter().parse_post(&fixture, false).unwrap();
        assert_eq!(post.author.as_deref(), Some("Alice"));
        assert_eq!(post.into_dto().author.as_deref(), Some("Alice"));
    }
    #[test]
    fn parses_listing_preview_urls() {
        let fixture = br#"{"posts":[{"id":834153,"width":1309,"height":2000,"size":2397010,"ext":".png","md5":"abcdef0123456789abcdef0123456789","erotics":1,"pubtime":"2024-06-01 12:00:00"}],"max_pages":2}"#;
        let (posts, pages) = adapter().parse_listing(fixture).unwrap();
        assert_eq!(pages, Some(2));
        assert_eq!(posts[0].rating, ContentRating::Sensitive);
        assert!(posts[0].media[0].url.contains("_cp.avif"));
    }

    #[test]
    fn detail_maps_nested_tags_and_download_endpoint() {
        let fixture = serde_json::json!({
            "id": 834153,
            "width": 1309,
            "height": 2000,
            "size": 2397010,
            "ext": ".png",
            "md5": "abcdef0123456789abcdef0123456789",
            "file_url": "834153-image.png",
            "tags": [{"tag": {"tag": "character"}}]
        });
        let post = adapter().parse_post(&fixture, true).unwrap();
        assert_eq!(post.tags[0].name, "character");
        assert!(post
            .media
            .iter()
            .any(|media| media.url.contains("/pictures/download_image/")));
    }

    #[test]
    fn malformed_md5_and_cross_source_original_are_rejected() {
        let malformed = serde_json::json!({"id": 1, "md5": "éé", "file_url": "x.jpg"});
        assert!(adapter().parse_post(&malformed, false).is_err());

        let external = serde_json::json!({
            "id": 1,
            "md5": "abcdef0123456789abcdef0123456789",
            "file_url": "https://example.com/x.jpg"
        });
        assert!(adapter().parse_post(&external, true).is_err());
    }

    #[test]
    fn original_path_segments_are_percent_encoded() {
        let url = adapter().original_url("folder/a b.jpg").unwrap();
        assert_eq!(
            url,
            "https://api.anime-pictures.net/pictures/download_image/folder/a%20b.jpg"
        );
        assert!(adapter().original_url("../secret.jpg").is_err());
    }

    #[test]
    fn empty_and_invalid_list_fixtures_are_distinct() {
        let (posts, _) = adapter()
            .parse_listing(br#"{"posts":[],"max_pages":0}"#)
            .unwrap();
        assert!(posts.is_empty());
        assert!(adapter().parse_listing(b"<html>").is_err());
    }
}
