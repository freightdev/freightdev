use crate::config::{HealthCheckConfig, Service};
use anyhow::{anyhow, Result};
use dashmap::DashMap;
use pingora::prelude::*;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::time::interval;
use tracing::{debug, error, info, warn};

#[derive(Clone)]
struct EndpointHealth {
    healthy: bool,
    last_check: Instant,
    consecutive_failures: u32,
    consecutive_successes: u32,
}

impl Default for EndpointHealth {
    fn default() -> Self {
        Self {
            healthy: true,
            last_check: Instant::now(),
            consecutive_failures: 0,
            consecutive_successes: 0,
        }
    }
}

pub struct UpstreamPool {
    endpoints: Vec<String>,
    current: std::sync::atomic::AtomicUsize,
    health_status: Arc<DashMap<String, EndpointHealth>>,
    health_check_config: Option<HealthCheckConfig>,
}

impl UpstreamPool {
    pub fn new(service: Service) -> Self {
        let health_status = Arc::new(DashMap::new());

        for endpoint in &service.endpoints {
            health_status.insert(endpoint.clone(), EndpointHealth::default());
        }

        let pool = Self {
            endpoints: service.endpoints,
            current: std::sync::atomic::AtomicUsize::new(0),
            health_status: health_status.clone(),
            health_check_config: service.health_check.clone(),
        };

        if let Some(health_config) = &pool.health_check_config {
            let endpoints = pool.endpoints.clone();
            let health_status = health_status.clone();
            let health_config = health_config.clone();

            tokio::spawn(async move {
                Self::health_check_loop(endpoints, health_status, health_config).await;
            });
        }

        pool
    }

    async fn health_check_loop(
        endpoints: Vec<String>,
        health_status: Arc<DashMap<String, EndpointHealth>>,
        config: HealthCheckConfig,
    ) {
        let mut check_interval = interval(Duration::from_secs(config.interval));

        loop {
            check_interval.tick().await;

            for endpoint in &endpoints {
                let health_url = format!("{}{}", endpoint, config.path);

                match Self::check_endpoint(&health_url, config.timeout).await {
                    Ok(()) => {
                        if let Some(mut health) = health_status.get_mut(endpoint) {
                            health.consecutive_successes += 1;
                            health.consecutive_failures = 0;
                            health.last_check = Instant::now();

                            let threshold = config.healthy_threshold.unwrap_or(2);
                            if !health.healthy && health.consecutive_successes >= threshold {
                                health.healthy = true;
                                info!("Endpoint {} is now healthy", endpoint);
                            }
                        }
                    }
                    Err(e) => {
                        if let Some(mut health) = health_status.get_mut(endpoint) {
                            health.consecutive_failures += 1;
                            health.consecutive_successes = 0;
                            health.last_check = Instant::now();

                            let threshold = config.unhealthy_threshold.unwrap_or(3);
                            if health.healthy && health.consecutive_failures >= threshold {
                                health.healthy = false;
                                error!("Endpoint {} marked unhealthy: {}", endpoint, e);
                            }
                        }
                    }
                }
            }
        }
    }

    async fn check_endpoint(url: &str, timeout_secs: u64) -> Result<()> {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(timeout_secs))
            .build()?;

        let response = client.get(url).send().await?;

        if response.status().is_success() {
            Ok(())
        } else {
            Err(anyhow!("Health check failed with status: {}", response.status()))
        }
    }

    pub async fn select_peer(&self) -> Result<HttpPeer> {
        let healthy_endpoints: Vec<&String> = self
            .endpoints
            .iter()
            .filter(|endpoint| {
                self.health_status
                    .get(*endpoint)
                    .map(|h| h.healthy)
                    .unwrap_or(true)
            })
            .collect();

        if healthy_endpoints.is_empty() {
            warn!("No healthy endpoints available, falling back to all endpoints");
            let idx = self
                .current
                .fetch_add(1, std::sync::atomic::Ordering::Relaxed)
                % self.endpoints.len();

            let endpoint = &self.endpoints[idx];
            let peer = HttpPeer::new(endpoint, false, String::new());
            return Ok(peer);
        }

        let idx = self
            .current
            .fetch_add(1, std::sync::atomic::Ordering::Relaxed)
            % healthy_endpoints.len();

        let endpoint = healthy_endpoints[idx];
        debug!("Selected healthy endpoint: {}", endpoint);

        let peer = HttpPeer::new(endpoint, false, String::new());
        Ok(peer)
    }
}
