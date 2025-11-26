use std::fmt;

pub mod error;
pub mod _utils;

pub use error::Error;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, Clone)]
pub enum Error {
    // Model errors
    ModelNotFound(String),
    ModelLoadError(String),
    ModelInvalidFormat(String),
    ModelUnsupportedVersion(String),

    // Context errors
    ContextCreateError(String),
    ContextInvalidState(String),
    ContextMemoryError(String),

    // Token errors
    TokenError(String),
    TokenizeError(String),
    DetokenizeError(String),
    VocabError(String),

    // Inference errors
    InferenceError(String),
    GenerationError(String),
    SamplingError(String),

    // Core system errors
    EngineError(String),
    ThreadPoolError(String),
    MemoryError(String),
    RateLimitError(String),

    // Runtime errors
    RuntimeError(String),
    BatchError(String),
    StreamingError(String),
    WebSocketError(String),

    // I/O errors
    IoError(std::io::Error),
    FileNotFound(String),
    InvalidPath(String),
    PermissionDenied(String),

    // Configuration errors
    ConfigError(String),
    InvalidParameter(String),
    MissingParameter(String),

    // Network/Handler errors
    NetworkError(String),
    AuthenticationError(String),
    AuthorizationError(String),
    RequestError(String),

    // FFI errors
    FfiError(String),
    BindingError(String),
    NullPointer(String),

    // Generic errors
    Internal(String),
    Unknown(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            // Model errors
            Error::ModelNotFound(msg) => write!(f, "Model not found: {}", msg),
            Error::ModelLoadError(msg) => write!(f, "Failed to load model: {}", msg),
            Error::ModelInvalidFormat(msg) => write!(f, "Invalid model format: {}", msg),
            Error::ModelUnsupportedVersion(msg) => write!(f, "Unsupported model version: {}", msg),

            // Context errors
            Error::ContextCreateError(msg) => write!(f, "Failed to create context: {}", msg),
            Error::ContextInvalidState(msg) => write!(f, "Invalid context state: {}", msg),
            Error::ContextMemoryError(msg) => write!(f, "Context memory error: {}", msg),

            // Token errors
            Error::TokenError(msg) => write!(f, "Token error: {}", msg),
            Error::TokenizeError(msg) => write!(f, "Tokenization failed: {}", msg),
            Error::DetokenizeError(msg) => write!(f, "Detokenization failed: {}", msg),
            Error::VocabError(msg) => write!(f, "Vocabulary error: {}", msg),

            // Inference errors
            Error::InferenceError(msg) => write!(f, "Inference error: {}", msg),
            Error::GenerationError(msg) => write!(f, "Text generation error: {}", msg),
            Error::SamplingError(msg) => write!(f, "Sampling error: {}", msg),

            // Core system errors
            Error::EngineError(msg) => write!(f, "Engine error: {}", msg),
            Error::ThreadPoolError(msg) => write!(f, "Thread pool error: {}", msg),
            Error::MemoryError(msg) => write!(f, "Memory error: {}", msg),
            Error::RateLimitError(msg) => write!(f, "Rate limit exceeded: {}", msg),

            // Runtime errors
            Error::RuntimeError(msg) => write!(f, "Runtime error: {}", msg),
            Error::BatchError(msg) => write!(f, "Batch processing error: {}", msg),
            Error::StreamingError(msg) => write!(f, "Streaming error: {}", msg),
            Error::WebSocketError(msg) => write!(f, "WebSocket error: {}", msg),

            // I/O errors
            Error::IoError(err) => write!(f, "I/O error: {}", err),
            Error::FileNotFound(path) => write!(f, "File not found: {}", path),
            Error::InvalidPath(path) => write!(f, "Invalid path: {}", path),
            Error::PermissionDenied(path) => write!(f, "Permission denied: {}", path),

            // Configuration errors
            Error::ConfigError(msg) => write!(f, "Configuration error: {}", msg),
            Error::InvalidParameter(param) => write!(f, "Invalid parameter: {}", param),
            Error::MissingParameter(param) => write!(f, "Missing parameter: {}", param),

            // Network/Handler errors
            Error::NetworkError(msg) => write!(f, "Network error: {}", msg),
            Error::AuthenticationError(msg) => write!(f, "Authentication failed: {}", msg),
            Error::AuthorizationError(msg) => write!(f, "Authorization failed: {}", msg),
            Error::RequestError(msg) => write!(f, "Request error: {}", msg),

            // FFI errors
            Error::FfiError(msg) => write!(f, "FFI error: {}", msg),
            Error::BindingError(msg) => write!(f, "Binding error: {}", msg),
            Error::NullPointer(msg) => write!(f, "Null pointer error: {}", msg),

            // Generic errors
            Error::Internal(msg) => write!(f, "Internal error: {}", msg),
            Error::Unknown(msg) => write!(f, "Unknown error: {}", msg),
        }
    }
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Error::IoError(err) => Some(err),
            _ => None,
        }
    }
}

impl From<std::io::Error> for Error {
    fn from(err: std::io::Error) -> Self {
        Error::IoError(err)
    }
}

impl From<std::ffi::NulError> for Error {
    fn from(err: std::ffi::NulError) -> Self {
        Error::FfiError(format!("Null byte in string: {}", err))
    }
}

impl Error {
    pub fn is_recoverable(&self) -> bool {
        match self {
            // Non-recoverable errors
            Error::ModelNotFound(_) |
            Error::ModelInvalidFormat(_) |
            Error::ModelUnsupportedVersion(_) |
            Error::FileNotFound(_) |
            Error::PermissionDenied(_) |
            Error::InvalidPath(_) |
            Error::FfiError(_) |
            Error::BindingError(_) |
            Error::NullPointer(_) => false,

            // Potentially recoverable errors
            Error::ModelLoadError(_) |
            Error::ContextCreateError(_) |
            Error::InferenceError(_) |
            Error::NetworkError(_) |
            Error::RateLimitError(_) |
            Error::MemoryError(_) |
            Error::ThreadPoolError(_) => true,

            // Context-dependent
            _ => true,
        }
    }

    pub fn error_code(&self) -> u32 {
        match self {
            // Model errors (1000-1099)
            Error::ModelNotFound(_) => 1001,
            Error::ModelLoadError(_) => 1002,
            Error::ModelInvalidFormat(_) => 1003,
            Error::ModelUnsupportedVersion(_) => 1004,

            // Context errors (1100-1199)
            Error::ContextCreateError(_) => 1101,
            Error::ContextInvalidState(_) => 1102,
            Error::ContextMemoryError(_) => 1103,

            // Token errors (1200-1299)
            Error::TokenError(_) => 1201,
            Error::TokenizeError(_) => 1202,
            Error::DetokenizeError(_) => 1203,
            Error::VocabError(_) => 1204,

            // Inference errors (1300-1399)
            Error::InferenceError(_) => 1301,
            Error::GenerationError(_) => 1302,
            Error::SamplingError(_) => 1303,

            // Core system errors (1400-1499)
            Error::EngineError(_) => 1401,
            Error::ThreadPoolError(_) => 1402,
            Error::MemoryError(_) => 1403,
            Error::RateLimitError(_) => 1404,

            // Runtime errors (1500-1599)
            Error::RuntimeError(_) => 1501,
            Error::BatchError(_) => 1502,
            Error::StreamingError(_) => 1503,
            Error::WebSocketError(_) => 1504,

            // I/O errors (2000-2099)
            Error::IoError(_) => 2001,
            Error::FileNotFound(_) => 2002,
            Error::InvalidPath(_) => 2003,
            Error::PermissionDenied(_) => 2004,

            // Configuration errors (2100-2199)
            Error::ConfigError(_) => 2101,
            Error::InvalidParameter(_) => 2102,
            Error::MissingParameter(_) => 2103,

            // Network/Handler errors (2200-2299)
            Error::NetworkError(_) => 2201,
            Error::AuthenticationError(_) => 2202,
            Error::AuthorizationError(_) => 2203,
            Error::RequestError(_) => 2204,

            // FFI errors (3000-3099)
            Error::FfiError(_) => 3001,
            Error::BindingError(_) => 3002,
            Error::NullPointer(_) => 3003,

            // Generic errors (9000+)
            Error::Internal(_) => 9001,
            Error::Unknown(_) => 9999,
        }
    }
}