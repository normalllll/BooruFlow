use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::{Mutex, OwnedSemaphorePermit, Semaphore};

#[derive(Debug)]
pub struct RateLimiter {
    semaphore: Arc<Semaphore>,
    min_interval: Duration,
    last_request: Mutex<Option<Instant>>,
}

impl RateLimiter {
    pub fn new(requests_per_minute: u32, max_concurrency: u32) -> Self {
        let interval_ms = if requests_per_minute == 0 {
            0
        } else {
            60_000 / u64::from(requests_per_minute)
        };
        Self {
            semaphore: Arc::new(Semaphore::new(max_concurrency.max(1) as usize)),
            min_interval: Duration::from_millis(interval_ms),
            last_request: Mutex::new(None),
        }
    }

    pub async fn acquire(&self) -> Result<OwnedSemaphorePermit, ()> {
        let permit = self
            .semaphore
            .clone()
            .acquire_owned()
            .await
            .map_err(|_| ())?;
        let mut last = self.last_request.lock().await;
        if let Some(last_request) = *last {
            let elapsed = last_request.elapsed();
            if elapsed < self.min_interval {
                tokio::time::sleep(self.min_interval - elapsed).await;
            }
        }
        *last = Some(Instant::now());
        Ok(permit)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test(start_paused = true)]
    async fn spaces_requests_to_the_configured_rate() {
        let limiter = Arc::new(RateLimiter::new(60, 2));
        drop(limiter.acquire().await.unwrap());
        let waiting = {
            let limiter = limiter.clone();
            tokio::spawn(async move { limiter.acquire().await.unwrap() })
        };
        tokio::task::yield_now().await;
        assert!(!waiting.is_finished());
        tokio::time::advance(Duration::from_secs(1)).await;
        drop(waiting.await.unwrap());
    }

    #[tokio::test]
    async fn semaphore_bounds_concurrency() {
        let limiter = Arc::new(RateLimiter::new(0, 1));
        let first = limiter.acquire().await.unwrap();
        let waiting = {
            let limiter = limiter.clone();
            tokio::spawn(async move { limiter.acquire().await.unwrap() })
        };
        tokio::task::yield_now().await;
        assert!(!waiting.is_finished());
        drop(first);
        drop(waiting.await.unwrap());
    }
}
