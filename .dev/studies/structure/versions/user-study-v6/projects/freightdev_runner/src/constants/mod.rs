pub mod default;
pub mod values;

pub use default::*;
pub use values::*;

// Model constants
pub const DEFAULT_MODEL_PATH: &str = "../models/";
pub const SUPPORTED_EXTENSIONS: &[&str] = &["gguf", "ggml", "bin"];

// Context constants
pub const MIN_CONTEXT_SIZE: u32 = 64;
pub const MAX_CONTEXT_SIZE: u32 = 32768;
pub const DEFAULT_CONTEXT_SIZE: u32 = 2048;

// Batch constants
pub const MIN_BATCH_SIZE: u32 = 1;
pub const MAX_BATCH_SIZE: u32 = 2048;
pub const DEFAULT_BATCH_SIZE: u32 = 512;

// Thread constants
pub const MIN_THREADS: i32 = 1;
pub const MAX_THREADS: i32 = 256;
pub const DEFAULT_THREADS: i32 = -1; // Auto-detect

// Memory constants
pub const MIN_MEMORY_MB: usize = 128;
pub const DEFAULT_MEMORY_MB: usize = 4096;
pub const MAX_MEMORY_MB: usize = 65536;

// Rate limiting constants
pub const MIN_RATE_LIMIT: u32 = 1;
pub const DEFAULT_RATE_LIMIT: u32 = 100;
pub const MAX_RATE_LIMIT: u32 = 10000;

// Token constants
pub const BOS_TOKEN: i32 = 1;
pub const EOS_TOKEN: i32 = 2;
pub const UNK_TOKEN: i32 = 0;
pub const PAD_TOKEN: i32 = -1;

// Special token strings
pub const BOS_TOKEN_STR: &str = "<s>";
pub const EOS_TOKEN_STR: &str = "</s>";
pub const UNK_TOKEN_STR: &str = "<unk>";
pub const PAD_TOKEN_STR: &str = "<pad>";

// Sampling constants
pub const DEFAULT_TEMP: f32 = 0.8;
pub const DEFAULT_TOP_K: i32 = 40;
pub const DEFAULT_TOP_P: f32 = 0.95;
pub const DEFAULT_REPEAT_PENALTY: f32 = 1.1;
pub const DEFAULT_REPEAT_LAST_N: i32 = 64;

// Generation constants
pub const DEFAULT_MAX_TOKENS: i32 = 256;
pub const MIN_MAX_TOKENS: i32 = 1;
pub const MAX_MAX_TOKENS: i32 = 4096;

// Rope constants
pub const DEFAULT_ROPE_FREQ_BASE: f32 = 10000.0;
pub const DEFAULT_ROPE_FREQ_SCALE: f32 = 1.0;

// YARN constants
pub const DEFAULT_YARN_EXT_FACTOR: f32 = -1.0;
pub const DEFAULT_YARN_ATTN_FACTOR: f32 = 1.0;
pub const DEFAULT_YARN_BETA_FAST: f32 = 32.0;
pub const DEFAULT_YARN_BETA_SLOW: f32 = 1.0;

// System constants
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
pub const NAME: &str = env!("CARGO_PKG_NAME");
pub const DESCRIPTION: &str = env!("CARGO_PKG_DESCRIPTION");
pub const AUTHOR: &str = env!("CARGO_PKG_AUTHORS");

// Error messages
pub const ERR_MODEL_NOT_FOUND: &str = "Model file not found";
pub const ERR_MODEL_LOAD_FAILED: &str = "Failed to load model";
pub const ERR_CONTEXT_CREATE_FAILED: &str = "Failed to create context";
pub const ERR_TOKEN_DECODE_FAILED: &str = "Failed to decode tokens";
pub const ERR_TOKEN_ENCODE_FAILED: &str = "Failed to encode tokens";
pub const ERR_INFERENCE_FAILED: &str = "Inference failed";
pub const ERR_MEMORY_ALLOCATION: &str = "Memory allocation failed";
pub const ERR_THREAD_SPAWN: &str = "Failed to spawn thread";
pub const ERR_RATE_LIMIT_EXCEEDED: &str = "Rate limit exceeded";

// Log levels
pub const LOG_LEVEL_ERROR: u8 = 0;
pub const LOG_LEVEL_WARN: u8 = 1;
pub const LOG_LEVEL_INFO: u8 = 2;
pub const LOG_LEVEL_DEBUG: u8 = 3;
pub const LOG_LEVEL_TRACE: u8 = 4;