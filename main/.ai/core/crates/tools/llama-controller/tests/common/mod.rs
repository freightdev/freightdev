//! tests/common/mod.rs - Common test utilities

pub mod mock_model;

use std::path::PathBuf;
use tempfile::TempDir;

/// Test fixture directory
pub fn get_fixtures_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/common/fixtures")
}

/// Create temporary directory for tests
pub fn create_temp_dir() -> TempDir {
    tempfile::tempdir().expect("Failed to create temp dir")
}

/// Sample prompts for testing
pub const SAMPLE_PROMPTS: &[&str] = &[
    "What is 2 + 2?",
    "Explain quantum computing",
    "Write a haiku about trucks",
    "How do I change a tire?",
    "What are DOT regulations?",
];

/// Technical terms for pronunciation testing
pub const TECH_TERMS: &[&str] = &[
    "GitHub",
    "PostgreSQL", 
    "API",
    "HTTP",
    "JSON",
    "zBox",
    "zBoxxy",
    "MARK",
    "Marketeer",
];

/// Mock generation parameters
pub fn default_test_params() -> llama_runner::GenerationParams {
    llama_runner::GenerationParams {
        max_tokens: 50,
        temperature: 0.1,
        top_p: 0.9,
        top_k: 40,
        threads: 2,
        batch_threads: 1,
    }
}