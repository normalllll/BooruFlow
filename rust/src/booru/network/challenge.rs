use reqwest::header::HeaderMap;

pub fn looks_like_challenge(headers: &HeaderMap, body: &[u8], _expected_json: bool) -> bool {
    if headers
        .get("cf-mitigated")
        .and_then(|value| value.to_str().ok())
        .is_some_and(|value| value.eq_ignore_ascii_case("challenge"))
    {
        return true;
    }
    let prefix = String::from_utf8_lossy(&body[..body.len().min(4096)]).to_ascii_lowercase();
    // A login page or generic HTML error is not evidence of a CF challenge.
    prefix.contains("cf-chl-")
        || prefix.contains("/cdn-cgi/challenge-platform/")
        || prefix.contains("just a moment...")
}

#[cfg(test)]
mod tests {
    use super::*;
    use reqwest::header::{HeaderValue, CONTENT_TYPE};

    #[test]
    fn cloudflare_block_page_does_not_request_another_challenge() {
        let mut headers = HeaderMap::new();
        headers.insert("server", HeaderValue::from_static("cloudflare"));
        headers.insert("cf-ray", HeaderValue::from_static("test-ray"));
        headers.insert(
            CONTENT_TYPE,
            HeaderValue::from_static("text/html; charset=UTF-8"),
        );
        // Minimal public page markers observed for image 403 responses. A WAF
        // block is not a challenge and must not send users into verification.
        let block = br#"<!doctype html><title>Attention Required! | Cloudflare</title>
            <div id="cf-error-details"><h1>Sorry, you have been blocked</h1>
            <p>Please enable cookies.</p><h2>Why have I been blocked?</h2>
            <p>Cloudflare Ray ID:</p></div>"#;
        assert!(!looks_like_challenge(&headers, block, false));
        assert!(!looks_like_challenge(&headers, block, true));
        // Real challenge evidence still takes precedence over generic page text.
        headers.insert("cf-mitigated", HeaderValue::from_static("challenge"));
        assert!(looks_like_challenge(&headers, block, false));
    }

    #[test]
    fn detects_headers_and_html_for_json() {
        let mut headers = HeaderMap::new();
        headers.insert("cf-mitigated", HeaderValue::from_static("challenge"));
        assert!(looks_like_challenge(&headers, b"", false));

        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("text/html"));
        assert!(!looks_like_challenge(&headers, b"ordinary page", true));
        assert!(!looks_like_challenge(&headers, b"ordinary page", false));
        assert!(!looks_like_challenge(
            &HeaderMap::new(),
            b"<!doctype html><title>Login</title>",
            true
        ));
        assert!(looks_like_challenge(
            &headers,
            b"<html><script src='/cdn-cgi/challenge-platform/x'></script></html>",
            true
        ));
    }
}
