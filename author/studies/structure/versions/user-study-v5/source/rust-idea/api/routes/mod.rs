//! src/api/routes/mod.rs

pub mod admin;
pub mod chat;
pub mod completions;
pub mod embeddings;
pub mod health;
pub mod models;

pub use admin::*;
pub use chat::*;
pub use completions::*;
pub use embeddings::*;
pub use health::*;
pub use models::*;
