use super::{material::ValidatedChallenge, rules, ChallengeCoordinator};
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
