use crate::api::booru_models::{AuthKind, ContentRating, SourceCapabilitiesDto};

pub fn capabilities(
    ratings: Vec<ContentRating>,
    auth_kind: AuthKind,
    autocomplete: bool,
    related: bool,
    authenticated_media: bool,
) -> SourceCapabilitiesDto {
    SourceCapabilitiesDto {
        ratings,
        auth_kind,
        supports_search: true,
        supports_post_detail: true,
        supports_autocomplete: autocomplete,
        supports_related_posts: related,
        supports_original: true,
        supports_authenticated_media: authenticated_media,
        supports_background_download: true,
    }
}
