use crate::api::booru_auth::WebCookie;
use serde::{Deserialize, Serialize};

/// Site access verification is independent of account authentication.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WebChallengeTarget {
    pub id: String,
    pub url: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WebChallengeSpec {
    pub source_id: String,
    pub display_name: String,
    pub entry_url: String,
    pub navigation_hosts: Vec<String>,
    pub capture_targets: Vec<WebChallengeTarget>,
    pub timeout_seconds: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WebChallengeOperation {
    pub operation_id: String,
    pub spec: WebChallengeSpec,
}

/// A native URL cookie read, without invented domain/path/expiry metadata.
#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WebChallengeSnapshot {
    pub target_id: String,
    pub cookie_header: String,
}

/// Exactly one of full cookies or URL snapshots must be populated.
/// Deliberately no Debug: never include browser material in diagnostics.
#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WebChallengeCandidate {
    pub cookies: Vec<WebCookie>,
    pub snapshots: Vec<WebChallengeSnapshot>,
    pub user_agent: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WebChallengeState {
    pub source_id: String,
    pub has_saved_data: bool,
    pub verified: bool,
    pub verified_at_iso8601: Option<String>,
    pub revision: u32,
}
