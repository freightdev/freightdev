use thiserror::Error;
use serde::{Deserialize, Serialize};

#[derive(Error, Debug, Clone, Serialize, Deserialize)]
pub enum LlamaError {
    #[error("Model loading error: {0}")]
    ModelLoadError(String),

    #[error("Context creation error: {0}")]
    ContextCreationError(String),

    #[error("Tokenization error: {0}")]
    TokenizationError(String),

    #[error("Generation error: {0}")]
    GenerationError(String),

    #[error("JSON error: {0}")]
    JsonError(String),
}

impl From<std::io::Error> for LlamaError {
    fn from(err: std::io::Error) -> Self {
        LlamaError::ModelLoadError(err.to_string())
    }
}

impl From<serde_json::Error> for LlamaError {
    fn from(err: serde_json::Error) -> Self {
        LlamaError::JsonError(err.to_string())
    }
}

pub type Result<T> = std::result::Result<T, LlamaError>;
