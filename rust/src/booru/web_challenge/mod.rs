mod coordinator;
pub mod material;
pub mod rules;
pub mod storage;
pub use coordinator::{ChallengeCoordinator, OperationLease};

#[cfg(test)]
mod tests;

#[cfg(all(windows, feature = "web-challenge-window"))]
pub mod window;

use crate::booru::error::{BooruError, BooruErrorCode};
pub fn error(source: &str, code: BooruErrorCode, key: &str) -> BooruError {
    BooruError::new(code, Some(source), &format!("webChallenge.{key}"))
}
