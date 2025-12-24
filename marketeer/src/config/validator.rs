// src/config/validator.rs

use super::{BackendConfig, Config};
use anyhow::{anyhow, Result};

pub struct ConfigValidator;

impl ConfigValidator {
    pub fn validate(config: &Config) -> Result<()> {
        for route in &config.routes {
            if let BackendConfig::Service { service, .. } = &route.backend {
                if !config.services.contains_key(service) {
                    return Err(anyhow!(
                        "Route '{}' references unknown service '{}'",
                        route.name,
                        service
                    ));
                }
            }

            if let Some(middlewares) = &route.middlewares {
                for mw in middlewares {
                    if !config.middlewares.contains_key(mw) {
                        return Err(anyhow!(
                            "Route '{}' references unknown middleware '{}'",
                            route.name,
                            mw
                        ));
                    }
                }
            }
        }

        Ok(())
    }
}
