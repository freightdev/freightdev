use std::path::Path;
use crate::error::{Error, Result};

pub mod completion;
pub mod embeddings;
pub mod model;
pub mod _utils;

pub use model::Model;

pub struct ModelConfig {
    pub n_ctx: u32,
    pub n_batch: u32,
    pub n_gpu_layers: i32,
    pub use_mmap: bool,
    pub use_mlock: bool,
    pub vocab_only: bool,
}

impl Default for ModelConfig {
    fn default() -> Self {
        Self {
            n_ctx: 2048,
            n_batch: 512,
            n_gpu_layers: -1,
            use_mmap: true,
            use_mlock: false,
            vocab_only: false,
        }
    }
}

pub struct ModelMetadata {
    pub name: String,
    pub architecture: String,
    pub vocab_size: usize,
    pub context_length: usize,
    pub embedding_length: usize,
    pub quantization: Option<String>,
}

pub trait ModelTrait {
    fn load_from_path<P: AsRef<Path>>(path: P) -> Result<Self> where Self: Sized;
    fn load_with_config<P: AsRef<Path>>(path: P, config: ModelConfig) -> Result<Self> where Self: Sized;
    fn metadata(&self) -> &ModelMetadata;
    fn vocab_size(&self) -> usize;
    fn context_length(&self) -> usize;
    fn embedding_length(&self) -> usize;
    fn is_loaded(&self) -> bool;
    fn unload(&mut self) -> Result<()>;
}