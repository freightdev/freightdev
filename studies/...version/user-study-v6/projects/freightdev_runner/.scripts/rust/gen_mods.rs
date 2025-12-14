use std::fs;
use std::path::{Path, PathBuf};
use std::io::Write;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let src_path = Path::new("src");
    generate_mod_files(src_path)?;
    println!("✅ All mod.rs files generated successfully!");
    Ok(())
}

fn generate_mod_files(dir: &Path) -> Result<(), Box<dyn std::error::Error>> {
    if !dir.is_dir() {
        return Ok(());
    }

    let mut rust_files = Vec::new();
    let mut subdirs = Vec::new();

    // Read directory contents
    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        let file_name = entry.file_name();
        let file_name_str = file_name.to_string_lossy();

        if path.is_file() && file_name_str.ends_with(".rs") && file_name_str != "mod.rs" {
            // Check if file has actual content (not just empty/whitespace)
            let content = fs::read_to_string(&path)?;
            let has_content = content.trim().len() > 0 && 
                            !content.trim().starts_with("//") || 
                            content.lines().filter(|line| !line.trim().is_empty() && !line.trim().starts_with("//")).count() > 0;
            
            if has_content {
                let module_name = file_name_str.trim_end_matches(".rs");
                rust_files.push(module_name.to_string());
            } else {
                println!("⚠️  Skipping empty file: {}", path.display());
            }
        } else if path.is_dir() {
            subdirs.push(file_name_str.to_string());
        }
    }

    // Generate mod.rs for subdirectories first
    for subdir in &subdirs {
        let subdir_path = dir.join(subdir);
        generate_mod_files(&subdir_path)?;
    }

    // Generate mod.rs for current directory if it has modules
    if !rust_files.is_empty() || !subdirs.is_empty() {
        let mod_file_path = dir.join("mod.rs");
        let mut mod_content = String::new();

        // Add subdirectories as modules
        for subdir in &subdirs {
            mod_content.push_str(&format!("pub mod {};\n", subdir));
        }

        // Add rust files as modules
        for rust_file in &rust_files {
            mod_content.push_str(&format!("pub mod {};\n", rust_file));
        }

        if !subdirs.is_empty() || !rust_files.is_empty() {
            mod_content.push('\n');
        }

        // Add re-exports for subdirectories
        for subdir in &subdirs {
            mod_content.push_str(&format!("pub use {}::*;\n", subdir));
        }

        // Add re-exports for rust files
        for rust_file in &rust_files {
            mod_content.push_str(&format!("pub use {}::*;\n", rust_file));
        }

        // Write the mod.rs file
        let mut file = fs::File::create(&mod_file_path)?;
        file.write_all(mod_content.as_bytes())?;
        
        println!("📝 Generated: {}", mod_file_path.display());
        println!("   Modules: {:?}", rust_files);
        println!("   Subdirs: {:?}", subdirs);
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_mod_generation() {
        let temp_dir = TempDir::new().unwrap();
        let src_path = temp_dir.path().join("src");
        fs::create_dir_all(&src_path).unwrap();

        // Create test files
        fs::write(src_path.join("lib.rs"), "// Main lib").unwrap();
        fs::create_dir_all(src_path.join("models")).unwrap();
        fs::write(src_path.join("models").join("chat.rs"), "pub struct Chat;").unwrap();
        fs::write(src_path.join("models").join("empty.rs"), "").unwrap();

        generate_mod_files(&src_path).unwrap();

        let mod_content = fs::read_to_string(src_path.join("models").join("mod.rs")).unwrap();
        assert!(mod_content.contains("pub mod chat;"));
        assert!(!mod_content.contains("pub mod empty;"));
    }
}