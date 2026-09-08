use super::{
    error,
    material::ValidatedChallenge,
    rules::RULES_VERSION,
    storage::{Record, Storage},
};
use crate::api::web_challenge::{WebChallengeCandidate, WebChallengeState};
use crate::booru::auth::SessionStore;
use crate::booru::error::{BooruErrorCode, BooruResult};
use std::collections::{HashMap, VecDeque};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock, Weak};
use std::time::{Duration, Instant};
use tokio_util::sync::CancellationToken;

#[derive(Clone)]
pub struct OperationLease {
    pub id: String,
    pub source: String,
    pub revision: u32,
    pub generation: u64,
    pub deadline: Instant,
    pub cancellation: CancellationToken,
}

struct Active {
    lease: OperationLease,
    window_open: bool,
    verifying: bool,
}
struct State {
    generation: u64,
    active: Option<Active>,
    committed: VecDeque<(String, WebChallengeState)>,
}

pub struct ChallengeCoordinator {
    pub sessions: Arc<SessionStore>,
    #[cfg(all(windows, feature = "web-challenge-window"))]
    pub support: PathBuf,
    storage: Storage,
    state: Mutex<State>,
    window_closed: tokio::sync::Notify,
}

static SHARED: OnceLock<Mutex<HashMap<PathBuf, Weak<ChallengeCoordinator>>>> = OnceLock::new();

impl ChallengeCoordinator {
    pub fn shared(directory: &str) -> BooruResult<Arc<Self>> {
        let path = Path::new(directory);
        if !path.is_absolute() {
            return Err(crate::booru::error::BooruError::invalid_request(None));
        }
        std::fs::create_dir_all(path)
            .map_err(|_| error("network", BooruErrorCode::Internal, "storageFailed"))?;
        let path = std::fs::canonicalize(path)
            .map_err(|_| error("network", BooruErrorCode::Internal, "storageFailed"))?;
        let mut shared = SHARED
            .get_or_init(Default::default)
            .lock()
            .map_err(|_| error("network", BooruErrorCode::Internal, "unavailable"))?;
        if let Some(owner) = shared.get(&path).and_then(Weak::upgrade) {
            return Ok(owner);
        }
        shared.retain(|_, owner| owner.strong_count() > 0);
        let owner = Arc::new(Self {
            sessions: Arc::new(SessionStore::default()),
            storage: Storage::new(&path),
            #[cfg(all(windows, feature = "web-challenge-window"))]
            support: path.clone(),
            state: Mutex::new(State {
                generation: 0,
                active: None,
                committed: VecDeque::with_capacity(16),
            }),
            window_closed: tokio::sync::Notify::new(),
        });
        shared.insert(path, Arc::downgrade(&owner));
        Ok(owner)
    }

    /// Engine recreation invalidates pending results from the previous transport.
    pub fn attach_engine(&self) -> BooruResult<u64> {
        let mut state = self.lock()?;
        state.generation = state.generation.wrapping_add(1);
        self.sessions.suspend_challenges()?;
        if let Some(active) = &state.active {
            active.lease.cancellation.cancel();
        }
        if state
            .active
            .as_ref()
            .is_some_and(|active| !active.window_open)
        {
            state.active = None;
        }
        Ok(state.generation)
    }

    pub fn begin(
        &self,
        source: &str,
        generation: u64,
        timeout: Duration,
    ) -> BooruResult<OperationLease> {
        super::rules::rules(source)?;
        let mut state = self.lock()?;
        if generation != state.generation {
            return Err(error(
                source,
                BooruErrorCode::Cancelled,
                "operationSuperseded",
            ));
        }
        if state
            .active
            .as_ref()
            .is_some_and(|active| !active.window_open && Instant::now() >= active.lease.deadline)
        {
            if let Some(active) = state.active.take() {
                active.lease.cancellation.cancel();
            }
        }
        if state.active.is_some() {
            return Err(error(source, BooruErrorCode::InvalidRequest, "busy"));
        }
        let mut bytes = [0_u8; 16];
        getrandom::fill(&mut bytes)
            .map_err(|_| error(source, BooruErrorCode::Internal, "unavailable"))?;
        let id = bytes.iter().map(|byte| format!("{byte:02x}")).collect();
        let lease = OperationLease {
            id,
            source: source.into(),
            revision: self.sessions.revision(source),
            generation,
            deadline: Instant::now() + timeout.min(Duration::from_secs(600)),
            cancellation: CancellationToken::new(),
        };
        state.active = Some(Active {
            lease: lease.clone(),
            window_open: false,
            verifying: false,
        });
        Ok(lease)
    }

    pub fn lease(&self, id: &str, generation: u64) -> BooruResult<OperationLease> {
        let state = self.lock()?;
        let active = state
            .active
            .as_ref()
            .filter(|active| active.lease.id == id)
            .ok_or_else(|| error("network", BooruErrorCode::Cancelled, "operationSuperseded"))?;
        self.check(&state, &active.lease, generation)?;
        Ok(active.lease.clone())
    }

    #[cfg(any(test, all(windows, feature = "web-challenge-window")))]
    pub fn open_window(&self, id: &str, generation: u64) -> BooruResult<OperationLease> {
        let lease = self.lease(id, generation)?;
        let mut state = self.lock()?;
        self.check(&state, &lease, generation)?;
        let active = state.active.as_mut().ok_or_else(|| {
            error(
                &lease.source,
                BooruErrorCode::Cancelled,
                "operationSuperseded",
            )
        })?;
        if active.window_open || active.verifying {
            return Err(error(&lease.source, BooruErrorCode::InvalidRequest, "busy"));
        }
        active.window_open = true;
        Ok(lease)
    }

    #[cfg(any(test, all(windows, feature = "web-challenge-window")))]
    pub fn did_close_window(&self, id: &str) {
        if let Ok(mut state) = self.state.lock() {
            if let Some(active) = state.active.as_mut().filter(|active| active.lease.id == id) {
                active.window_open = false;
                if active.lease.cancellation.is_cancelled() {
                    state.active = None;
                }
            }
        }
        self.window_closed.notify_waiters();
    }

    pub fn start_verifying(&self, id: &str, generation: u64) -> BooruResult<OperationLease> {
        let lease = self.lease(id, generation)?;
        let mut state = self.lock()?;
        self.check(&state, &lease, generation)?;
        let active = state.active.as_mut().ok_or_else(|| {
            error(
                &lease.source,
                BooruErrorCode::Cancelled,
                "operationSuperseded",
            )
        })?;
        if active.window_open || active.verifying {
            return Err(error(&lease.source, BooruErrorCode::InvalidRequest, "busy"));
        }
        active.verifying = true;
        Ok(lease)
    }

    pub fn end_verifying(&self, id: &str) {
        if let Ok(mut state) = self.state.lock() {
            if let Some(active) = state.active.as_mut().filter(|active| active.lease.id == id) {
                active.verifying = false;
            }
        }
    }

    pub fn committed(&self, id: &str) -> BooruResult<Option<WebChallengeState>> {
        Ok(self
            .lock()?
            .committed
            .iter()
            .find(|(key, _)| key == id)
            .map(|(_, result)| result.clone()))
    }

    pub fn commit(
        &self,
        lease: &OperationLease,
        mut challenge: ValidatedChallenge,
    ) -> BooruResult<WebChallengeState> {
        if challenge.source_id != lease.source {
            return Err(crate::booru::error::BooruError::invalid_request(Some(
                &lease.source,
            )));
        }
        if let Some(result) = self.committed(&lease.id)? {
            return Ok(result);
        }
        challenge.verified_at = time::OffsetDateTime::now_utc()
            .format(&time::format_description::well_known::Rfc3339)
            .map_err(|_| error(&lease.source, BooruErrorCode::Internal, "unavailable"))?;
        let record = Record {
            version: 1,
            rules_version: RULES_VERSION,
            source_id: lease.source.clone(),
            commit_id: lease.id.clone(),
            verified_at: Some(challenge.verified_at.clone()),
            material: Some(challenge.material.clone()),
        };
        let prepared = self.storage.prepare(&record)?;
        let response = WebChallengeState {
            source_id: lease.source.clone(),
            has_saved_data: true,
            verified: true,
            verified_at_iso8601: Some(challenge.verified_at.clone()),
            revision: lease.revision.wrapping_add(1),
        };
        let cached = (lease.id.clone(), response.clone());
        let mut state = self.lock()?;
        self.check(&state, lease, lease.generation)?;
        if state.committed.len() == 16 {
            state.committed.pop_front();
        }
        // This lock linearizes cancel, clear and network changes with the disk
        // commit. SessionStore also excludes concurrent manual credential edits.
        self.sessions
            .publish_challenge(challenge, lease.revision, || {
                if Instant::now() >= lease.deadline {
                    return Err(error(&lease.source, BooruErrorCode::Timeout, "timedOut"));
                }
                prepared.commit()
            })?;
        state.committed.push_back(cached);
        state.active = None;
        Ok(response)
    }

    pub fn cancel(&self, id: &str) -> BooruResult<()> {
        let mut state = self.lock()?;
        if let Some(active) = state.active.as_ref().filter(|active| active.lease.id == id) {
            active.lease.cancellation.cancel();
            if !active.window_open {
                state.active = None;
            }
        }
        Ok(())
    }

    pub fn clear(&self, source: &str) -> BooruResult<()> {
        let mut state = self.lock()?;
        if let Some(active) = state
            .active
            .as_ref()
            .filter(|active| active.lease.source == source)
        {
            active.lease.cancellation.cancel();
            if !active.window_open {
                state.active = None;
            }
        }
        let record = Record {
            version: 1,
            rules_version: RULES_VERSION,
            source_id: source.into(),
            commit_id: String::new(),
            verified_at: None,
            material: None,
        };
        let prepared = self.storage.prepare(&record)?;
        self.sessions
            .clear_challenge(source, || prepared.commit())?;
        state
            .committed
            .retain(|(_, result)| result.source_id != source);
        Ok(())
    }

    pub async fn wait_for_window_closed(&self, source: &str) -> BooruResult<()> {
        let deadline = tokio::time::Instant::now() + Duration::from_secs(30);
        loop {
            let notification = self.window_closed.notified();
            if !self
                .lock()?
                .active
                .as_ref()
                .is_some_and(|active| active.window_open && active.lease.source == source)
            {
                return Ok(());
            }
            tokio::time::timeout_at(deadline, notification)
                .await
                .map_err(|_| error(source, BooruErrorCode::Timeout, "cleanupFailed"))?;
        }
    }

    pub fn saved_candidate(&self, source: &str) -> BooruResult<Option<WebChallengeCandidate>> {
        Ok(self
            .storage
            .read(source)?
            .and_then(|record| record.material))
    }

    pub fn info(&self, source: &str) -> BooruResult<WebChallengeState> {
        let _state = self.lock()?;
        let record = self.storage.read(source)?;
        let active = self.sessions.challenge(source)?;
        Ok(WebChallengeState {
            source_id: source.into(),
            has_saved_data: record
                .as_ref()
                .is_some_and(|record| record.material.is_some()),
            verified: active.is_some(),
            verified_at_iso8601: active.map(|active| active.verified_at),
            revision: self.sessions.revision(source),
        })
    }

    fn check(&self, state: &State, lease: &OperationLease, generation: u64) -> BooruResult<()> {
        if generation != state.generation
            || lease.generation != state.generation
            || lease.cancellation.is_cancelled()
            || !state
                .active
                .as_ref()
                .is_some_and(|active| active.lease.id == lease.id)
        {
            return Err(error(
                &lease.source,
                BooruErrorCode::Cancelled,
                "operationSuperseded",
            ));
        }
        if Instant::now() >= lease.deadline {
            return Err(error(&lease.source, BooruErrorCode::Timeout, "timedOut"));
        }
        Ok(())
    }

    fn lock(&self) -> BooruResult<std::sync::MutexGuard<'_, State>> {
        self.state
            .lock()
            .map_err(|_| error("network", BooruErrorCode::Internal, "unavailable"))
    }
}
