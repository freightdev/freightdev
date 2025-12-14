// source: src/libs/clean.rs
// src/libs/clean.rs

use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

pub async fn run(dir: &str) {
    println!("🧼 --clean: Converting `{dir}` into .mark format...");

    let source = Path::new(dir);
    let dest = source.join(".mark/converted");

    for entry in WalkDir::new(source)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().is_file())
    {
        let src_path = entry.path();
        let rel = src_path.strip_prefix(source).unwrap();
        let flat_name = rel.to_string_lossy().replace("/", "_").replace("\\", "_");

        let new_file = dest.join(format!("marks/marks.{}", flat_name));
        fs::create_dir_all(new_file.parent().unwrap()).unwrap();

        let header = format!("# Mark: {}\n\n---\n\n", flat_name);
        let contents = fs::read_to_string(src_path).unwrap_or_default();

        fs::write(new_file, format!("{header}{contents}")).unwrap();
    }

    println!("✅ All files migrated to: {}", dest.display());
}