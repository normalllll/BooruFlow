use crate::api::booru_models::{
    ChecksumAlgorithm, ChecksumDto, ContentRating, MediaType, MediaVariantKind, TagCategory,
};
use crate::booru::error::{BooruErrorDto, BooruResult};
use crate::booru::model::{extension_from_url, media_type_from_extension, MediaVariant, Tag};
use crate::booru::source::SourceDefinition;
use serde_json::Value;

pub fn parse_json(source_id: &str, bytes: &[u8]) -> BooruResult<Value> {
    serde_json::from_slice(bytes).map_err(|_| BooruErrorDto::invalid_response(source_id))
}

pub fn string(value: &Value, key: &str) -> Option<String> {
    value.get(key).and_then(value_string)
}

pub fn value_string(value: &Value) -> Option<String> {
    match value {
        Value::String(value) if !value.is_empty() => Some(value.clone()),
        Value::Number(value) => Some(value.to_string()),
        _ => None,
    }
}

pub fn unsigned(value: &Value, key: &str) -> Option<u64> {
    value.get(key).and_then(|value| match value {
        Value::Number(value) => value.as_u64(),
        Value::String(value) => value.parse().ok(),
        _ => None,
    })
}

pub fn unsigned32(value: &Value, key: &str) -> Option<u32> {
    unsigned(value, key).and_then(|value| u32::try_from(value).ok())
}

pub fn signed32(value: &Value, key: &str) -> Option<i32> {
    value.get(key).and_then(|value| match value {
        Value::Number(value) => value.as_i64().and_then(|value| i32::try_from(value).ok()),
        Value::String(value) => value.parse().ok(),
        _ => None,
    })
}

pub fn boolean(value: &Value, key: &str) -> bool {
    value.get(key).is_some_and(|value| match value {
        Value::Bool(value) => *value,
        Value::Number(value) => value.as_u64() == Some(1),
        Value::String(value) => matches!(value.as_str(), "true" | "1" | "yes"),
        _ => false,
    })
}

pub fn rating(value: Option<&str>) -> ContentRating {
    match value.unwrap_or_default().to_ascii_lowercase().as_str() {
        "g" | "general" | "safe" | "s" | "sfw" => ContentRating::General,
        "sensitive" | "sketchy" => ContentRating::Sensitive,
        "q" | "questionable" => ContentRating::Questionable,
        "e" | "explicit" | "nsfw" => ContentRating::Explicit,
        _ => ContentRating::Unknown,
    }
}

pub fn tag_list(text: &str, category: TagCategory) -> Vec<Tag> {
    text.split_whitespace()
        .filter(|tag| !tag.is_empty())
        .map(|tag| Tag {
            name: tag.to_owned(),
            category,
        })
        .collect()
}

#[allow(clippy::too_many_arguments)]
pub fn media(
    kind: MediaVariantKind,
    url: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
    byte_length: Option<u64>,
    extension: Option<String>,
    media_type: Option<MediaType>,
    md5: Option<String>,
) -> Option<MediaVariant> {
    let url = url.filter(|value| !value.is_empty())?;
    let extension = extension.or_else(|| extension_from_url(&url));
    let media_type =
        media_type.or_else(|| extension.as_deref().and_then(media_type_from_extension));
    let checksum = md5
        .filter(|value| is_hex(value, 32))
        .map(|value| ChecksumDto {
            algorithm: ChecksumAlgorithm::Md5,
            value: value.to_ascii_lowercase(),
        });
    Some(MediaVariant {
        kind,
        url,
        width,
        height,
        byte_length,
        media_type,
        extension,
        checksum,
    })
}

pub fn unix_to_iso8601(seconds: Option<u64>) -> Option<String> {
    let seconds = i64::try_from(seconds?).ok()?;
    time::OffsetDateTime::from_unix_timestamp(seconds)
        .ok()?
        .format(&time::format_description::well_known::Rfc3339)
        .ok()
}

pub fn validate_media_hosts(source: &SourceDefinition, media: &[MediaVariant]) -> BooruResult<()> {
    for item in media {
        let url = reqwest::Url::parse(&item.url)
            .map_err(|_| BooruErrorDto::invalid_response(source.id))?;
        if url.scheme() != "https" || !url.host_str().is_some_and(|host| source.allows_host(host)) {
            return Err(BooruErrorDto::invalid_response(source.id));
        }
    }
    Ok(())
}

fn is_hex(value: &str, length: usize) -> bool {
    value.len() == length && value.bytes().all(|byte| byte.is_ascii_hexdigit())
}
