use crate::api::booru_models::{
    AuthKind, ContentRating, SortCapabilities, SortOption, SortOrder, SourceCapabilities,
};
use crate::booru::source::{ProtocolFamily, SourceDefinition};

pub fn capabilities(
    ratings: Vec<ContentRating>,
    auth_kind: AuthKind,
    autocomplete: bool,
    related: bool,
    authenticated_media: bool,
) -> SourceCapabilities {
    SourceCapabilities {
        discovery: crate::booru::discovery::unsupported_capabilities(),
        sorts: SortCapabilities {
            feed: vec![],
            search: vec![],
        },
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

/// The sorts each source applies, by protocol family. The first option of a
/// list is its default and sends no sort parameter.
pub fn sort_capabilities(source: &SourceDefinition) -> SortCapabilities {
    use SortOrder::*;
    fn options(primary: &[SortOrder], more: &[SortOrder]) -> Vec<SortOption> {
        primary
            .iter()
            .map(|&order| SortOption {
                order,
                primary: true,
            })
            .chain(more.iter().map(|&order| SortOption {
                order,
                primary: false,
            }))
            .collect()
    }
    let list = match source.family {
        ProtocolFamily::Wallhaven => {
            return SortCapabilities {
                feed: options(&[Latest, Hot, Views, Favorites, Random], &[Oldest]),
                search: options(
                    &[Latest, Relevance, Hot, Views, Favorites, Random],
                    &[Oldest],
                ),
            };
        }
        ProtocolFamily::Danbooru if source.is_ai_source => options(
            &[Latest, Views, Score, Favorites, Upvotes, Hot, Random],
            &[Oldest, Resolution, Landscape, Portrait],
        ),
        // Danbooru answers an untagged query for these orders with HTTP 500, so
        // the home feed offers only the orders it serves; tagged searches have all.
        ProtocolFamily::Danbooru => {
            return SortCapabilities {
                feed: options(&[Latest, Score, Favorites, Upvotes, Hot], &[Oldest]),
                search: options(
                    &[Latest, Score, Favorites, Upvotes, Hot, Random],
                    &[Oldest, Resolution, Landscape, Portrait],
                ),
            };
        }
        ProtocolFamily::Moebooru if source.id == "konachan_net" => options(
            &[Latest, Score, Random],
            &[Oldest, Resolution, Landscape, Portrait],
        ),
        ProtocolFamily::Moebooru => {
            options(&[Latest, Score], &[Oldest, Resolution, Landscape, Portrait])
        }
        ProtocolFamily::Gelbooru => options(&[Latest, Score, Random], &[Oldest, Updated]),
        ProtocolFamily::AnimePictures => {
            options(&[Latest, Score, Views], &[Oldest, FileSize, TagCount])
        }
    };
    SortCapabilities {
        feed: list.clone(),
        search: list,
    }
}

#[cfg(test)]
mod tests {
    use crate::api::booru_models::{SortOption, SortOrder::*};
    use crate::booru::source::builtin_sources;

    /// Primary options first, then the ones under the submenu.
    fn list(
        primary: &[crate::api::booru_models::SortOrder],
        more: &[crate::api::booru_models::SortOrder],
    ) -> Vec<SortOption> {
        primary
            .iter()
            .map(|&order| SortOption {
                order,
                primary: true,
            })
            .chain(more.iter().map(|&order| SortOption {
                order,
                primary: false,
            }))
            .collect()
    }

    #[test]
    fn each_source_declares_its_feed_and_search_sorts() {
        let moebooru_more = [Oldest, Resolution, Landscape, Portrait];
        let danbooru_search = list(
            &[Latest, Score, Favorites, Upvotes, Hot, Random],
            &moebooru_more,
        );
        let aibooru = list(
            &[Latest, Views, Score, Favorites, Upvotes, Hot, Random],
            &moebooru_more,
        );
        let gelbooru = list(&[Latest, Score, Random], &[Oldest, Updated]);
        let expected = [
            ("yande", list(&[Latest, Score], &moebooru_more), None),
            ("konachan_com", list(&[Latest, Score], &moebooru_more), None),
            (
                "konachan_net",
                list(&[Latest, Score, Random], &moebooru_more),
                None,
            ),
            (
                "danbooru",
                danbooru_search,
                Some(list(&[Latest, Score, Favorites, Upvotes, Hot], &[Oldest])),
            ),
            ("aibooru", aibooru, None),
            ("gelbooru", gelbooru, None),
            (
                "wallhaven",
                list(
                    &[Latest, Relevance, Hot, Views, Favorites, Random],
                    &[Oldest],
                ),
                Some(list(&[Latest, Hot, Views, Favorites, Random], &[Oldest])),
            ),
            (
                "anime_pictures",
                list(&[Latest, Score, Views], &[Oldest, FileSize, TagCount]),
                None,
            ),
        ];
        let sources = builtin_sources();
        assert_eq!(sources.len(), expected.len());
        for (id, search, feed) in expected {
            let sorts = &sources
                .iter()
                .find(|source| source.id == id)
                .unwrap_or_else(|| panic!("{id}"))
                .capabilities
                .sorts;
            assert_eq!(sorts.search, search, "{id} search");
            assert_eq!(sorts.feed, feed.unwrap_or(search), "{id} feed");
        }
    }
}
