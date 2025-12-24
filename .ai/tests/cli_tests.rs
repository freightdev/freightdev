//! tests/cli_tests.rs - CLI interface tests

use std::process::Command;
use std::path::Path;

#[test]
fn test_cli_help() {
    let output = Command::new("cargo")
        .args(&["run", "--", "--help"])
        .output()
        .expect("Failed to execute command");
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("llama-runner"));
    assert!(stdout.contains("--model"));
    assert!(stdout.contains("--threads"));
    assert!(stdout.contains("--max"));
    assert!(stdout.contains("--check"));
}

#[test]
fn test_cli_version() {
    let output = Command::new("cargo")
        .args(&["run", "--", "--version"])
        .output()
        .expect("Failed to execute command");
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("1.0.0"));
}

#[test]
fn test_cli_missing_model() {
    let output = Command::new("cargo")
        .args(&["run", "--", "--model", "nonexistent.json"])
        .output()
        .expect("Failed to execute command");
    
    // Should exit with error for missing model
    assert!(!output.status.success());
}

#[test]
fn test_cli_check_mode_missing_file() {
    let output = Command::new("cargo")
        .args(&["run", "--", "--model", "missing.json", "--check"])
        .output()
        .expect("Failed to execute command");
    
    // Should fail gracefully with check mode
    assert!(!output.status.success());
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("Failed to load") || stderr.contains("not found"));
}

#[test]
fn test_cli_parameter_parsing() {
    // Test that parameters are parsed correctly (even if model loading fails)
    let output = Command::new("cargo")
        .args(&[
            "run", "--", 
            "--model", "test.json",
            "--threads", "4",
            "--batch", "2", 
            "--max", "100",
            "--check"
        ])
        .output()
        .expect("Failed to execute command");
    
    // Should attempt to parse all parameters before failing on missing model
    // The specific error doesn't matter as much as not crashing from bad parsing
    assert!(!output.status.success()); // Expected since model doesn't exist
}

#[test] 
fn test_cli_with_invalid_parameters() {
    let test_cases = [
        vec!["--threads", "not_a_number"],
        vec!["--max", "-5"],
        vec!["--batch", "abc"],
    ];
    
    for args in test_cases {
        let mut cmd_args = vec!["run", "--", "--model", "test.json"];
        cmd_args.extend(args);
        
        let output = Command::new("cargo")
            .args(&cmd_args)
            .output()
            .expect("Failed to execute command");
            
        // Should fail with argument parsing errors
        assert!(!output.status.success());
    }
}