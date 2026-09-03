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
pub struct BooruErrorDto {
    pub code: BooruErrorCode,
    pub source_id: Option<String>,
    pub user_message_key: String,
    pub diagnostic_id: String,
    pub http_status: Option<u32>,
    pub retry_after_seconds: Option<u32>,
    pub action: Option<RecoveryAction>,
}

impl BooruErrorDto {
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

    pub fn with_http_status(mut self, status: u32) -> Self {
        self.http_status = Some(status);
        self
    }

    pub fn with_retry_after(mut self, seconds: Option<u32>) -> Self {
        self.retry_after_seconds = seconds;
        self
    }
}

impl Display for BooruErrorDto {
    fn fmt(&self, formatter: &mut Formatter<'_>) -> std::fmt::Result {
        write!(
            formatter,
            "{} [{}]",
            self.user_message_key, self.diagnostic_id
        )
    }
}

impl std::error::Error for BooruErrorDto {}

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

pub type BooruResult<T> = Result<T, BooruErrorDto>;
