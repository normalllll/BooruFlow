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
