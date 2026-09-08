use super::rules::rules;
use crate::api::web_challenge::WebChallengeCandidate;
use crate::booru::auth::session_store::{cookie_matches, merge_cookie_header};
use crate::booru::auth::SessionStore;
use crate::booru::error::{BooruError, BooruResult};
use reqwest::header::{HeaderMap, HeaderValue, USER_AGENT};
use reqwest::Url;
use std::collections::BTreeSet;

#[derive(Clone)]
pub struct ValidatedChallenge {
    pub source_id: String,
    pub material: WebChallengeCandidate,
    pub verified_at: String,
}

impl ValidatedChallenge {
    pub fn new(source: &str, mut candidate: WebChallengeCandidate) -> BooruResult<Self> {
        let rules = rules(source)?;
        if candidate.cookies.is_empty() == candidate.snapshots.is_empty()
            || candidate.user_agent.trim().is_empty()
            || candidate.user_agent.len() > 4096
            || HeaderValue::from_str(&candidate.user_agent).is_err()
        {
            return Err(BooruError::invalid_request(Some(source)));
        }
        candidate.user_agent = candidate.user_agent.trim().into();
        if !candidate.cookies.is_empty() {
            if candidate
                .cookies
                .iter()
                .any(|cookie| !rules.allows_cookie_domain(&cookie.domain))
            {
                return Err(BooruError::invalid_request(Some(source)));
            }
            let temporary = SessionStore::default();
            temporary.set_web_session(source, candidate.cookies, candidate.user_agent.clone())?;
            let snapshot = temporary
                .web_snapshot(source)?
                .ok_or_else(|| BooruError::invalid_request(Some(source)))?;
            candidate.cookies = snapshot.cookies;
            candidate.user_agent = snapshot.user_agent;
        } else {
            if candidate.snapshots.len() > rules.request_hosts.len() {
                return Err(BooruError::invalid_request(Some(source)));
            }
            let mut targets = BTreeSet::new();
            let mut size = 0;
            let mut count = 0;
            for snapshot in &candidate.snapshots {
                if !rules.request_hosts.contains(&snapshot.target_id.as_str())
                    || !targets.insert(&snapshot.target_id)
                {
                    return Err(BooruError::invalid_request(Some(source)));
                }
                size += snapshot.cookie_header.len();
                count += parse_snapshot(source, &snapshot.cookie_header)?.len();
            }
            if size > 64 * 1024 || count == 0 || count > 128 {
                return Err(BooruError::invalid_request(Some(source)));
            }
        }
        Ok(Self {
            source_id: source.into(),
            material: candidate,
            verified_at: String::new(),
        })
    }

    pub fn apply(&self, url: &Url, headers: &mut HeaderMap) -> BooruResult<()> {
        if !rules(&self.source_id)?.allows_request(url) {
            return Ok(());
        }
        if self.material.snapshots.is_empty() {
            let mut matching = self
                .material
                .cookies
                .iter()
                .filter(|cookie| cookie_matches(cookie, url))
                .collect::<Vec<_>>();
            matching.sort_by_key(|cookie| std::cmp::Reverse(cookie.path.len()));
            merge_cookie_header(
                headers,
                matching
                    .into_iter()
                    .map(|cookie| (cookie.name.as_str(), cookie.value.as_str())),
                &self.source_id,
            )?;
        } else if let Some(snapshot) = self
            .material
            .snapshots
            .iter()
            .find(|snapshot| Some(snapshot.target_id.as_str()) == url.host_str())
        {
            merge_cookie_header(
                headers,
                parse_snapshot(&self.source_id, &snapshot.cookie_header)?.into_iter(),
                &self.source_id,
            )?;
        }
        self.apply_user_agent(url, headers)
    }

    pub fn apply_user_agent(&self, url: &Url, headers: &mut HeaderMap) -> BooruResult<()> {
        if rules(&self.source_id)?.allows_request(url) {
            headers.insert(
                USER_AGENT,
                HeaderValue::from_str(&self.material.user_agent)
                    .map_err(|_| BooruError::invalid_request(Some(&self.source_id)))?,
            );
        }
        Ok(())
    }
}

fn parse_snapshot<'a>(source: &str, header: &'a str) -> BooruResult<Vec<(&'a str, &'a str)>> {
    if header.len() > 64 * 1024 {
        return Err(BooruError::invalid_request(Some(source)));
    }
    header.split(';').filter(|part| !part.trim().is_empty()).map(|part| {
        let (name, value) = part.trim().split_once('=').ok_or_else(|| BooruError::invalid_request(Some(source)))?;
        if name.is_empty() || !name.bytes().all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'-' | b'.'))
            || value.bytes().any(|byte| !matches!(byte, 0x21 | 0x23..=0x2b | 0x2d..=0x3a | 0x3c..=0x5b | 0x5d..=0x7e)) {
            return Err(BooruError::invalid_request(Some(source)));
        }
        Ok((name, value))
    }).collect()
}
