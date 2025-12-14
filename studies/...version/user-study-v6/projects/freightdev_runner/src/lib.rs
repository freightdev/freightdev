//! src/lib.rs - Core library for LLM interaction
#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(dead_code)]

pub mod constants;
pub mod context;
pub mod core;
pub mod error;
pub mod handlers;
pub mod model;
pub mod runtimes;
pub mod token;
pub mod utils;

// Re-exports for convenience
pub use context::Context;
pub use core::Engine;
pub use error::{Error, Result};
pub use model::Model;
pub use runtimes as runtime;
pub use token::TokenProcessor;

