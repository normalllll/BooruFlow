use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AuthFieldKind {
    Username,
    UserId,
    ApiKey,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AuthFieldDto {
    pub kind: AuthFieldKind,
    pub label_key: String,
    pub required: bool,
    pub secret: bool,
    pub help_url: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AuthSchemaDto {
    pub source_id: String,
    pub fields: Vec<AuthFieldDto>,
    pub uses_web_session: bool,
}

#[derive(Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceCredentialsDto {
    pub username: Option<String>,
    pub user_id: Option<String>,
    pub api_key: Option<String>,
}

#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WebCookieDto {
    pub name: String,
    pub value: String,
    pub domain: String,
    pub path: String,
    pub secure: bool,
    pub expires_at_iso8601: Option<String>,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
pub enum AuthStatus {
    #[default]
    NotConfigured,
    ConfiguredUnverified,
    Verified,
    Rejected,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AuthStateDto {
    pub source_id: String,
    pub status: AuthStatus,
    pub username: Option<String>,
    pub auth_revision: u32,
}
