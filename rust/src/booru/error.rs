use serde::{Deserialize, Serialize};
use std::fmt::{Display, Formatter};
use std::sync::atomic::{AtomicU32, Ordering};

static DIAGNOSTIC_SEQUENCE: AtomicU32 = AtomicU32::new(1);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BooruErrorCode {
    InvalidRequest,
    UnsupportedCapability,
    AuthenticationRequired,
    AuthenticationRejected,
    PermissionDenied,
    RateLimited,
    ChallengeRequired,
    SourceUnavailable,
    Network,
    Timeout,
    InvalidResponse,
    UnsafeRedirect,
    MediaValidationFailed,
    Cancelled,
    Internal,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RecoveryAction {
    Retry,
    Login,
    SwitchSource,
    CheckProxy,
    RefreshRoute,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BooruError {
    pub code: BooruErrorCode,
    pub source_id: Option<String>,
    pub user_message_key: String,
    pub diagnostic_id: String,
    pub http_status: Option<u32>,
    pub retry_after_seconds: Option<u32>,
    pub action: Option<RecoveryAction>,
    /// Technical failure stage and original system error; never browser material.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub details: Option<String>,
}

impl BooruError {
    pub fn new(code: BooruErrorCode, source_id: Option<&str>, message_key: &str) -> Self {
        let sequence = DIAGNOSTIC_SEQUENCE.fetch_add(1, Ordering::Relaxed);
        Self {
            code,
            source_id: source_id.map(str::to_owned),
            user_message_key: message_key.to_owned(),
            diagnostic_id: format!("booru-{sequence:08x}"),
            http_status: None,
            retry_after_seconds: None,
            action: default_action(code),
            details: None,
        }
    }

    pub fn invalid_request(source_id: Option<&str>) -> Self {
        Self::new(
            BooruErrorCode::InvalidRequest,
            source_id,
            "booru.error.invalidRequest",
        )
    }

    pub fn invalid_response(source_id: &str) -> Self {
        Self::new(
            BooruErrorCode::InvalidResponse,
            Some(source_id),
            "booru.error.invalidResponse",
        )
    }

    pub fn with_details(mut self, details: String) -> Self {
        self.details = Some(details);
        self
    }

    pub fn with_http_status(mut self, status: u32) -> Self {
        self.http_status = Some(status);
        self
    }

    pub fn with_retry_after(mut self, seconds: Option<u32>) -> Self {
        self.retry_after_seconds = seconds;
        self
    }
}

impl Display for BooruError {
    fn fmt(&self, formatter: &mut Formatter<'_>) -> std::fmt::Result {
        write!(
            formatter,
            "{} [{}]",
            self.user_message_key, self.diagnostic_id
        )
    }
}

impl std::error::Error for BooruError {}

fn default_action(code: BooruErrorCode) -> Option<RecoveryAction> {
    match code {
        BooruErrorCode::AuthenticationRequired | BooruErrorCode::AuthenticationRejected => {
            Some(RecoveryAction::Login)
        }
        BooruErrorCode::RateLimited
        | BooruErrorCode::Network
        | BooruErrorCode::Timeout
        | BooruErrorCode::SourceUnavailable => Some(RecoveryAction::Retry),
        BooruErrorCode::ChallengeRequired => Some(RecoveryAction::SwitchSource),
        _ => None,
    }
}

pub type BooruResult<T> = Result<T, BooruError>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn older_error_records_allow_missing_details_and_new_details_round_trip() {
        let error = BooruError::new(
            BooruErrorCode::Internal,
            Some("aibooru"),
            "webChallenge.windowFailed",
        );
        let old_record = serde_json::to_value(&error).unwrap();
        assert!(old_record.get("details").is_none());
        let restored: BooruError = serde_json::from_value(old_record).unwrap();
        assert!(restored.details.is_none());
        let with_details = error.with_details("stage=webview-create\nHRESULT 0x8007139F".into());
        assert_eq!(
            serde_json::from_value::<BooruError>(serde_json::to_value(&with_details).unwrap())
                .unwrap(),
            with_details
        );
    }
}
