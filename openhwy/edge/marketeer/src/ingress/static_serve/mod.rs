use anyhow::{anyhow, Result};
use std::path::PathBuf;
use tokio::fs;

pub struct StaticFileServer {
    root: PathBuf,
    spa_mode: bool,
}

impl StaticFileServer {
    pub fn new(root: String, spa_mode: bool) -> Self {
        Self {
            root: PathBuf::from(root),
            spa_mode,
        }
    }

    pub async fn serve(&self, path: &str) -> Result<Vec<u8>> {
        let mut file_path = self.root.join(path.trim_start_matches('/'));

        if file_path.is_file() {
            return fs::read(&file_path).await.map_err(Into::into);
        }

        file_path.push("index.html");
        if file_path.is_file() {
            return fs::read(&file_path).await.map_err(Into::into);
        }

        if self.spa_mode {
            let index = self.root.join("index.html");
            return fs::read(&index).await.map_err(Into::into);
        }

        Err(anyhow!("File not found"))
    }

    pub fn get_mime_type(&self, path: &str) -> &'static str {
        if path.ends_with(".html") {
            "text/html"
        } else if path.ends_with(".css") {
            "text/css"
        } else if path.ends_with(".js") {
            "application/javascript"
        } else if path.ends_with(".json") {
            "application/json"
        } else if path.ends_with(".png") {
            "image/png"
        } else if path.ends_with(".jpg") || path.ends_with(".jpeg") {
            "image/jpeg"
        } else if path.ends_with(".svg") {
            "image/svg+xml"
        } else {
            "application/octet-stream"
        }
    }
}
