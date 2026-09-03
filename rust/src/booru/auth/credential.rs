use crate::api::booru_auth::{AuthFieldDto, AuthFieldKind, AuthSchemaDto, SourceCredentialsDto};
use crate::api::booru_models::AuthKind;
use crate::booru::error::{BooruErrorDto, BooruResult};

pub fn auth_schema(source_id: &str, kind: AuthKind) -> AuthSchemaDto {
    let field = |kind: AuthFieldKind, secret: bool, help_url: Option<&str>| {
        let key = match kind {
            AuthFieldKind::Username => "username",
            AuthFieldKind::UserId => "userId",
            AuthFieldKind::ApiKey => "apiKey",
        };
        AuthFieldDto {
            kind,
            label_key: format!("booru.auth.field.{key}"),
            required: true,
            secret,
            help_url: help_url.map(str::to_owned),
        }
    };
    let (fields, uses_web_session) = match kind {
        AuthKind::None => (Vec::new(), false),
        AuthKind::LoginApiKey => (
            vec![
                field(AuthFieldKind::Username, false, None),
                field(AuthFieldKind::ApiKey, true, None),
            ],
            false,
        ),
        AuthKind::UserIdApiKey => (
            vec![
                field(
                    AuthFieldKind::UserId,
                    false,
                    Some("https://gelbooru.com/index.php?page=account&s=options"),
                ),
                field(
                    AuthFieldKind::ApiKey,
                    true,
                    Some("https://gelbooru.com/index.php?page=account&s=options"),
                ),
            ],
            false,
        ),
        AuthKind::ApiKey => (
            vec![field(
                AuthFieldKind::ApiKey,
                true,
                Some("https://wallhaven.cc/settings/account"),
            )],
            false,
        ),
        AuthKind::WebSession => (Vec::new(), true),
    };
    AuthSchemaDto {
        source_id: source_id.to_owned(),
        fields,
        uses_web_session,
    }
}

pub fn validate_credentials(
    source_id: &str,
    kind: AuthKind,
    credentials: &SourceCredentialsDto,
) -> BooruResult<()> {
    let present = |value: &Option<String>| {
        value
            .as_deref()
            .is_some_and(|value| !value.trim().is_empty())
    };
    let safe = |value: &Option<String>| {
        value
            .as_deref()
            .is_none_or(|value| !value.chars().any(char::is_control))
    };
    let valid = match kind {
        AuthKind::None => false,
        AuthKind::LoginApiKey => present(&credentials.username) && present(&credentials.api_key),
        AuthKind::UserIdApiKey => {
            credentials.user_id.as_deref().is_some_and(|value| {
                !value.is_empty() && value.bytes().all(|byte| byte.is_ascii_digit())
            }) && present(&credentials.api_key)
        }
        AuthKind::ApiKey => present(&credentials.api_key),
        AuthKind::WebSession => false,
    } && safe(&credentials.username)
        && safe(&credentials.user_id)
        && safe(&credentials.api_key);
    if valid {
        Ok(())
    } else {
        Err(BooruErrorDto::invalid_request(Some(source_id)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn schemas_match_each_auth_contract() {
        assert!(auth_schema("yande", AuthKind::None).fields.is_empty());
        assert_eq!(
            auth_schema("danbooru", AuthKind::LoginApiKey)
                .fields
                .iter()
                .map(|field| field.kind)
                .collect::<Vec<_>>(),
            [AuthFieldKind::Username, AuthFieldKind::ApiKey]
        );
        assert_eq!(
            auth_schema("gelbooru", AuthKind::UserIdApiKey)
                .fields
                .iter()
                .map(|field| field.kind)
                .collect::<Vec<_>>(),
            [AuthFieldKind::UserId, AuthFieldKind::ApiKey]
        );
        assert_eq!(
            auth_schema("wallhaven", AuthKind::ApiKey).fields[0].kind,
            AuthFieldKind::ApiKey
        );
        assert!(auth_schema("anime_pictures", AuthKind::WebSession).uses_web_session);
    }

    #[test]
    fn gelbooru_user_id_must_be_decimal() {
        let credentials = SourceCredentialsDto {
            username: None,
            user_id: Some("../1".to_owned()),
            api_key: Some("key".to_owned()),
        };
        assert!(validate_credentials("gelbooru", AuthKind::UserIdApiKey, &credentials).is_err());
    }
}
