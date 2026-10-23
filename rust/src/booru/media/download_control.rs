use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use tokio::sync::watch;
use tokio_util::sync::CancellationToken;

#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum DownloadCommand {
    Running,
    Paused,
}

/// One transfer's control stays alive while paused, retaining only its partial
/// file and validator, not an HTTP connection or a background encoder thread.
pub(crate) struct DownloadControl {
    command: watch::Sender<DownloadCommand>,
    pub cancel: CancellationToken,
}
impl DownloadControl {
    pub fn new() -> Self {
        Self {
            command: watch::channel(DownloadCommand::Running).0,
            cancel: CancellationToken::new(),
        }
    }
    pub fn pause(&self) {
        self.command.send_replace(DownloadCommand::Paused);
    }
    pub fn resume(&self) {
        self.command.send_replace(DownloadCommand::Running);
    }
    pub fn is_paused(&self) -> bool {
        *self.command.borrow() == DownloadCommand::Paused
    }
    pub async fn interrupted(&self) {
        let mut command = self.command.subscribe();
        loop {
            if self.is_paused() || self.cancel.is_cancelled() {
                return;
            }
            tokio::select! { _ = self.cancel.cancelled() => return, _ = command.changed() => {} }
        }
    }
    pub async fn running(&self) -> BooruResult<()> {
        let mut command = self.command.subscribe();
        loop {
            if self.cancel.is_cancelled() {
                return Err(cancelled());
            }
            if !self.is_paused() {
                return Ok(());
            }
            tokio::select! { _ = self.cancel.cancelled() => return Err(cancelled()), _ = command.changed() => {} }
        }
    }
}
pub(crate) fn cancelled() -> BooruError {
    BooruError::new(BooruErrorCode::Cancelled, None, "booru.error.cancelled")
}
