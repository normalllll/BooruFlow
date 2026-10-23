use super::{material::ValidatedChallenge, rules, ChallengeCoordinator};
use crate::api::booru_auth::WebCookie;
use crate::api::web_challenge::{WebChallengeCandidate, WebChallengeSnapshot};
use reqwest::header::{HeaderMap, COOKIE, USER_AGENT};
use std::time::Duration;

fn candidate() -> WebChallengeCandidate {
    WebChallengeCandidate {
        cookies: vec![],
        snapshots: vec![WebChallengeSnapshot {
            target_id: "konachan.com".into(),
            cookie_header: "cf_clearance=fixture==".into(),
        }],
        user_agent: "fixture-browser".into(),
    }
}

fn material() -> ValidatedChallenge {
    ValidatedChallenge::new("konachan_com", candidate()).unwrap()
}

#[test]
fn snapshot_preserves_equals_and_is_confined_to_exact_https_host() {
    let material = material();
    let mut headers = HeaderMap::new();
    material
        .apply(
            &"https://konachan.com/post.json".parse().unwrap(),
            &mut headers,
        )
        .unwrap();
    assert_eq!(headers[COOKIE], "cf_clearance=fixture==");
    assert_eq!(headers[USER_AGENT], "fixture-browser");
    for target in [
        "http://konachan.com/",
        "https://konachan.com:444/",
        "https://evil.konachan.com/",
        "https://konachan.net/",
    ] {
        let mut headers = HeaderMap::new();
        material
            .apply(&target.parse().unwrap(), &mut headers)
            .unwrap();
        assert!(headers.is_empty());
    }
    let mut headers = HeaderMap::new();
    material
        .apply(&"https://www.konachan.com/".parse().unwrap(), &mut headers)
        .unwrap();
    assert!(!headers.contains_key(COOKIE));
}

#[test]
fn malformed_and_unregistered_snapshots_are_rejected() {
    for header in [
        "bad",
        "name=a\r\nX: injected",
        "name=a b",
        "=value",
        "name=\"quoted\"",
    ] {
        let mut value = candidate();
        value.snapshots[0].cookie_header = header.into();
        assert!(ValidatedChallenge::new("konachan_com", value).is_err());
    }
    let mut value = candidate();
    value.snapshots[0].target_id = "evil.konachan.com".into();
    assert!(ValidatedChallenge::new("konachan_com", value).is_err());
    let mut value = candidate();
    value.snapshots.push(value.snapshots[0].clone());
    assert!(ValidatedChallenge::new("konachan_com", value).is_err());
    assert!(!rules::rules("konachan_com")
        .unwrap()
        .allows_cookie_domain("evil.konachan.com"));
}

#[test]
fn durable_commit_restart_and_clear_tombstone() {
    let directory = tempfile::tempdir().unwrap();
    let path = directory.path().to_str().unwrap();
    let owner = ChallengeCoordinator::shared(path).unwrap();
    let generation = owner.attach_engine().unwrap();
    let lease = owner
        .begin("konachan_com", generation, Duration::from_secs(30))
        .unwrap();
    let committed = owner.commit(&lease, material()).unwrap();
    assert!(committed.verified && committed.has_saved_data);
    assert_eq!(
        owner.commit(&lease, material()).unwrap().revision,
        committed.revision
    );
    drop(owner);
    let restarted = ChallengeCoordinator::shared(path).unwrap();
    let info = restarted.info("konachan_com").unwrap();
    assert!(info.has_saved_data);
    assert!(!info.verified); // Restored data must pass real network verification first.
    assert!(restarted.saved_candidate("konachan_com").unwrap().is_some());
    restarted.clear("konachan_com").unwrap();
    assert!(restarted.saved_candidate("konachan_com").unwrap().is_none());
    drop(restarted);
    assert!(
        !ChallengeCoordinator::shared(path)
            .unwrap()
            .info("konachan_com")
            .unwrap()
            .has_saved_data
    );
}

#[test]
fn cancellation_clear_and_engine_change_reject_late_commit() {
    for action in 0..3 {
        let directory = tempfile::tempdir().unwrap();
        let owner = ChallengeCoordinator::shared(directory.path().to_str().unwrap()).unwrap();
        let generation = owner.attach_engine().unwrap();
        let initial = owner
            .begin("konachan_com", generation, Duration::from_secs(30))
            .unwrap();
        owner.commit(&initial, material()).unwrap();
        let pending = owner
            .begin("konachan_com", generation, Duration::from_secs(30))
            .unwrap();
        match action {
            0 => owner.cancel(&pending.id).unwrap(),
            1 => owner.clear("konachan_com").unwrap(),
            _ => {
                owner.attach_engine().unwrap();
            }
        }
        assert!(owner.commit(&pending, material()).is_err());
        assert_eq!(
            owner.info("konachan_com").unwrap().has_saved_data,
            action != 1
        );
    }
}

#[test]
fn open_window_blocks_replacement_until_cleanup_finishes() {
    let directory = tempfile::tempdir().unwrap();
    let owner = ChallengeCoordinator::shared(directory.path().to_str().unwrap()).unwrap();
    let generation = owner.attach_engine().unwrap();
    let lease = owner
        .begin("konachan_com", generation, Duration::from_secs(30))
        .unwrap();
    owner.open_window(&lease.id, generation).unwrap();
    owner.cancel(&lease.id).unwrap();
    assert!(owner
        .begin("yande", generation, Duration::from_secs(30))
        .is_err());
    owner.did_close_window(&lease.id);
    assert!(owner
        .begin("yande", generation, Duration::from_secs(30))
        .is_ok());
}

#[test]
fn expired_operation_does_not_write_session() {
    let directory = tempfile::tempdir().unwrap();
    let owner = ChallengeCoordinator::shared(directory.path().to_str().unwrap()).unwrap();
    let generation = owner.attach_engine().unwrap();
    let lease = owner
        .begin("konachan_com", generation, Duration::ZERO)
        .unwrap();
    assert!(owner.commit(&lease, material()).is_err());
    assert!(!owner.info("konachan_com").unwrap().has_saved_data);
}

#[cfg(windows)]
#[test]
fn failed_atomic_replacement_preserves_saved_and_live_session() {
    use std::os::windows::fs::OpenOptionsExt;
    let directory = tempfile::tempdir().unwrap();
    let owner = ChallengeCoordinator::shared(directory.path().to_str().unwrap()).unwrap();
    let generation = owner.attach_engine().unwrap();
    let first = owner
        .begin("konachan_com", generation, Duration::from_secs(30))
        .unwrap();
    let previous = owner.commit(&first, material()).unwrap();
    let path = directory
        .path()
        .join("web-verification/sessions-v1/konachan_com.session");
    let old_bytes = std::fs::read(&path).unwrap();
    let locked = std::fs::OpenOptions::new()
        .read(true)
        .share_mode(1)
        .open(&path)
        .unwrap();
    let next = owner
        .begin("konachan_com", generation, Duration::from_secs(30))
        .unwrap();
    let mut replacement = candidate();
    replacement.user_agent = "replacement-browser".into();
    let replacement = ValidatedChallenge::new("konachan_com", replacement).unwrap();
    assert!(owner.commit(&next, replacement.clone()).is_err());
    assert_eq!(std::fs::read(&path).unwrap(), old_bytes);
    assert_eq!(
        owner.info("konachan_com").unwrap().revision,
        previous.revision
    );
    assert_eq!(
        owner
            .sessions
            .challenge("konachan_com")
            .unwrap()
            .unwrap()
            .material
            .user_agent,
        "fixture-browser"
    );
    drop(locked);
    assert_eq!(
        owner.commit(&next, replacement).unwrap().revision,
        previous.revision + 1
    );
}

fn aibooru_cookies(domains: &[&str]) -> WebChallengeCandidate {
    WebChallengeCandidate {
        cookies: domains
            .iter()
            .map(|domain| WebCookie {
                name: "cf_clearance".into(),
                value: "synthetic-test-marker".into(),
                domain: (*domain).into(),
                path: "/".into(),
                secure: true,
                expires_at_iso8601: None,
            })
            .collect(),
        snapshots: vec![],
        user_agent: "synthetic-browser".into(),
    }
}

#[test]
fn aibooru_parent_cookie_is_retained_and_applied_only_to_the_registered_cdn() {
    let material = ValidatedChallenge::new("aibooru", aibooru_cookies(&[".aibooru.download"]))
        .expect("registered CDN parent cookie must survive capture validation");
    let mut headers = HeaderMap::new();
    material
        .apply(
            &"https://cdn.aibooru.download/sample/test.jpg"
                .parse()
                .unwrap(),
            &mut headers,
        )
        .unwrap();
    assert_eq!(headers[COOKIE], "cf_clearance=synthetic-test-marker");
    assert_eq!(headers[USER_AGENT], "synthetic-browser");
    let mut api = HeaderMap::new();
    material
        .apply(
            &"https://aibooru.online/posts.json".parse().unwrap(),
            &mut api,
        )
        .unwrap();
    assert!(!api.contains_key(COOKIE));
    // Accepting parent-domain material must not authorize additional destinations.
    for url in [
        "https://aibooru.download/",
        "https://other.aibooru.download/",
        "https://cdn.aibooru.download.evil.test/",
        "http://cdn.aibooru.download/",
        "https://cdn.aibooru.download:444/",
        "https://cdn.donmai.us/",
    ] {
        let mut headers = HeaderMap::new();
        headers.insert(USER_AGENT, "default-app-agent".parse().unwrap());
        material.apply(&url.parse().unwrap(), &mut headers).unwrap();
        assert!(
            !headers.contains_key(COOKIE),
            "cookie escaped registered destination: {url}"
        );
        assert_eq!(headers[USER_AGENT], "default-app-agent");
    }
}

#[test]
fn aibooru_api_cookie_does_not_become_a_cdn_cookie() {
    let material =
        ValidatedChallenge::new("aibooru", aibooru_cookies(&[".aibooru.online"])).unwrap();
    let mut api = HeaderMap::new();
    material
        .apply(
            &"https://aibooru.online/posts.json".parse().unwrap(),
            &mut api,
        )
        .unwrap();
    assert_eq!(api[COOKIE], "cf_clearance=synthetic-test-marker");
    let mut cdn = HeaderMap::new();
    material
        .apply(
            &"https://cdn.aibooru.download/sample/test.jpg"
                .parse()
                .unwrap(),
            &mut cdn,
        )
        .unwrap();
    assert!(!cdn.contains_key(COOKIE));
}

#[test]
fn aibooru_cookie_allowlist_does_not_accept_unrelated_parents_or_sources() {
    let rule = rules::rules("aibooru").unwrap();
    for domain in [
        ".aibooru.online",
        ".aibooru.download",
        "cdn.aibooru.download",
    ] {
        assert!(
            rule.allows_cookie_domain(domain),
            "registered domain: {domain}"
        );
    }
    for domain in [
        ".download",
        ".online",
        ".other.aibooru.download",
        ".aibooru.download.evil.test",
        ".donmai.us",
    ] {
        assert!(!rule.allows_cookie_domain(domain));
        assert!(ValidatedChallenge::new("aibooru", aibooru_cookies(&[domain])).is_err());
    }
    assert!(ValidatedChallenge::new("danbooru", aibooru_cookies(&[".aibooru.download"])).is_err());
}

#[test]
fn aibooru_cdn_snapshot_is_exact_and_never_borrows_the_api_snapshot() {
    for cdn_cookie in ["", "cf_clearance=synthetic-cdn-marker"] {
        let material = ValidatedChallenge::new(
            "aibooru",
            WebChallengeCandidate {
                cookies: vec![],
                snapshots: vec![
                    WebChallengeSnapshot {
                        target_id: "aibooru.online".into(),
                        cookie_header: "api_session=synthetic-api-marker".into(),
                    },
                    WebChallengeSnapshot {
                        target_id: "cdn.aibooru.download".into(),
                        cookie_header: cdn_cookie.into(),
                    },
                ],
                user_agent: "synthetic-browser".into(),
            },
        )
        .unwrap();
        let mut api = HeaderMap::new();
        material
            .apply(
                &"https://aibooru.online/posts.json".parse().unwrap(),
                &mut api,
            )
            .unwrap();
        assert_eq!(api[COOKIE], "api_session=synthetic-api-marker");
        let mut cdn = HeaderMap::new();
        material
            .apply(
                &"https://cdn.aibooru.download/sample/test.jpg"
                    .parse()
                    .unwrap(),
                &mut cdn,
            )
            .unwrap();
        assert_eq!(
            cdn.get(COOKIE).map(|v| v.to_str().unwrap()),
            if cdn_cookie.is_empty() {
                None
            } else {
                Some(cdn_cookie)
            }
        );
        let mut sibling = HeaderMap::new();
        material
            .apply(
                &"https://other.aibooru.download/".parse().unwrap(),
                &mut sibling,
            )
            .unwrap();
        assert!(sibling.is_empty());
    }
    for target in ["aibooru.download", "other.aibooru.download"] {
        assert!(ValidatedChallenge::new(
            "aibooru",
            WebChallengeCandidate {
                cookies: vec![],
                snapshots: vec![WebChallengeSnapshot {
                    target_id: target.into(),
                    cookie_header: "cf_clearance=synthetic-test-marker".into()
                }],
                user_agent: "synthetic-browser".into(),
            }
        )
        .is_err());
    }
}

#[test]
fn aibooru_snapshot_targets_keep_the_exact_api_and_cdn_hosts() {
    let source = crate::booru::source::builtin_sources()
        .into_iter()
        .find(|source| source.id == "aibooru")
        .unwrap();
    let spec = rules::spec(&source).unwrap();
    assert_eq!(
        spec.navigation_hosts,
        ["aibooru.online", "cdn.aibooru.download"]
    );
    let targets = spec
        .capture_targets
        .iter()
        .map(|target| (target.id.as_str(), target.url.as_str()))
        .collect::<Vec<_>>();
    assert_eq!(
        targets,
        [
            ("aibooru.online", "https://aibooru.online/"),
            ("cdn.aibooru.download", "https://cdn.aibooru.download/"),
        ]
    );
}
