use reqwest::header::HeaderMap;

pub fn looks_like_challenge(headers: &HeaderMap, body: &[u8], expected_json: bool) -> bool {
    if headers
        .get("cf-mitigated")
        .and_then(|value| value.to_str().ok())
        .is_some_and(|value| value.eq_ignore_ascii_case("challenge"))
    {
        return true;
    }
    let content_type = headers
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|value| value.to_str().ok())
        .unwrap_or_default()
        .to_ascii_lowercase();
    let prefix = String::from_utf8_lossy(&body[..body.len().min(4096)]).to_ascii_lowercase();
    (expected_json
        && (content_type.contains("text/html")
            || prefix.trim_start().starts_with("<!doctype html")
            || prefix.trim_start().starts_with("<html")))
        || prefix.contains("cf-chl-")
        || prefix.contains("cloudflare ray id")
        || prefix.contains("just a moment...")
}

#[cfg(test)]
mod tests {
    use super::*;
    use reqwest::header::{HeaderValue, CONTENT_TYPE};

    #[test]
    fn detects_headers_and_html_for_json() {
        let mut headers = HeaderMap::new();
        headers.insert("cf-mitigated", HeaderValue::from_static("challenge"));
        assert!(looks_like_challenge(&headers, b"", false));

        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("text/html"));
        assert!(looks_like_challenge(&headers, b"ordinary page", true));
        assert!(!looks_like_challenge(&headers, b"ordinary page", false));
        assert!(looks_like_challenge(
            &HeaderMap::new(),
            b"<!doctype html><title>Login</title>",
            true
        ));
    }
}
