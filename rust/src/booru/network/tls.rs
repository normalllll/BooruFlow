use reqwest::ClientBuilder;

pub(super) fn client_builder() -> ClientBuilder {
    let builder = reqwest::Client::builder();
    #[cfg(target_os = "android")]
    let builder = with_bundled_roots(builder);
    builder
}

pub(super) fn with_sni_bypass(builder: ClientBuilder, enabled: bool) -> ClientBuilder {
    builder
        .tls_sni(!enabled)
        .danger_accept_invalid_certs(enabled)
}

// reqwest 0.13 defaults to the platform verifier, which requires Android
// Kotlin/JNI initialization. Use Mozilla roots explicitly on Android so every
// Rust request also works independently of the Flutter Activity lifecycle.
// tls_certs_merge would still invoke the platform verifier; use certs_only.
#[cfg(any(target_os = "android", test))]
fn with_bundled_roots(builder: ClientBuilder) -> ClientBuilder {
    builder.tls_certs_only(webpki_root_certs::TLS_SERVER_ROOT_CERTS.iter().map(|cert| {
        reqwest::Certificate::from_der(cert.as_ref())
            .expect("bundled Mozilla root must be valid DER")
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    #[ignore = "requires public HTTPS endpoints; run without a TLS-intercepting proxy"]
    async fn bundled_roots_validate_public_certificates_and_reject_invalid_ones() {
        let client = with_bundled_roots(reqwest::Client::builder())
            .no_proxy()
            .timeout(std::time::Duration::from_secs(20))
            .build()
            .unwrap();
        client
            .get("https://example.com")
            .send()
            .await
            .unwrap()
            .error_for_status()
            .unwrap();
        for url in [
            "https://self-signed.badssl.com/",
            "https://wrong.host.badssl.com/",
        ] {
            let error = client.get(url).send().await.unwrap_err();
            let mut cause: &dyn std::error::Error = &error;
            let mut details = String::new();
            loop {
                details.push_str(&cause.to_string());
                match cause.source() {
                    Some(source) => cause = source,
                    None => break,
                }
            }
            assert!(
                details.contains("invalid peer certificate"),
                "{url}: {details}"
            );
            let bypass_client =
                with_sni_bypass(with_bundled_roots(reqwest::Client::builder()), true)
                    .no_proxy()
                    .timeout(std::time::Duration::from_secs(20))
                    .build()
                    .unwrap();
            // Without SNI the server may return a fallback virtual host. Any
            // HTTP response proves TLS accepted its otherwise invalid cert.
            bypass_client.get(url).send().await.unwrap();
        }
    }
}
