use crate::config::{BackendConfig, Config, MiddlewareConfig};
use crate::router::Router;
use crate::proxy::UpstreamPool;
use crate::middleware::{CorsMiddleware, JwtMiddleware, RateLimitMiddleware};
use crate::static_serve::StaticFileServer;
use async_trait::async_trait;
use dashmap::DashMap;
use pingora::prelude::*;
use pingora_proxy::{ProxyHttp, Session};
use std::sync::Arc;

fn convert_error(msg: impl std::fmt::Display) -> Box<Error> {
    Error::explain(ErrorType::InternalError, msg.to_string())
}

pub struct MarketeerProxy {
    config: Arc<Config>,
    router: Arc<Router>,
    upstreams: Arc<DashMap<String, UpstreamPool>>,
    rate_limiters: Arc<DashMap<String, RateLimitMiddleware>>,
    jwt_validators: Arc<DashMap<String, JwtMiddleware>>,
    cors_handlers: Arc<DashMap<String, CorsMiddleware>>,
    static_servers: Arc<DashMap<String, StaticFileServer>>,
}

impl MarketeerProxy {
    pub fn new(config: Arc<Config>) -> Self {
        let router = Arc::new(Router::new(config.routes.clone()));
        let upstreams = Arc::new(DashMap::new());
        let rate_limiters = Arc::new(DashMap::new());
        let jwt_validators = Arc::new(DashMap::new());
        let cors_handlers = Arc::new(DashMap::new());
        let static_servers = Arc::new(DashMap::new());

        // Initialize upstream pools
        for (name, service) in &config.services {
            let pool = UpstreamPool::new(service.clone());
            upstreams.insert(name.clone(), pool);
        }

        // Initialize middleware instances
        for (name, middleware_config) in &config.middlewares {
            match middleware_config {
                MiddlewareConfig::RateLimit { requests_per_second, burst, .. } => {
                    let limiter = RateLimitMiddleware::new(*requests_per_second, *burst);
                    rate_limiters.insert(name.clone(), limiter);
                }
                MiddlewareConfig::Jwt { secret, header, .. } => {
                    let validator = JwtMiddleware::new(secret.clone(), header.clone());
                    jwt_validators.insert(name.clone(), validator);
                }
                MiddlewareConfig::Cors { allow_origins, allow_methods, allow_headers, max_age } => {
                    let cors = CorsMiddleware::new(
                        allow_origins.clone(),
                        allow_methods.clone(),
                        allow_headers.clone(),
                        *max_age,
                    );
                    cors_handlers.insert(name.clone(), cors);
                }
                _ => {}
            }
        }

        // Initialize static file servers for static backends
        for route in &config.routes {
            if let BackendConfig::Static { root, spa, .. } = &route.backend {
                let server = StaticFileServer::new(root.clone(), spa.unwrap_or(false));
                static_servers.insert(route.name.clone(), server);
            }
        }

        Self {
            config,
            router,
            upstreams,
            rate_limiters,
            jwt_validators,
            cors_handlers,
            static_servers,
        }
    }
}

pub struct RequestContext {
    route_name: String,
    matched_route: Option<String>,
}

#[async_trait]
impl ProxyHttp for MarketeerProxy {
    type CTX = RequestContext;

    fn new_ctx(&self) -> Self::CTX {
        RequestContext {
            route_name: String::new(),
            matched_route: None,
        }
    }

    async fn request_filter(
        &self,
        session: &mut Session,
        ctx: &mut Self::CTX,
    ) -> pingora::Result<bool> {
        // Match the route
        let matched_route = match self.router.match_request(session.req_header()) {
            Ok(route) => route,
            Err(_) => {
                let mut response = pingora::http::ResponseHeader::build(404, None)?;
                response.insert_header("Content-Type", "text/plain")?;
                session.write_response_header(Box::new(response), false).await?;
                session.write_response_body(Some("Route not found".into()), true).await?;
                return Ok(true);
            }
        };

        ctx.route_name = matched_route.name.clone();
        ctx.matched_route = Some(matched_route.name.clone());

        // Apply middleware chain
        if let Some(middleware_names) = &matched_route.middlewares {
            for mw_name in middleware_names {
                let mw_config = self.config.middlewares.get(mw_name);

                if let Some(config) = mw_config {
                    match config {
                        MiddlewareConfig::RateLimit { key, .. } => {
                            if let Some(limiter) = self.rate_limiters.get(mw_name) {
                                // Extract rate limit key from request
                                let rate_key = match key.as_str() {
                                    "ip" => {
                                        session.client_addr()
                                            .map(|a| a.to_string())
                                            .unwrap_or_else(|| "unknown".to_string())
                                    }
                                    "header" => {
                                        session.req_header()
                                            .headers
                                            .get("X-Rate-Limit-Key")
                                            .and_then(|v| v.to_str().ok())
                                            .unwrap_or("default")
                                            .to_string()
                                    }
                                    _ => "default".to_string(),
                                };

                                if let Err(_) = limiter.check(&rate_key).await {
                                    let mut response = pingora::http::ResponseHeader::build(429, None)?;
                                    response.insert_header("Content-Type", "application/json")?;
                                    response.insert_header("Retry-After", "60")?;
                                    session.write_response_header(Box::new(response), false).await?;
                                    session.write_response_body(
                                        Some(r#"{"error":"Rate limit exceeded"}"#.into()),
                                        true
                                    ).await?;
                                    return Ok(true);
                                }
                            }
                        }
                        MiddlewareConfig::Jwt { header, .. } => {
                            if let Some(validator) = self.jwt_validators.get(mw_name) {
                                let auth_header = session.req_header()
                                    .headers
                                    .get(header)
                                    .and_then(|v| v.to_str().ok())
                                    .unwrap_or("");

                                let token = match validator.extract_token(auth_header) {
                                    Some(t) => t,
                                    None => {
                                        let mut response = pingora::http::ResponseHeader::build(401, None)?;
                                        response.insert_header("Content-Type", "application/json")?;
                                        session.write_response_header(Box::new(response), false).await?;
                                        session.write_response_body(
                                            Some(r#"{"error":"Missing or invalid authorization header"}"#.into()),
                                            true
                                        ).await?;
                                        return Ok(true);
                                    }
                                };

                                if let Err(_) = validator.validate(token) {
                                    let mut response = pingora::http::ResponseHeader::build(403, None)?;
                                    response.insert_header("Content-Type", "application/json")?;
                                    session.write_response_header(Box::new(response), false).await?;
                                    session.write_response_body(
                                        Some(r#"{"error":"Invalid or expired token"}"#.into()),
                                        true
                                    ).await?;
                                    return Ok(true);
                                }
                            }
                        }
                        _ => {}
                    }
                }
            }
        }

        // Handle static file serving
        if let BackendConfig::Static { .. } = &matched_route.backend {
            if let Some(server) = self.static_servers.get(&matched_route.name) {
                let path = session.req_header().uri.path();

                match server.serve(path).await {
                    Ok(content) => {
                        let mime_type = server.get_mime_type(path);
                        let mut response = pingora::http::ResponseHeader::build(200, None)?;
                        response.insert_header("Content-Type", mime_type)?;
                        response.insert_header("Content-Length", &content.len().to_string())?;

                        session.write_response_header(Box::new(response), false).await?;
                        session.write_response_body(Some(content.into()), true).await?;
                        return Ok(true);
                    }
                    Err(_) => {
                        let mut response = pingora::http::ResponseHeader::build(404, None)?;
                        response.insert_header("Content-Type", "text/plain")?;
                        session.write_response_header(Box::new(response), false).await?;
                        session.write_response_body(Some("File not found".into()), true).await?;
                        return Ok(true);
                    }
                }
            }
        }

        Ok(false)
    }

    async fn upstream_peer(
        &self,
        session: &mut Session,
        _ctx: &mut Self::CTX,
    ) -> pingora::Result<Box<HttpPeer>> {
        let matched_route = self.router.match_request(session.req_header())
            .map_err(|e| convert_error(e))?;

        match &matched_route.backend {
            BackendConfig::Service { service, .. } => {
                let pool = self
                    .upstreams
                    .get(service)
                    .ok_or_else(|| Error::new(ErrorType::InternalError))?;

                let peer = pool.select_peer().await
                    .map_err(|e| convert_error(e))?;
                Ok(Box::new(peer))
            }
            BackendConfig::Static { .. } => {
                Err(Error::new(ErrorType::InternalError))
            }
        }
    }

    async fn response_filter(
        &self,
        session: &mut Session,
        upstream_response: &mut pingora::http::ResponseHeader,
        ctx: &mut Self::CTX,
    ) -> pingora::Result<()> {
        // Add security headers
        upstream_response.insert_header("X-Frame-Options", "DENY")?;
        upstream_response.insert_header("X-Content-Type-Options", "nosniff")?;

        // Apply CORS if configured
        if let Some(route_name) = &ctx.matched_route {
            let matched_route = self.config.routes.iter()
                .find(|r| &r.name == route_name);

            if let Some(route) = matched_route {
                if let Some(middleware_names) = &route.middlewares {
                    for mw_name in middleware_names {
                        if let Some(cors) = self.cors_handlers.get(mw_name) {
                            let origin = session.req_header()
                                .headers
                                .get("Origin")
                                .and_then(|v| v.to_str().ok())
                                .unwrap_or("");

                            if cors.is_origin_allowed(origin) {
                                upstream_response.insert_header("Access-Control-Allow-Origin", origin)?;
                                upstream_response.insert_header(
                                    "Access-Control-Allow-Methods",
                                    &cors.allow_methods.join(", ")
                                )?;
                                upstream_response.insert_header(
                                    "Access-Control-Allow-Headers",
                                    &cors.allow_headers.join(", ")
                                )?;

                                if let Some(max_age) = cors.max_age {
                                    upstream_response.insert_header(
                                        "Access-Control-Max-Age",
                                        &max_age.to_string()
                                    )?;
                                }
                            }
                        }
                    }
                }
            }
        }

        Ok(())
    }
}
