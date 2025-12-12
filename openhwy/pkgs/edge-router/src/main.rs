use anyhow::Result;
use marketeer::{Config, MarketeerProxy};
use pingora::prelude::*;
use pingora_proxy::http_proxy_service;
use std::sync::Arc;
use tracing::{error, info};

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();

    info!("Starting Marketeer Edge Router");

    let config = Config::load("config/marketeer.yaml").await?;
    let config = Arc::new(config);

    info!("Configuration loaded successfully");

    let config_clone = config.clone();
    tokio::spawn(async move {
        if let Err(e) = Config::watch(config_clone).await {
            error!("Config watcher failed: {}", e);
        }
    });

    let mut server = Server::new(None).unwrap();
    server.bootstrap();

    let proxy = MarketeerProxy::new(config.clone());
    let mut proxy_service = http_proxy_service(&server.configuration, proxy);

    for http_config in &config.server.http {
        proxy_service.add_tcp(&http_config.listen.to_string());
        info!("HTTP listening on {}", http_config.listen);
    }

    for https_config in &config.server.https {
        if https_config.tls.auto {
            info!("Automatic HTTPS enabled for {}", https_config.listen);
        }
        proxy_service.add_tcp(&https_config.listen.to_string());
    }

    server.add_service(proxy_service);

    if config.admin.enabled {
        let admin_config = config.clone();
        tokio::spawn(async move {
            if let Err(e) = marketeer::admin::start_admin_server(admin_config).await {
                error!("Admin server failed: {}", e);
            }
        });
        info!("Admin API listening on {}", config.admin.listen);
    }

    info!("Marketeer is ready");

    server.run_forever();
}
