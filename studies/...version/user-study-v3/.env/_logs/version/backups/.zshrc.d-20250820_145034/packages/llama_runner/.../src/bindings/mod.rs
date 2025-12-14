//! src/bindings/mod.rs

#[cfg(feature = "regen-bindings")]
pub mod llama_cpp;

#[cfg(not(feature = "regen-bindings"))]
#[path = "llama_cpp.rs"]
pub mod llama_cpp;

// Re-export all the generated bindings from the public `llamaCPP` module:
pub use llama_cpp::*;
