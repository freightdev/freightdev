// src/config/types.rs

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::SocketAddr;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Config {
    pub server: ServerConfig,
    pub admin: AdminConfig,
    pub logging: LoggingConfig,
    pub routes: Vec<Route>,
    pub services: HashMap<String, Service>,
    pub middlewares: HashMap<String, MiddlewareConfig>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ServerConfig {
    pub http: Vec<HttpListener>,
    pub https: Vec<HttpsListener>,
    pub graceful_shutdown: Option<u64>,
    pub max_connections: Option<usize>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct HttpListener {
    pub listen: SocketAddr,
    pub redirect_https: Option<bool>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct HttpsListener {
    pub listen: SocketAddr,
    pub tls: TlsConfig,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TlsConfig {
    pub auto: bool,
    pub email: Option<String>,
    pub cert_path: Option<String>,
    pub key_path: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Route {
    pub name: String,
    pub r#match: MatchConfig,
    pub backend: BackendConfig,
    pub middlewares: Option<Vec<String>>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct MatchConfig {
    pub host: Option<String>,
    pub path: Option<String>,
    pub method: Option<Vec<String>>,
    pub headers: Option<HashMap<String, String>>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum BackendConfig {
    #[serde(rename = "static")]
    Static {
        root: String,
        spa: Option<bool>,
        compression: Option<bool>,
    },
    #[serde(rename = "service")]
    Service {
        service: String,
        load_balancer: Option<String>,
        health_check: Option<HealthCheckConfig>,
    },
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct HealthCheckConfig {
    pub interval: u64,
    pub timeout: u64,
    pub path: String,
    pub unhealthy_threshold: Option<u32>,
    pub healthy_threshold: Option<u32>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Service {
    pub endpoints: Vec<String>,
    pub health_check: Option<HealthCheckConfig>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum MiddlewareConfig {
    #[serde(rename = "rate_limit")]
    RateLimit {
        requests_per_second: u32,
        burst: u32,
        key: String,
    },
    #[serde(rename = "jwt")]
    Jwt {
        secret: String,
        header: String,
        required_claims: Option<Vec<String>>,
    },
    #[serde(rename = "cors")]
    Cors {
        allow_origins: Vec<String>,
        allow_methods: Vec<String>,
        allow_headers: Vec<String>,
        max_age: Option<u64>,
    },
    #[serde(rename = "compress")]
    Compression {
        algorithms: Vec<String>,
        min_size: usize,
    },
    #[serde(rename = "cache")]
    Cache {
        ttl: u64,
        key: String,
        storage: String,
        max_size: Option<String>,
    },
    #[serde(rename = "headers")]
    Headers {
        add: HashMap<String, String>,
    },
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AdminConfig {
    pub enabled: bool,
    pub listen: SocketAddr,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
    pub access_log: Option<String>,
    pub error_log: Option<String>,
}
