//! lib.rs — llama-libs core crate
//! llama-libs — Core lib for LLM CLI
//!
//! This crate wraps llama.cpp FFI and provides high-level Rust tools like:
//! - tokenizer
//! - model loader
//! - interactive loop
//! - CLI bindings

// Silent binding noise from bindgen
#![allow(unreachable_pub)]
#![allow(unused_variables)]
#![allow(unused_unsafe)]
#![allow(dead_code)]
#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]

// Make the modules public so downstream code (and your own `main.rs`) can see them
pub mod bindings;
pub mod tokens;
pub mod runners;
pub mod loaders;
pub mod prompts;


// Re-export their contents if you want a flat API:
pub use bindings::*;
pub use tokens::*;
pub use runners::*;
pub use loaders::*;
pub use prompts::*;

