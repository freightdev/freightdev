//! context.rs - Utilities for reading, tokenizing, and summarizing file context.

use std::fs;
use std::path::{Path, PathBuf};

pub fn read_file<P: AsRef<Path>>(path: P) -> Result<String, String> {
    fs::read_to_string(&path).map_err(|e| format!("Failed to read file {}: {e}", path.as_ref().display()))
}

pub fn read_lines<P: AsRef<Path>>(path: P, start: usize, end: usize) -> Result<String, String> {
    let contents = read_file(&path)?;
    let lines: Vec<&str> = contents.lines().collect();

    if start >= lines.len() || end > lines.len() || start >= end {
        return Err("Invalid line range".to_string());
    }

    Ok(lines[start..end].join("\n"))
}

pub fn summarize_path<P: AsRef<Path>>(path: P) -> String {
    let full_path = PathBuf::from(path.as_ref());
    format!("Context file: {}", full_path.display())
}
