use anyhow::{anyhow, Result};
use chrono::{DateTime, Utc};
use image::ImageFormat;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use surrealdb::engine::remote::ws::{Client, Ws};
use surrealdb::opt::auth::Root;
use surrealdb::Surreal;
use tokio::fs;
use tokio::io::AsyncWriteExt;
use tracing::{debug, info};
use uuid::Uuid;

#[derive(Clone)]
pub struct AppState {
    pub db: Surreal<Client>,
    pub upload_dir: PathBuf,
    pub max_file_size: usize,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FileMetadata {
    pub id: String,
    pub filename: String,
    pub content_type: String,
    pub size: usize,
    pub user_id: String,
    pub file_type: FileType,
    pub storage_path: String,
    pub thumbnail_path: Option<String>,
    pub uploaded_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum FileType {
    Image,
    Document,
    Pdf,
    Other,
}

impl AppState {
    pub async fn new(upload_dir: impl AsRef<Path>, max_file_size: usize) -> Result<Self> {
        let upload_path = upload_dir.as_ref().to_path_buf();
        fs::create_dir_all(&upload_path).await?;
        fs::create_dir_all(upload_path.join("images")).await?;
        fs::create_dir_all(upload_path.join("documents")).await?;
        fs::create_dir_all(upload_path.join("thumbnails")).await?;

        let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "127.0.0.1:8000".to_string());
        let db = Surreal::new::<Ws>(db_url).await?;

        db.signin(Root {
            username: "root",
            password: "root",
        })
        .await?;

        db.use_ns("hwy_tms").use_db("production").await?;

        info!("Upload service initialized with upload_dir: {:?}", upload_path);

        Ok(Self {
            db,
            upload_dir: upload_path,
            max_file_size,
        })
    }

    pub async fn save_file(
        &self,
        user_id: &str,
        filename: &str,
        content_type: &str,
        data: &[u8],
    ) -> Result<FileMetadata> {
        if data.len() > self.max_file_size {
            return Err(anyhow!(
                "File size exceeds maximum allowed size of {} bytes",
                self.max_file_size
            ));
        }

        let file_id = Uuid::new_v4().to_string();
        let file_type = Self::determine_file_type(content_type);

        let subdir = match file_type {
            FileType::Image => "images",
            FileType::Document | FileType::Pdf => "documents",
            FileType::Other => "other",
        };

        let storage_path = self
            .upload_dir
            .join(subdir)
            .join(format!("{}_{}", file_id, filename));

        let mut file = fs::File::create(&storage_path).await?;
        file.write_all(data).await?;

        debug!("Saved file to {:?}", storage_path);

        let thumbnail_path = if matches!(file_type, FileType::Image) {
            match self.create_thumbnail(&storage_path, &file_id).await {
                Ok(path) => Some(path),
                Err(e) => {
                    tracing::warn!("Failed to create thumbnail: {}", e);
                    None
                }
            }
        } else {
            None
        };

        let metadata = FileMetadata {
            id: file_id,
            filename: filename.to_string(),
            content_type: content_type.to_string(),
            size: data.len(),
            user_id: user_id.to_string(),
            file_type,
            storage_path: storage_path.to_string_lossy().to_string(),
            thumbnail_path,
            uploaded_at: Utc::now(),
        };

        let _: Vec<FileMetadata> = self
            .db
            .create("uploads")
            .content(&metadata)
            .await?;

        Ok(metadata)
    }

    pub async fn get_file(&self, file_id: &str) -> Result<(FileMetadata, Vec<u8>)> {
        let metadata: Option<FileMetadata> = self.db.select(("uploads", file_id)).await?;

        let metadata = metadata.ok_or_else(|| anyhow!("File not found"))?;

        let data = fs::read(&metadata.storage_path).await?;

        Ok((metadata, data))
    }

    pub async fn get_metadata(&self, file_id: &str) -> Result<FileMetadata> {
        let metadata: Option<FileMetadata> = self.db.select(("uploads", file_id)).await?;
        metadata.ok_or_else(|| anyhow!("File not found"))
    }

    pub async fn delete_file(&self, file_id: &str, user_id: &str) -> Result<()> {
        let metadata: Option<FileMetadata> = self.db.select(("uploads", file_id)).await?;

        let metadata = metadata.ok_or_else(|| anyhow!("File not found"))?;

        if metadata.user_id != user_id {
            return Err(anyhow!("Unauthorized to delete this file"));
        }

        fs::remove_file(&metadata.storage_path).await?;

        if let Some(thumbnail_path) = &metadata.thumbnail_path {
            fs::remove_file(thumbnail_path).await.ok();
        }

        let _: Option<FileMetadata> = self.db.delete(("uploads", file_id)).await?;

        Ok(())
    }

    pub async fn list_user_files(&self, user_id: &str) -> Result<Vec<FileMetadata>> {
        let query = format!("SELECT * FROM uploads WHERE user_id = '{}'", user_id);
        let mut result = self.db.query(query).await?;
        let files: Vec<FileMetadata> = result.take(0)?;
        Ok(files)
    }

    async fn create_thumbnail(&self, image_path: &Path, file_id: &str) -> Result<String> {
        let img = image::open(image_path)?;
        let thumbnail = img.thumbnail(200, 200);

        let thumbnail_filename = format!("thumb_{}.jpg", file_id);
        let thumbnail_path = self.upload_dir.join("thumbnails").join(&thumbnail_filename);

        thumbnail.save_with_format(&thumbnail_path, ImageFormat::Jpeg)?;

        Ok(thumbnail_path.to_string_lossy().to_string())
    }

    fn determine_file_type(content_type: &str) -> FileType {
        if content_type.starts_with("image/") {
            FileType::Image
        } else if content_type == "application/pdf" {
            FileType::Pdf
        } else if content_type.starts_with("application/") || content_type.starts_with("text/") {
            FileType::Document
        } else {
            FileType::Other
        }
    }
}
