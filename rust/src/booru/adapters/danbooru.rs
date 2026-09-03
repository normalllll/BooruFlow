use crate::api::booru_auth::AuthStateDto;
use crate::api::booru_models::{
    ContentPolicy, ContentRating, MediaVariantKind, TagCategory, TagSuggestionDto,
};
use crate::booru::adapter::{BooruAdapter, RequestContext};
use crate::booru::adapters::common::{
    boolean, media, parse_json, signed32, string, tag_list, unsigned, unsigned32,
    validate_media_hosts,
};
use crate::booru::error::{BooruErrorCode, BooruErrorDto, BooruResult};
use crate::booru::model::{Post, PostFlags, PostId, PostPage, SearchQuery, Tag};
use crate::booru::network::{RequestSpec, ResponseKind};
use crate::booru::source::SourceDefinition;
use async_trait::async_trait;
use serde_json::Value;
use std::collections::BTreeSet;

const ANIME_REJECT_TAGS: &[&str] = &[
    "photo_(medium)",
    "photograph",
    "real_life",
    "3d_(artwork)",
    "ai-assisted",
];

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
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        let mut items = Vec::with_capacity(values.len());
        let mut last_id = None;
        for value in values {
            let id = string(value, "id")
                .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
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
        let id = string(value, "id")
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
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
            return Err(BooruErrorDto::invalid_response(self.definition.id));
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
                .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
            let mut spec = RequestSpec::get(url, ResponseKind::Json);
            spec.query = vec![
                ("tags".to_owned(), query.text.trim().to_owned()),
                ("limit".to_owned(), limit.to_string()),
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
            for post in upstream.items {
                if rating_selected(post.rating, &query.ratings)
                    && (query.content_policy == ContentPolicy::Unfiltered || anime_focused(&post))
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
            if upstream_len < limit as usize {
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

    async fn get_post(&self, ctx: &RequestContext, id: &PostId) -> BooruResult<Post> {
        validate_post_id(id)?;
        let url = reqwest::Url::parse(&format!("{}/posts/{}.json", self.definition.api_base, id.0))
            .map_err(|_| BooruErrorDto::invalid_request(Some(self.definition.id)))?;
        let response = ctx
            .runtime
            .execute(&self.definition, RequestSpec::get(url, ResponseKind::Json))
            .await?;
        let json = parse_json(self.definition.id, &response.body)?;
        self.parse_post(&json)
    }

    async fn autocomplete(
        &self,
        ctx: &RequestContext,
        text: &str,
    ) -> BooruResult<Vec<TagSuggestionDto>> {
        let url = reqwest::Url::parse(&format!("{}/autocomplete.json", self.definition.api_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
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
            .ok_or_else(|| BooruErrorDto::invalid_response(self.definition.id))?;
        Ok(values
            .iter()
            .filter_map(|item| {
                let value = string(item, "value")?;
                Some(TagSuggestionDto {
                    label: string(item, "label").unwrap_or_else(|| value.clone()),
                    value,
                    category: TagCategory::General,
                    post_count_decimal: string(item, "post_count"),
                })
            })
            .collect())
    }

    async fn verify_auth(&self, ctx: &RequestContext) -> BooruResult<AuthStateDto> {
        if ctx.runtime.auth_state(self.definition.id)?.status
            == crate::api::booru_auth::AuthStatus::NotConfigured
        {
            return Err(BooruErrorDto::new(
                BooruErrorCode::AuthenticationRequired,
                Some(self.definition.id),
                "booru.error.authenticationRequired",
            ));
        }
        let url = reqwest::Url::parse(&format!("{}/profile.json", self.definition.api_base))
            .map_err(|_| BooruErrorDto::invalid_response(self.definition.id))?;
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
    let has_media = ["preview_file_url", "large_file_url", "file_url"]
        .iter()
        .any(|key| string(value, key).is_some());
    if has_media {
        return false;
    }
    boolean(value, "is_banned")
        || boolean(value, "is_deleted")
        || boolean(value, "is_pending")
        || matches!(
            string(value, "status").as_deref(),
            Some("banned" | "deleted" | "pending")
        )
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

fn anime_focused(post: &Post) -> bool {
    let names = post
        .tags
        .iter()
        .map(|tag| tag.name.as_str())
        .collect::<BTreeSet<_>>();
    if ANIME_REJECT_TAGS.iter().any(|tag| names.contains(tag)) {
        return false;
    }
    post.tags.iter().any(|tag| {
        matches!(
            tag.category,
            TagCategory::Artist | TagCategory::Copyright | TagCategory::Character
        )
    })
}

fn validate_danbooru_cursor(cursor: &str) -> BooruResult<()> {
    let valid = cursor
        .strip_prefix('b')
        .is_some_and(|value| !value.is_empty() && value.bytes().all(|byte| byte.is_ascii_digit()));
    if valid {
        Ok(())
    } else {
        Err(BooruErrorDto::invalid_request(None))
    }
}

fn validate_post_id(id: &PostId) -> BooruResult<()> {
    if !id.0.is_empty() && id.0.bytes().all(|byte| byte.is_ascii_digit()) {
        Ok(())
    } else {
        Err(BooruErrorDto::invalid_request(None))
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
    fn anime_filter_rejects_photos_but_not_explicit_art() {
        let mut post = adapter("danbooru")
            .parse_posts(br#"[{"id":1,"rating":"e","preview_file_url":"https://cdn.donmai.us/p.jpg","tag_string_artist":"alice","tag_string_general":"solo"}]"#)
            .unwrap()
            .items
            .remove(0);
        assert!(anime_focused(&post));
        post.tags.push(Tag {
            name: "photo_(medium)".to_owned(),
            category: TagCategory::Meta,
        });
        assert!(!anime_focused(&post));
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
    fn still_rejects_an_unflagged_post_without_media() {
        assert!(adapter("danbooru")
            .parse_posts(br#"[{"id":1,"rating":"g"}]"#)
            .is_err());
    }
}
