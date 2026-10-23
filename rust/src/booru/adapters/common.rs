use crate::api::booru_models::{
    Checksum, ChecksumAlgorithm, ContentRating, MediaType, MediaVariantKind, TagCategory,
};
use crate::booru::error::{BooruError, BooruResult};
use crate::booru::model::{
    extension_from_url, media_type_from_extension, MediaVariant, PostId, Tag,
};
use crate::booru::source::SourceDefinition;
use serde_json::Value;

pub fn parse_json(source_id: &str, bytes: &[u8]) -> BooruResult<Value> {
    serde_json::from_slice(bytes).map_err(|_| BooruError::invalid_response(source_id))
}

pub fn string(value: &Value, key: &str) -> Option<String> {
    value.get(key).and_then(value_string)
}

/// Usernames must be supplied as text by the source, never inferred from IDs.
pub fn username(value: &Value, pointer: &str) -> Option<String> {
    value
        .pointer(pointer)
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|name| !name.is_empty())
        .map(str::to_owned)
}

#[test]
fn usernames_do_not_fall_back_to_numeric_ids_or_empty_text() {
    for value in [
        serde_json::json!({}),
        serde_json::json!({"author": 123}),
        serde_json::json!({"author": "  "}),
        serde_json::json!({"author": null}),
    ] {
        assert_eq!(username(&value, "/author"), None);
    }
    assert_eq!(
        username(&serde_json::json!({"author": "123"}), "/author"),
        Some("123".into())
    );
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

pub fn parent_id(value: &Value) -> Option<PostId> {
    unsigned(value, "parent_id")
        .filter(|id| *id > 0)
        .map(|id| PostId(id.to_string()))
}

pub fn md5_checksum(value: Option<String>) -> Option<Checksum> {
    value
        .filter(|value| is_hex(value, 32))
        .map(|value| Checksum {
            algorithm: ChecksumAlgorithm::Md5,
            value: value.to_ascii_lowercase(),
        })
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
    let checksum = md5_checksum(md5);
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

/// These APIs publish UTC for timestamps without an explicit offset.
pub fn source_time(value: Option<String>) -> Option<String> {
    use time::format_description::well_known::Rfc3339;
    use time::{OffsetDateTime, PrimitiveDateTime};

    let value = value?.replacen(' ', "T", 1);
    if let Ok(date) = OffsetDateTime::parse(&value, &Rfc3339) {
        return date.format(&Rfc3339).ok();
    }
    for format in [
        "[year]-[month]-[day]T[hour]:[minute]:[second].[subsecond]",
        "[year]-[month]-[day]T[hour]:[minute]:[second]",
    ] {
        let format = time::format_description::parse_borrowed::<2>(format).ok()?;
        if let Ok(date) = PrimitiveDateTime::parse(&value, &format) {
            return date.assume_utc().format(&Rfc3339).ok();
        }
    }
    None
}

pub fn validate_media_hosts(source: &SourceDefinition, media: &[MediaVariant]) -> BooruResult<()> {
    for item in media {
        let url =
            reqwest::Url::parse(&item.url).map_err(|_| BooruError::invalid_response(source.id))?;
        if url.scheme() != "https" || !url.host_str().is_some_and(|host| source.allows_host(host)) {
            return Err(BooruError::invalid_response(source.id));
        }
    }
    Ok(())
}

fn is_hex(value: &str, length: usize) -> bool {
    value.len() == length && value.bytes().all(|byte| byte.is_ascii_hexdigit())
}

#[test]
fn parent_ids_exclude_absent_sentinels_and_keep_real_relationships() {
    for id in [
        serde_json::json!(null),
        serde_json::json!(0),
        serde_json::json!("0"),
        serde_json::json!(-1),
        serde_json::json!(""),
    ] {
        assert_eq!(parent_id(&serde_json::json!({"parent_id": id})), None);
    }
    for id in [serde_json::json!(42), serde_json::json!("42")] {
        assert_eq!(
            parent_id(&serde_json::json!({"parent_id": id})),
            Some(PostId("42".into()))
        );
    }
}

#[test]
fn source_times_keep_offsets_and_mark_naive_timestamps_as_utc() {
    for text in ["2024-06-01 12:00:00", "2024-06-01T12:00:00"] {
        assert_eq!(
            source_time(Some(text.into())).as_deref(),
            Some("2024-06-01T12:00:00Z")
        );
    }
    assert_eq!(
        source_time(Some("2026-10-24T15:42:12.847548".into())).as_deref(),
        Some("2026-10-24T15:42:12.847548Z")
    );
    assert_eq!(
        source_time(Some("2024-06-01 14:00:00+02:00".into())).as_deref(),
        Some("2024-06-01T14:00:00+02:00")
    );
    assert_eq!(source_time(Some("invalid".into())), None);
    assert_eq!(source_time(None), None);
}
