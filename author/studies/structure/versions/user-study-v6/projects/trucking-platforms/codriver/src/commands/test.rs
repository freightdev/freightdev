// source: src/libs/test.rs
// src/libs/test.rs

use std::fs;
use std::path::{Path, PathBuf};

pub async fn run(dir: &str) {
    println!("🧪 --test: Simulating .mstp execution for `{dir}`");

    let base = Path::new(dir).join(".mark");
    let mstp = base.join("mark.mstp");

    let Ok(contents) = fs::read_to_string(&mstp) else {
        println!("❌ No mark.mstp found at {}", mstp.display());
        return;
    };

    let mut steps = Vec::new();

    for line in contents.lines().filter_map(|l| l.strip_prefix("- ").map(str::trim)) {
        let full_path = base.join(line);
        if full_path.exists() {
            steps.push(full_path);
        } else {
            println!("⚠️ Missing: {}", full_path.display());
        }
    }

    println!("\n🔄 Beginning dry-run task simulation:\n");

    for path in &steps {
        if path.ends_with(".marks") {
            if let Ok(data) = fs::read_to_string(&path) {
                println!("📄 {}", path.display());
                for line in data.lines().filter(|l| l.starts_with("#") || l.starts_with("##")) {
                    println!("  {line}");
                }
                println!("✅ Simulated execution complete.\n");
            }
        }
    }

    println!("🎉 Dry-run finished. {} tasks simulated.\n", steps.len());
}