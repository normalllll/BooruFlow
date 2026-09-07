use crate::api::booru_models::{
    post_key, BooruPostDto, BooruTagDto, ChecksumDto, ContentRating, MediaType, MediaVariantDto,
    MediaVariantKind, PostFlagsDto, TagCategory,
};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct PostId(pub String);

#[derive(Debug, Clone)]
pub struct SearchQuery {
    pub text: String,
    pub ratings: Vec<ContentRating>,
    pub page_size: u32,
    pub cursor: Option<String>,
}

#[derive(Debug, Clone)]
pub struct PostPage {
    pub items: Vec<Post>,
    pub next_cursor: Option<String>,
    pub exhausted: bool,
}

#[derive(Debug, Clone)]
pub struct Post {
    pub source_id: String,
    pub author: Option<String>,
    pub id: PostId,
    pub web_url: Option<String>,
    pub rating: ContentRating,
    pub score: Option<i32>,
    pub created_at_iso8601: Option<String>,
    pub source_url: Option<String>,
    pub tags: Vec<Tag>,
    pub media: Vec<MediaVariant>,
    pub flags: PostFlags,
}

#[derive(Debug, Clone)]
pub struct Tag {
    pub name: String,
    pub category: TagCategory,
}

#[derive(Debug, Clone)]
pub struct MediaVariant {
    pub kind: MediaVariantKind,
    pub url: String,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub byte_length: Option<u64>,
    pub media_type: Option<MediaType>,
    pub extension: Option<String>,
    pub checksum: Option<ChecksumDto>,
}

#[derive(Debug, Clone, Default)]
pub struct PostFlags {
    pub has_children: bool,
    pub parent_id: Option<PostId>,
    pub is_pending: bool,
    pub is_deleted: bool,
    pub is_ai_generated: bool,
}

impl Post {
    pub fn into_dto(self) -> BooruPostDto {
        let key = post_key(&self.source_id, &self.id.0);
        BooruPostDto {
            source_id: self.source_id,
            author: self.author,
            post_id: self.id.0,
            post_key: key,
            web_url: self.web_url,
            rating: self.rating,
            score: self.score,
            created_at_iso8601: self.created_at_iso8601,
            source_url: self.source_url,
            tags: self
                .tags
                .into_iter()
                .map(|tag| BooruTagDto {
                    name: tag.name,
                    category: tag.category,
                })
                .collect(),
            media: self
                .media
                .into_iter()
                .map(|media| MediaVariantDto {
                    kind: media.kind,
                    url: media.url,
                    width: media.width,
                    height: media.height,
                    byte_length_decimal: media.byte_length.map(|value| value.to_string()),
                    media_type: media.media_type,
                    extension: media.extension,
                    checksum: media.checksum,
                })
                .collect(),
            flags: PostFlagsDto {
                has_children: self.flags.has_children,
                parent_id: self.flags.parent_id.map(|id| id.0),
                is_pending: self.flags.is_pending,
                is_deleted: self.flags.is_deleted,
                is_ai_generated: self.flags.is_ai_generated,
            },
        }
    }
}

pub fn extension_from_url(url: &str) -> Option<String> {
    let parsed = url::Url::parse(url).ok()?;
    parsed
        .path_segments()?
        .next_back()?
        .rsplit_once('.')
        .map(|(_, extension)| extension.to_ascii_lowercase())
}

pub fn media_type_from_extension(extension: &str) -> Option<MediaType> {
    match extension.to_ascii_lowercase().as_str() {
        "jpg" | "jpeg" => Some(MediaType::Jpeg),
        "png" => Some(MediaType::Png),
        "gif" => Some(MediaType::Gif),
        "webp" => Some(MediaType::Webp),
        "avif" => Some(MediaType::Avif),
        "mp4" => Some(MediaType::Mp4),
        "webm" => Some(MediaType::Webm),
        _ => None,
    }
}
