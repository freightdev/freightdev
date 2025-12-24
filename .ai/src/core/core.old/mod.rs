use crate::error::{Error, Result};
use std::sync::Arc;

pub mod context_pool;
pub mod engine;
pub mod memory_manager;
pub mod rate_limit;
pub mod thread_pool;

pub use engine::Engine;
pub use context_pool::ContextPool;
pub use memory_manager::MemoryManager;
pub use thread_pool::ThreadPool;
pub use rate_limit::RateLimiter;

pub struct CoreConfig {
    pub max_contexts: usize,
    pub thread_count: usize,
    pub memory_limit_mb: usize,
    pub rate_limit_per_second: u32,
    pub enable_gpu: bool,
}

impl Default for CoreConfig {
    fn default() -> Self {
        Self {
            max_contexts: 10,
            thread_count: num_cpus::get(),
            memory_limit_mb: 4096,
            rate_limit_per_second: 100,
            enable_gpu: true,
        }
    }
}

pub struct Core {
    config: CoreConfig,
    context_pool: Arc<ContextPool>,
    memory_manager: Arc<MemoryManager>,
    thread_pool: Arc<ThreadPool>,
    rate_limiter: Arc<RateLimiter>,
}

impl Core {
    pub fn new() -> Result<Self> {
        Self::with_config(CoreConfig::default())
    }

    pub fn with_config(config: CoreConfig) -> Result<Self> {
        let context_pool = Arc::new(ContextPool::new(config.max_contexts)?);
        let memory_manager = Arc::new(MemoryManager::new(config.memory_limit_mb)?);
        let thread_pool = Arc::new(ThreadPool::new(config.thread_count)?);
        let rate_limiter = Arc::new(RateLimiter::new(config.rate_limit_per_second)?);

        Ok(Self {
            config,
            context_pool,
            memory_manager,
            thread_pool,
            rate_limiter,
        })
    }

    pub fn context_pool(&self) -> Arc<ContextPool> {
        Arc::clone(&self.context_pool)
    }

    pub fn memory_manager(&self) -> Arc<MemoryManager> {
        Arc::clone(&self.memory_manager)
    }

    pub fn thread_pool(&self) -> Arc<ThreadPool> {
        Arc::clone(&self.thread_pool)
    }

    pub fn rate_limiter(&self) -> Arc<RateLimiter> {
        Arc::clone(&self.rate_limiter)
    }

    pub fn config(&self) -> &CoreConfig {
        &self.config
    }
}