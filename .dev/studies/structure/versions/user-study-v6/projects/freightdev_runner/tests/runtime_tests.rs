//! tests/api_tests.rs - Core API functionality tests

mod common;

use llama_runner::{LlamaRunner, GenerationParams, Result};
use common::{default_test_params, SAMPLE_PROMPTS};
use std::path::Path;

#[test]
fn test_generation_params_defaults() {
    let params = GenerationParams::default();
    assert_eq!(params.max_tokens, 256);
    assert_eq!(params.temperature, 0.1);
    assert_eq!(params.top_p, 0.9);
    assert_eq!(params.top_k, 40);
    assert_eq!(params.threads, 8);
    assert_eq!(params.batch_threads, 4);
}

#[test] 
fn test_generation_params_custom() {
    let params = GenerationParams {
        max_tokens: 100,
        temperature: 0.5,
        top_p: 0.8,
        top_k: 20,
        threads: 4,
        batch_threads: 2,
    };
    
    assert_eq!(params.max_tokens, 100);
    assert_eq!(params.temperature, 0.5);
}

// Note: These tests require a real model to run
// Uncomment when you have test models available
/*
#[test]
fn test_llama_runner_creation() -> Result<()> {
    let model_path = Path::new("tests/common/fixtures/test_model.json");
    let runner = LlamaRunner::new(model_path)?;
    
    let info = runner.model_info();
    assert!(!info.name.is_empty());
    assert!(!info.path.is_empty());
    
    Ok(())
}

#[test]
fn test_stateless_generation() -> Result<()> {
    let model_path = Path::new("tests/common/fixtures/test_model.json");
    let runner = LlamaRunner::new(model_path)?;
    let params = default_test_params();
    
    let response = runner.generate_stateless("What is 2+2?", params)?;
    
    assert!(!response.is_empty());
    assert!(response.len() < 1000); // Reasonable length
    
    Ok(())
}

#[test]
fn test_stateful_generation() -> Result<()> {
    let model_path = Path::new("tests/common/fixtures/test_model.json");
    let mut runner = LlamaRunner::new(model_path)?;
    
    runner.init_stateful(default_test_params())?;
    
    let response1 = runner.generate_stateful("My name is Alice.", 20)?;
    let response2 = runner.generate_stateful("What is my name?", 20)?;
    
    assert!(!response1.is_empty());
    assert!(!response2.is_empty());
    
    // Should remember the name in context
    assert!(response2.to_lowercase().contains("alice") || 
            response2.to_lowercase().contains("your name"));
    
    Ok(())
}

#[test]
fn test_context_management() -> Result<()> {
    let model_path = Path::new("tests/common/fixtures/test_model.json");
    let mut runner = LlamaRunner::new(model_path)?;
    
    runner.init_stateful(default_test_params())?;
    
    // Generate some content to fill context
    for prompt in SAMPLE_PROMPTS.iter().take(3) {
        runner.generate_stateful(prompt, 30)?;
    }
    
    // Check context info
    let info = runner.get_context_info()?;
    assert!(info.used_tokens > 0);
    assert!(info.total_capacity > info.used_tokens);
    assert!(info.usage_percent >= 0.0 && info.usage_percent <= 100.0);
    
    // Clear context
    runner.clear_context()?;
    let info_after_clear = runner.get_context_info()?;
    assert!(info_after_clear.used_tokens <= info.used_tokens);
    
    Ok(())
}

#[test]
fn test_garbage_collection() -> Result<()> {
    let model_path = Path::new("tests/common/fixtures/test_model.json");
    let mut runner = LlamaRunner::new(model_path)?;
    
    runner.init_stateful(default_test_params())?;
    
    // Fill context significantly
    for i in 0..10 {
        runner.generate_stateful(&format!("Question number {}", i), 50)?;
    }
    
    let info_before = runner.get_context_info()?;
    
    // Trigger GC
    runner.gc_context(100)?;
    
    let info_after = runner.get_context_info()?;
    
    // Should have cleaned up some tokens
    assert!(info_after.used_tokens <= info_before.used_tokens);
    
    Ok(())
}
*/

#[test]
fn test_error_handling() {
    // Test with non-existent model
    let result = LlamaRunner::new(Path::new("non_existent_model.json"));
    assert!(result.is_err());
    
    // Test invalid path
    let result = LlamaRunner::new(Path::new(""));
    assert!(result.is_err());
}

#[test]
fn test_multiple_runners() {
    // Test that multiple runners can be created (even if they fail)
    // This tests the basic structure and error handling
    let paths = [
        "model1.json",
        "model2.json", 
        "model3.json"
    ];
    
    for path in &paths {
        let result = LlamaRunner::new(Path::new(path));
        // Should fail gracefully with proper error types
        assert!(result.is_err());
    }
}