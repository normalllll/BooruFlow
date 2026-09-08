use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq)]
pub struct SourceConnectionCheck {
    pub source_id: String,
    pub api_available: bool,
    pub media_available: bool,
    pub api_error: Option<crate::booru::error::BooruError>,
    pub media_error: Option<crate::booru::error::BooruError>,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
pub enum ContentRating {
    General,
    Sensitive,
    Questionable,
    Explicit,
    #[default]
    Unknown,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
pub enum TagCategory {
    Artist,
    Copyright,
    Character,
    Meta,
    #[default]
    General,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
pub enum MediaVariantKind {
    Thumbnail,
    #[default]
    Preview,
    Sample,
    Original,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
pub enum ChecksumAlgorithm {
    #[default]
    Md5,
    Sha256,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
pub enum AuthKind {
    #[default]
    None,
    LoginApiKey,
    UserIdApiKey,
    ApiKey,
    WebSession,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum NetworkFallbackMode {
    #[default]
    Off,
    PersistedIpOverride,
    LegacyIpUrl,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BooruProtocol {
    Moebooru,
    Danbooru,
    GelbooruDapi,
    WallhavenV1,
    AnimePicturesV3,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MediaKind {
    Image,
    Video,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MediaType {
    Jpeg,
    Png,
    Gif,
    Webp,
    Avif,
    Mp4,
    Webm,
    OtherImage,
    OtherVideo,
}

impl MediaType {
    pub fn from_mime(value: &str) -> Option<Self> {
        let value = value
            .split(';')
            .next()
            .unwrap_or_default()
            .trim()
            .to_ascii_lowercase();
        match value.as_str() {
            "image/jpeg" | "image/jpg" => Some(Self::Jpeg),
            "image/png" => Some(Self::Png),
            "image/gif" => Some(Self::Gif),
            "image/webp" => Some(Self::Webp),
            "image/avif" => Some(Self::Avif),
            "video/mp4" => Some(Self::Mp4),
            "video/webm" => Some(Self::Webm),
            value if value.starts_with("image/") => Some(Self::OtherImage),
            value if value.starts_with("video/") => Some(Self::OtherVideo),
            _ => None,
        }
    }

    pub fn kind(self) -> MediaKind {
        match self {
            Self::Jpeg | Self::Png | Self::Gif | Self::Webp | Self::Avif | Self::OtherImage => {
                MediaKind::Image
            }
            Self::Mp4 | Self::Webm | Self::OtherVideo => MediaKind::Video,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RouteProvider {
    UncensoredDns,
    DohSb,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BooruTag {
    pub name: String,
    pub category: TagCategory,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Checksum {
    pub algorithm: ChecksumAlgorithm,
    pub value: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MediaVariant {
    pub kind: MediaVariantKind,
    pub url: String,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub byte_length_decimal: Option<String>,
    pub media_type: Option<MediaType>,
    pub extension: Option<String>,
    pub checksum: Option<Checksum>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct PostFlags {
    pub has_children: bool,
    pub parent_id: Option<String>,
    pub is_pending: bool,
    pub is_deleted: bool,
    pub is_ai_generated: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BooruPost {
    pub source_id: String,
    pub author: Option<String>,
    pub post_id: String,
    pub post_key: String,
    pub web_url: Option<String>,
    pub rating: ContentRating,
    pub score: Option<i32>,
    pub created_at_iso8601: Option<String>,
    pub source_url: Option<String>,
    pub tags: Vec<BooruTag>,
    pub media: Vec<MediaVariant>,
    pub flags: PostFlags,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceCapabilities {
    pub discovery: DiscoveryCapabilities,
    pub ratings: Vec<ContentRating>,
    pub auth_kind: AuthKind,
    pub supports_search: bool,
    pub supports_post_detail: bool,
    pub supports_autocomplete: bool,
    pub supports_related_posts: bool,
    pub supports_original: bool,
    pub supports_authenticated_media: bool,
    pub supports_background_download: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CapabilityAvailability {
    Unsupported,
    RequiresProbe,
    Available,
    TemporarilyUnavailable,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum FeedKind {
    Latest,
    RecentPopular,
    HistoricalPopular,
    Random,
    LifetimeViews,
    LifetimeFavorites,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PopularRange {
    Day,
    ThreeDays,
    Week,
    Month,
    ThreeMonths,
    SixMonths,
    Year,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PopularTimeBasis {
    IndexTimeWindow,
    CalendarUploadPeriod,
    SourceActivityWindow,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DiscoveryCapabilities {
    pub popular: CapabilityAvailability,
    pub common_tags: CapabilityAvailability,
    pub popular_ranges: Vec<PopularRange>,
    pub historical_ranges: Vec<PopularRange>,
    pub time_basis: PopularTimeBasis,
    pub finite_popular_limit: Option<u32>,
    pub additional_feeds: Vec<FeedKind>,
    pub autocomplete_min_chars: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FeedRequest {
    pub source_id: String,
    pub kind: FeedKind,
    pub range: Option<PopularRange>,
    /// A date, not an instant. Calendar feeds are anchored in their cursor.
    pub date: Option<String>,
    pub seed: Option<String>,
    pub ratings: Vec<ContentRating>,
    /// Upstream page-size hint; finite rankings may return their whole list.
    pub page_size: u32,
    pub cursor: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CommonTagsRequest {
    pub source_id: String,
    pub page: u32,
    pub page_size: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CommonTagsPage {
    pub items: Vec<BooruTagSuggestion>,
    pub next_page: Option<u32>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BooruSource {
    pub source_id: String,
    pub display_name: String,
    pub protocol: BooruProtocol,
    pub enabled_by_default: bool,
    pub is_ai_source: bool,
    pub capabilities: SourceCapabilities,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SearchRequest {
    pub source_id: String,
    pub query_text: String,
    pub ratings: Vec<ContentRating>,
    pub page_size: u32,
    pub cursor: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PostPage {
    pub items: Vec<BooruPost>,
    pub next_cursor: Option<String>,
    pub exhausted: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BooruTagSuggestion {
    pub value: String,
    pub label: String,
    pub category: TagCategory,
    pub post_count_decimal: Option<String>,
}

#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HttpHeader {
    pub name: String,
    pub value: String,
}

#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MediaRequest {
    pub source_id: String,
    pub post_id: String,
    pub variant: MediaVariantKind,
    pub url: String,
    pub headers: Vec<HttpHeader>,
    pub route_key: String,
    pub cache_key: String,
    pub auth_revision: u32,
    pub route_revision: String,
    pub allow_disk_cache: bool,
}

#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BooruEngineConfig {
    pub app_support_directory: String,
    pub proxy_url: Option<String>,
    pub fallback_mode: NetworkFallbackMode,
    pub dns_provider: RouteProvider,
    pub user_agent: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PersistedHostRoute {
    pub logical_host: String,
    pub https_port: u16,
    pub candidates: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RouteCacheState {
    pub initialized: bool,
    pub refreshing: bool,
    pub route_revision: String,
    pub fetched_at_iso8601: Option<String>,
    pub provider: Option<RouteProvider>,
    pub routes: Vec<PersistedHostRoute>,
    pub diagnostics: Vec<RouteDiagnostic>,
}

pub fn post_key(source_id: &str, post_id: &str) -> String {
    format!("{source_id}:{post_id}")
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RouteDiagnostic {
    pub source_ids: Vec<String>,
    pub logical_host: String,
    pub status: String,
    pub candidates: Vec<String>,
    pub error: Option<String>,
    pub elapsed_ms: Option<u32>,
    pub updated_at_iso8601: Option<String>,
}
