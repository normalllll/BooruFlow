use crate::api::booru_auth::{AuthState, AuthStatus};
use crate::api::booru_models::{MediaVariantKind, TagCategory};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::common::{
    boolean, md5_checksum, media, parent_id, parse_json, rating, signed32, string, tag_list,
    unix_to_iso8601, unsigned, unsigned32, username, validate_media_hosts,
};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
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
                .ok_or_else(|| BooruError::invalid_response(self.definition.id))?,
            _ => return Err(BooruError::invalid_response(self.definition.id)),
        };
        values.iter().map(|value| self.parse_post(value)).collect()
    }

    fn parse_post(&self, value: &Value) -> BooruResult<Post> {
        let id =
            string(value, "id").ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
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
            return Err(BooruError::invalid_response(self.definition.id));
        }
        validate_media_hosts(&self.definition, &variants)?;
        let created_at_iso8601 = parse_created_at(value);
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            original_file_size: unsigned(value, "file_size"),
            original_file_extension: string(value, "file_ext"),
            original_checksum: md5_checksum(string(value, "md5")),
            width,
            height,
            id: PostId(id.clone()),
            web_url: Some(format!(
                "{}/index.php?page=post&s=view&id={id}",
                self.definition.web_base
            )),
            rating: rating(string(value, "rating").as_deref()),
            score: signed32(value, "score"),
            created_at_iso8601,
            author: username(value, "/owner"),
            source_url: string(value, "source"),
            tags: tag_list(
                string(value, "tags").as_deref().unwrap_or_default(),
                TagCategory::General,
            ),
            media: variants,
            flags: PostFlags {
                parent_id: parent_id(value),
                has_children: boolean(value, "has_children"),
                is_pending: boolean(value, "is_pending")
                    || string(value, "status").as_deref() == Some("pending"),
                is_deleted: boolean(value, "is_deleted")
                    || string(value, "status").as_deref() == Some("deleted"),
                ..PostFlags::default()
            },
        })
    }

    fn request(&self, tags: &str, limit: u32, page: u32) -> BooruResult<RequestSpec> {
        let url = reqwest::Url::parse(&format!("{}/index.php", self.definition.api_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
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
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
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
            return Err(BooruError::invalid_request(Some(self.definition.id)));
        }
        let url = reqwest::Url::parse(&format!("{}/index.php", self.definition.web_base))
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
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
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let mut posts = Vec::new();
        for anchor in html.split("<a ").skip(1) {
            let Some((anchor, _)) = anchor.split_once("</a>") else {
                continue;
            };
            let Some((_, tail)) = anchor
                .split_once("s=view&amp;id=")
                .or_else(|| anchor.split_once("s=view&id="))
            else {
                continue;
            };
            let id = tail
                .chars()
                .take_while(char::is_ascii_digit)
                .collect::<String>();
            let Some((_, image)) = anchor.split_once("<img ") else {
                continue;
            };
            let Some(preview) =
                html_attribute(image, "src").filter(|url| url.contains("/thumbnails/"))
            else {
                continue;
            };
            if id.is_empty() {
                continue;
            }
            let title = html_attribute(image, "title").unwrap_or_default();
            let source_rating = title
                .split_whitespace()
                .find_map(|part| part.strip_prefix("rating:"));
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
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
            validate_media_hosts(&self.definition, std::slice::from_ref(&preview))?;
            posts.push(Post {
                source_id: self.definition.id.to_owned(),
                original_file_size: None,
                original_file_extension: None,
                original_checksum: None,
                width: None,
                height: None,
                id: PostId(id.clone()),
                web_url: Some(format!(
                    "{}/index.php?page=post&s=view&id={id}",
                    self.definition.web_base
                )),
                rating: rating(source_rating),
                score: None,
                created_at_iso8601: None,
                author: title
                    .split_whitespace()
                    .find_map(|part| part.strip_prefix("user:"))
                    .filter(|name| !name.is_empty())
                    .map(decode_username),
                source_url: None,
                tags: Vec::new(),
                media: vec![preview],
                flags: PostFlags::default(),
            });
            if posts.len() >= limit {
                break;
            }
        }
        if posts.is_empty() {
            Err(BooruError::invalid_response(self.definition.id))
        } else {
            Ok(posts)
        }
    }

    fn parse_public_detail(&self, id: &PostId, bytes: &[u8]) -> BooruResult<Post> {
        let html = std::str::from_utf8(bytes)
            .map_err(|_| BooruError::invalid_response(self.definition.id))?;
        let original_url = html
            .split("property=\"og:image\" content=\"")
            .nth(1)
            .and_then(|tail| tail.split_once('"').map(|(url, _)| url))
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
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
        .ok_or_else(|| BooruError::invalid_response(self.definition.id))?;
        validate_media_hosts(&self.definition, std::slice::from_ref(&original))?;
        Ok(Post {
            source_id: self.definition.id.to_owned(),
            original_file_size: None,
            original_file_extension: None,
            original_checksum: None,
            width: None,
            height: None,
            id: id.clone(),
            web_url: Some(format!(
                "{}/index.php?page=post&s=view&id={}",
                self.definition.web_base, id.0
            )),
            rating: crate::api::booru_models::ContentRating::Unknown,
            score: None,
            created_at_iso8601: None,
            author: html.split_once("Posted:").and_then(|(_, info)| {
                let info = info.split("</li>").next()?;
                info.split("<a ").skip(1).find_map(|anchor| {
                    let href = html_attribute(anchor, "href")?;
                    if !href.contains("s=profile") {
                        return None;
                    }
                    let name = anchor.split_once('>')?.1.split_once("</a>")?.0.trim();
                    (!name.is_empty() && !name.contains('<')).then(|| decode_username(name))
                })
            }),
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
            .map_err(|_| BooruError::invalid_request(Some(self.definition.id)))?;
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
            let item_count = u32::try_from(items.len()).unwrap_or(0);
            if !query.ratings.is_empty() {
                items.retain(|post| query.ratings.contains(&post.rating));
            }
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
            return Err(BooruError::invalid_request(Some(self.definition.id)));
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
            .ok_or_else(|| BooruError::invalid_response(self.definition.id))
    }

    async fn verify_auth(&self, ctx: &RequestContext) -> BooruResult<AuthState> {
        if ctx.runtime.auth_state(self.definition.id)?.status == AuthStatus::NotConfigured {
            return Err(BooruError::new(
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

fn parse_created_at(value: &Value) -> Option<String> {
    use time::format_description::well_known::{Rfc2822, Rfc3339};
    use time::OffsetDateTime;

    let text = string(value, "created_at")?;
    // DAPI's Ruby-style date is not ISO 8601. `change` is a modification
    // timestamp, so it must never substitute for a missing publication date.
    let legacy = time::format_description::parse_borrowed::<2>(
        "[weekday repr:short] [month repr:short] [day padding:space] [hour]:[minute]:[second] [offset_hour sign:mandatory][offset_minute] [year]",
    ).ok()?;
    OffsetDateTime::parse(&text, &Rfc3339)
        .or_else(|_| OffsetDateTime::parse(&text, &Rfc2822))
        .or_else(|_| OffsetDateTime::parse(&text, &legacy))
        .ok()
        .and_then(|date| date.format(&Rfc3339).ok())
        .or_else(|| unix_to_iso8601(unsigned(value, "created_at")))
}

fn html_attribute<'a>(element: &'a str, name: &str) -> Option<&'a str> {
    for quote in ['"', '\''] {
        let prefix = format!("{name}={quote}");
        if let Some((_, tail)) = element.split_once(&prefix) {
            return tail.split_once(quote).map(|(value, _)| value);
        }
    }
    None
}

fn decode_username(value: &str) -> String {
    value
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&amp;", "&")
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
    fn preserves_source_username_in_api_model() {
        let fixture = serde_json::json!({"id":1,"file_url":"https://img3.gelbooru.com/a.jpg","owner":" Alice "});
        let post = adapter().parse_post(&fixture).unwrap();
        assert_eq!(post.author.as_deref(), Some("Alice"));
        assert_eq!(post.into_api().author.as_deref(), Some("Alice"));
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
    fn dapi_metadata_survives_without_an_original_url() {
        let post = adapter()
            .parse_post(&serde_json::json!({
                "id": "42", "width": "2400", "height": "3600",
                "preview_url": "https://img3.gelbooru.com/thumbnails/a.jpg",
                "preview_width": 100, "preview_height": 150,
                "file_size": "4000000", "file_ext": "png",
                "md5": "0123456789abcdef0123456789abcdef",
                "parent_id": "7", "has_children": true,
                "created_at": "Sat Jun 01 12:00:00 +0000 2024", "change": 1800000000,
                "owner": "Alice", "score": "10", "tags": "sky solo", "rating": "general"
            }))
            .unwrap()
            .into_api();
        assert_eq!((post.width, post.height), (Some(2400), Some(3600)));
        assert_eq!(post.original_file_size_decimal.as_deref(), Some("4000000"));
        assert_eq!(post.original_file_extension.as_deref(), Some("png"));
        assert!(post.original_checksum.is_some());
        assert_eq!(post.flags.parent_id.as_deref(), Some("7"));
        assert!(post.flags.has_children);
        assert_eq!(
            post.created_at_iso8601.as_deref(),
            Some("2024-06-01T12:00:00Z")
        );
        assert_eq!(post.score, Some(10));
        assert_eq!(post.author.as_deref(), Some("Alice"));
        assert_eq!(post.tags.len(), 2);
        assert_eq!(
            (post.media[0].width, post.media[0].height),
            (Some(100), Some(150))
        );
        assert!(post.media[0].byte_length_decimal.is_none());
    }

    #[test]
    fn publication_time_accepts_source_formats_but_never_uses_change() {
        for date in [
            "Sat Jun 01 12:00:00 +0000 2024",
            "Sat Jun  1 12:00:00 +0000 2024",
            "Sat, 01 Jun 2024 14:00:00 +0200",
            "2024-06-01T12:00:00Z",
        ] {
            let normalized = parse_created_at(&serde_json::json!({"created_at": date})).unwrap();
            assert_eq!(
                time::OffsetDateTime::parse(
                    &normalized,
                    &time::format_description::well_known::Rfc3339
                )
                .unwrap()
                .unix_timestamp(),
                1717243200
            );
        }
        assert_eq!(
            parse_created_at(&serde_json::json!({"change": 1717243200})),
            None
        );
        assert_eq!(
            parse_created_at(&serde_json::json!({"created_at": "invalid", "change": 1717243200})),
            None
        );
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
    fn public_listing_keeps_each_rating_with_its_own_post() {
        let fixture = br#"<a href="?s=view&amp;id=999">unrelated</a><a href="?s=view&amp;id=42"><img src="https://img3.gelbooru.com/thumbnails/a.jpg" title="sky rating:general"></a><a href="?s=view&amp;id=43"><img src="https://img3.gelbooru.com/thumbnails/b.jpg" title="rating:explicit"></a>"#;
        let posts = adapter().parse_public_listing(fixture, 10).unwrap();
        assert_eq!(posts.len(), 2);
        assert_eq!(posts[0].id.0, "42");
        assert_eq!(posts[0].rating, ContentRating::General);
        assert_eq!(posts[1].id.0, "43");
        assert_eq!(posts[1].rating, ContentRating::Explicit);
    }

    #[test]
    fn parses_anonymous_public_detail_original() {
        let fixture = br#"<meta property="og:image" content="https://img3.gelbooru.com/images/aa/bb/original.png"><li>Posted: today by <a href="index.php?page=account&amp;s=profile&amp;id=12">Alice &amp; Bob</a></li>"#;
        let post = adapter()
            .parse_public_detail(&PostId("42".to_owned()), fixture)
            .unwrap();
        assert_eq!(post.media[0].kind, MediaVariantKind::Original);
        assert!(post.media[0].url.ends_with("/original.png"));
        assert_eq!(post.author.as_deref(), Some("Alice & Bob"));
    }
}
