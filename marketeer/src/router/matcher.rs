use crate::config::Route;
use anyhow::{anyhow, Result};
use pingora::http::RequestHeader;

pub struct Router {
    routes: Vec<Route>,
}

impl Router {
    pub fn new(routes: Vec<Route>) -> Self {
        Self { routes }
    }

    pub fn match_request(&self, headers: &RequestHeader) -> Result<&Route> {
        let host = headers
            .uri
            .host()
            .unwrap_or("");
        let path = headers.uri.path();
        let method = headers.method.as_str();

        for route in &self.routes {
            if self.matches_route(route, host, path, method, headers) {
                return Ok(route);
            }
        }

        Err(anyhow!("No route matched"))
    }

    fn matches_route(
        &self,
        route: &Route,
        host: &str,
        path: &str,
        method: &str,
        headers: &RequestHeader,
    ) -> bool {
        if let Some(route_host) = &route.r#match.host {
            if route_host != host && !self.wildcard_match(route_host, host) {
                return false;
            }
        }

        if let Some(route_path) = &route.r#match.path {
            if !self.path_match(route_path, path) {
                return false;
            }
        }

        if let Some(methods) = &route.r#match.method {
            if !methods.iter().any(|m| m.eq_ignore_ascii_case(method)) {
                return false;
            }
        }

        if let Some(header_matchers) = &route.r#match.headers {
            for (key, value) in header_matchers {
                let header_value = headers
                    .headers
                    .get(key)
                    .and_then(|v| v.to_str().ok())
                    .unwrap_or("");
                if header_value != value {
                    return false;
                }
            }
        }

        true
    }

    fn wildcard_match(&self, pattern: &str, value: &str) -> bool {
        if pattern.starts_with("*.") {
            let suffix = &pattern[2..];
            value.ends_with(suffix)
        } else {
            pattern == value
        }
    }

    fn path_match(&self, pattern: &str, path: &str) -> bool {
        if pattern.ends_with("/*") {
            let prefix = &pattern[..pattern.len() - 2];
            path.starts_with(prefix)
        } else {
            pattern == path
        }
    }
}
