use crate::error::{Error, Result};
use std::path::Path;

pub mod config;
pub mod file_utils;
pub mod formating;
pub mod health;
pub mod logging;
pub mod metrics;

pub use config::Config;
pub use file_utils::{FileUtils, PathUtils};
pub use formating::{Formatter, TimeFormatter, SizeFormatter};
pub use health::{HealthChecker, SystemHealth};
pub use logging::{Logger, LogLevel};
pub use metrics::{Metrics, PerformanceMetrics};

// Re-export commonly used utility functions
pub use file_utils::{ensure_dir_exists, get_file_size, is_file_readable};
pub use formating::{format_duration, format_bytes, format_tokens_per_second};
pub use health::{check_system_resources, get_memory_usage, get_cpu_usage};
pub use logging::{init_logger, log_info, log_error, log_warn, log_debug};
pub use metrics::{start_timer, record_inference_time, get_avg_response_time};

// Common utility traits
pub trait Validate {
    fn validate(&self) -> Result<()>;
}

pub trait Serialize {
    fn serialize(&self) -> Result<Vec<u8>>;
    fn deserialize(data: &[u8]) -> Result<Self> where Self: Sized;
}

pub trait Cleanup {
    fn cleanup(&mut self) -> Result<()>;
}

// System utilities
pub fn get_system_info() -> SystemInfo {
    SystemInfo {
        os: std::env::consts::OS.to_string(),
        arch: std::env::consts::ARCH.to_string(),
        cpu_count: num_cpus::get(),
        available_memory: get_available_memory(),
    }
}

pub fn get_available_memory() -> usize {
    // Platform-specific memory detection would go here
    // For now, return a reasonable default
    8192 // 8GB in MB
}

pub fn normalize_path<P: AsRef<Path>>(path: P) -> Result<std::path::PathBuf> {
    let path = path.as_ref();
    if path.is_absolute() {
        Ok(path.to_path_buf())
    } else {
        std::env::current_dir()
            .map_err(Error::from)?
            .join(path)
            .canonicalize()
            .map_err(Error::from)
    }
}

pub fn validate_model_path<P: AsRef<Path>>(path: P) -> Result<()> {
    let path = path.as_ref();
    
    if !path.exists() {
        return Err(Error::FileNotFound(path.display().to_string()));
    }
    
    if !path.is_file() {
        return Err(Error::InvalidPath(format!("{} is not a file", path.display())));
    }
    
    // Check file extension
    if let Some(ext) = path.extension() {
        let ext = ext.to_string_lossy().to_lowercase();
        if !["gguf", "ggml", "bin"].contains(&ext.as_str()) {
            return Err(Error::ModelInvalidFormat(format!("Unsupported file extension: {}", ext)));
        }
    } else {
        return Err(Error::ModelInvalidFormat("No file extension found".to_string()));
    }
    
    Ok(())
}

pub fn validate_context_params(n_ctx: u32, n_batch: u32, n_threads: i32) -> Result<()> {
    if n_ctx < 64 || n_ctx > 32768 {
        return Err(Error::InvalidParameter(format!("n_ctx must be between 64 and 32768, got {}", n_ctx)));
    }
    
    if n_batch < 1 || n_batch > 2048 {
        return Err(Error::InvalidParameter(format!("n_batch must be between 1 and 2048, got {}", n_batch)));
    }
    
    if n_threads != -1 && (n_threads < 1 || n_threads > 256) {
        return Err(Error::InvalidParameter(format!("n_threads must be -1 (auto) or between 1 and 256, got {}", n_threads)));
    }
    
    Ok(())
}

pub fn clamp<T: PartialOrd + Copy>(value: T, min: T, max: T) -> T {
    if value < min {
        min
    } else if value > max {
        max
    } else {
        value
    }
}

pub fn percentage(value: f32, total: f32) -> f32 {
    if total == 0.0 {
        0.0
    } else {
        (value / total) * 100.0
    }
}

pub struct SystemInfo {
    pub os: String,
    pub arch: String,
    pub cpu_count: usize,
    pub available_memory: usize,
}

impl SystemInfo {
    pub fn is_gpu_available(&self) -> bool {
        // Would check for CUDA, Metal, ROCm, etc. based on platform
        cfg!(feature = "cuda") || cfg!(feature = "metal") || cfg!(feature = "rocm")
    }
    
    pub fn recommended_threads(&self) -> usize {
        // Leave one core free for the system
        (self.cpu_count - 1).max(1)
    }
    
    pub fn recommended_context_size(&self) -> u32 {
        // Recommend context size based on available memory
        match self.available_memory {
            0..=2048 => 512,      // <= 2GB RAM
            2049..=4096 => 1024,  // <= 4GB RAM
            4097..=8192 => 2048,  // <= 8GB RAM
            _ => 4096,            // > 8GB RAM
        }
    }
}