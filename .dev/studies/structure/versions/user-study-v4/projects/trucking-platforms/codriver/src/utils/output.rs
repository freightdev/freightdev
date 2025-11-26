//! output.rs - Utility functions for logging and clipboard integration.

use std::fs::{create_dir_all, write};
use chrono::Utc;

/// Saves the given output string to a timestamped markdown file in `.logs/`.
pub fn log_output(label: &str, content: &str) {
    let timestamp = Utc::now().format("%Y%m%dT%H%M%S");
    let _ = create_dir_all(".logs");
    let path = format!(".logs/{}-{}.md", label, timestamp);
    if let Err(e) = write(&path, content) {
        eprintln!("⚠️  Failed to write log file: {e}");
    } else {
        println!("📝 Log saved: {}", path);
    }
}

/// Copies a string to the system clipboard (Linux-only, requires `xclip`).
pub fn copy_to_clipboard(content: &str) {
    #[cfg(target_os = "linux")]
    if std::process::Command::new("which").arg("xclip").output().is_ok() {
        let _ = std::process::Command::new("xclip")
            .args(&["-selection", "clipboard"])
            .stdin(std::process::Stdio::piped())
            .spawn()
            .and_then(|mut child| {
                use std::io::Write;
                if let Some(stdin) = child.stdin.as_mut() {
                    stdin.write_all(content.as_bytes()).ok();
                }
                child.wait().ok();
                Ok(())
            });
    }
}
