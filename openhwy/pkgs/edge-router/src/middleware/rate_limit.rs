use anyhow::{anyhow, Result};
use dashmap::DashMap;
use governor::{clock::DefaultClock, state::InMemoryState, Quota, RateLimiter};
use std::num::NonZeroU32;

pub struct RateLimitMiddleware {
    limiter: RateLimiter<String, DashMap<String, InMemoryState>, DefaultClock>,
}

impl RateLimitMiddleware {
    pub fn new(rps: u32, burst: u32) -> Self {
        let quota = Quota::per_second(NonZeroU32::new(rps).unwrap())
            .allow_burst(NonZeroU32::new(burst).unwrap());

        Self {
            limiter: RateLimiter::dashmap(quota),
        }
    }

    pub async fn check(&self, key: &str) -> Result<()> {
        match self.limiter.check_key(&key.to_string()) {
            Ok(_) => Ok(()),
            Err(_) => Err(anyhow!("Rate limit exceeded")),
        }
    }
}
