use crate::api::booru_models::{Checksum, HttpHeader, MediaKind, MediaVariantKind};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DownloadRequest {
    pub source_id: String,
    pub post_id: String,
    pub variant: MediaVariantKind,
    pub download_root: String,
}

#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PreparedDownload {
    pub source_id: String,
    pub post_id: String,
    pub variant: MediaVariantKind,
    pub url: String,
    pub headers: Vec<HttpHeader>,
    pub expected_bytes_decimal: Option<String>,
    pub allowed_media_kinds: Vec<MediaKind>,
    pub checksum: Option<Checksum>,
    pub filename: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum DownloadEvent {
    Progress {
        received_bytes_decimal: String,
        total_bytes_decimal: Option<String>,
        progress: f64,
    },
    Done {
        path: String,
    },
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum MediaFetchEvent {
    Failed {
        error: crate::booru::error::BooruError,
    },
    Chunk {
        bytes: Vec<u8>,
        received_bytes_decimal: String,
        total_bytes_decimal: Option<String>,
    },
}
