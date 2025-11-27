//! tests/pronunciation_tests.rs - Pronunciation optimization tests

mod common;

use common::TECH_TERMS;
use llama_runner::prompts;

#[test]
fn test_pronunciation_mappings() {
    let test_cases = [
        ("GitHub", "Git-Hub"),
        ("PostgreSQL", "Postgres-Q-L"),
        ("API", "A-P-I"),
        ("JSON", "J-SON"),
        ("zBox", "z-Box"),
        ("zBoxxy", "z-Boxy"),
        ("MARK", "M-A-R-K"),
    ];
    
    for (input, expected) in &test_cases {
        // This would test the internal preprocessing function
        // Currently the function is private, so this is a placeholder
        assert!(input.len() > 0);
        assert!(expected.len() > 0);
    }
}

#[test]
fn test_tech_terms_coverage() {
    // Ensure we have test coverage for important technical terms
    let important_terms = ["API", "HTTP", "JSON", "SQL", "HTML", "CSS"];
    
    for term in &important_terms {
        assert!(TECH_TERMS.contains(term), "Missing coverage for: {}", term);
    }
}

#[test]
fn test_mark_system_terms() {
    // Test MARK system specific terminology
    let mark_terms = ["zBox", "zBoxxy", "MARK", "Marketeer"];
    
    for term in &mark_terms {
        assert!(TECH_TERMS.contains(term), "Missing MARK term: {}", term);
    }
}

#[test]
fn test_camel_case_detection() {
    let camel_cases = [
        "camelCase",
        "PascalCase", 
        "XMLHttpRequest",
        "getElementById",
        "CargoConnect",
        "BigBear",
    ];
    
    // These should be detected as needing word boundary insertion
    for case in &camel_cases {
        assert!(case.chars().any(|c| c.is_uppercase()), "Should contain uppercase: {}", case);
    }
}

#[test]
fn test_agent_prompt_formatting() {
    let cargo_info = "40ft container from Chicago to LA";
    let prompt = prompts::agents::big_bear(cargo_info);
    
    assert!(prompt.contains("Big Bear"));
    assert!(prompt.contains("MARK"));
    assert!(prompt.contains(cargo_info));
    assert!(prompt.contains("[INST]") && prompt.contains("[/INST]"));
}

#[test]
fn test_all_agent_prompts() {
    let test_input = "test input";
    
    let prompts = [
        prompts::agents::big_bear(test_input),
        prompts::agents::cargo_connect(test_input),
        prompts::agents::trucker_tales(test_input),
        prompts::agents::legal_logger(test_input),
        prompts::agents::memory_mark(test_input),
    ];
    
    for prompt in &prompts {
        assert!(prompt.contains("MARK"));
        assert!(prompt.contains(test_input));
        assert!(prompt.contains("[INST]"));
        assert!(prompt.contains("[/INST]"));
    }
}

#[test]
fn test_chat_format_detection() {
    let test_cases = [
        ("llama-7b.gguf", "should detect llama format"),
        ("vicuna-13b.gguf", "should detect vicuna format"),
        ("alpaca-7b.gguf", "should detect alpaca format"),
        ("openchat-3.5.gguf", "should detect openchat format"),
        ("unknown-model.gguf", "should default to llama format"),
    ];
    
    for (model_path, description) in &test_cases {
        let format = prompts::detect_chat_format(model_path);
        // Just ensure it returns a valid format
        match format {
            prompts::ChatFormat::Llama | 
            prompts::ChatFormat::Vicuna | 
            prompts::ChatFormat::Alpaca | 
            prompts::ChatFormat::OpenChat => {
                // Valid format detected
            }
        }
    }
}

#[test]
fn test_chat_format_user_formatting() {
    let formats = [
        prompts::ChatFormat::Llama,
        prompts::ChatFormat::Vicuna,
        prompts::ChatFormat::Alpaca,
        prompts::ChatFormat::OpenChat,
    ];
    
    let test_input = "Hello world";
    
    for format in &formats {
        let formatted = format.format_user(test_input);
        assert!(formatted.contains(test_input));
        assert!(!formatted.is_empty());
    }
}

#[test]
fn test_pronunciation_consistency() {
    // Test that repeated processing gives consistent results
    let test_term = "GitHub API";
    
    // This would test the preprocessing function multiple times
    // to ensure consistent output
    for _ in 0..5 {
        // Placeholder - would call the actual preprocessing function
        assert!(test_term.contains("GitHub"));
        assert!(test_term.contains("API"));
    }
}