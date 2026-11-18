use crate::api::booru_models::{Checksum, HttpHeader, MediaKind, MediaVariantKind};
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use tokio_util::sync::CancellationToken;

/// Stops a `stream_media` download from Dart as soon as its stream is
/// cancelled, including while the request still waits for its response.
#[frb(opaque)]
pub struct MediaCancel {
    pub(crate) token: CancellationToken,
}

impl MediaCancel {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            token: CancellationToken::new(),
        }
    }

    #[frb(sync)]
    pub fn cancel(&self) {
        self.token.cancel();
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum UgoiraExport {
    LosslessWebp,
    OriginalZip,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DownloadRequest {
    pub source_id: String,
    pub post_id: String,
    pub variant: MediaVariantKind,
    pub download_root: String,
    pub ugoira_export: Option<UgoiraExport>,
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
    Failed {
        error: crate::booru::error::BooruError,
    },
    Paused,
    Resumed {
        restarted: bool,
    },
    Progress {
        received_bytes_decimal: String,
        total_bytes_decimal: Option<String>,
        progress: f64,
    },
    Encoding {
        completed_frames: u32,
        total_frames: u32,
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
