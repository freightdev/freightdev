// src/admin/server.rs

use crate::Config;
use anyhow::Result;
use hyper::body::Bytes;
use hyper::server::conn::http1;
use hyper::service::service_fn;
use hyper::{Method, Request, Response, StatusCode};
use hyper::body::Incoming;
use http_body_util::Full;
use hyper_util::rt::TokioIo;
use std::sync::Arc;
use tokio::net::TcpListener;
use tracing::info;

pub async fn start_admin_server(config: Arc<Config>) -> Result<()> {
    let addr = config.admin.listen;
    let listener = TcpListener::bind(addr).await?;

    info!("Admin API listening on {}", addr);

    loop {
        let (stream, _) = listener.accept().await?;
        let io = TokioIo::new(stream);
        let config = config.clone();

        tokio::spawn(async move {
            if let Err(e) = http1::Builder::new()
                .serve_connection(
                    io,
                    service_fn(move |req| {
                        let config = config.clone();
                        handle_request(req, config)
                    }),
                )
                .await
            {
                eprintln!("Error serving connection: {:?}", e);
            }
        });
    }
}

async fn handle_request(
    req: Request<Incoming>,
    config: Arc<Config>,
) -> Result<Response<Full<Bytes>>, Box<dyn std::error::Error + Send + Sync>> {
    let response = match (req.method(), req.uri().path()) {
        (&Method::GET, "/health") => Response::builder()
            .status(StatusCode::OK)
            .header("Content-Type", "application/json")
            .body(Full::new(Bytes::from(r#"{"status":"healthy"}"#)))?,

        (&Method::GET, "/config") => {
            let config_json = serde_json::to_string_pretty(&*config).unwrap_or_default();
            Response::builder()
                .status(StatusCode::OK)
                .header("Content-Type", "application/json")
                .body(Full::new(Bytes::from(config_json)))?
        }

        (&Method::POST, "/reload") => Response::builder()
            .status(StatusCode::OK)
            .header("Content-Type", "application/json")
            .body(Full::new(Bytes::from(r#"{"reloaded":true}"#)))?,

        (&Method::GET, "/metrics") => Response::builder()
            .status(StatusCode::OK)
            .header("Content-Type", "text/plain")
            .body(Full::new(Bytes::from("# Prometheus metrics placeholder\n")))?,

        _ => Response::builder()
            .status(StatusCode::NOT_FOUND)
            .body(Full::new(Bytes::from("Not found")))?,
    };

    Ok(response)
}
