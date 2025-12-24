//! scripts/fix_imports.rs
use std::{
    fs,
    io::{self, BufRead},
    path::{Path},
};

fn main() {
    let src_dir = Path::new("src");
    if !src_dir.exists() {
        eprintln!("src directory not found");
        std::process::exit(1);
    }

    let rs_files = collect_rs_files(src_dir);
    let mut module_map = Vec::new();

    for file in rs_files {
        let module_name = module_name_from_path(&file, src_dir);
        let functions = extract_functions(&file);
        let used_items = extract_used_items(&file);
        module_map.push((module_name, functions, used_items));
    }

    println!("Modules and their declared functions:\n");
    for (module_name, functions, _) in &module_map {
        println!("Module: {}", module_name);
        for func in functions {
            println!("  {}", func);
        }
        println!();
    }

    println!("Checking for missing imports...\n");
    for (module_name, _functions, used_items) in &module_map {
        if used_items.is_empty() {
            continue;
        }
        println!("// Module: {}", module_name);
        for item in used_items {
            println!("use crate::{};", item);
        }
        println!();
    }
}

fn collect_rs_files(dir: &Path) -> Vec<std::path::PathBuf> {
    let mut files = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                files.extend(collect_rs_files(&path));
            } else if path.extension().map_or(false, |e| e == "rs") {
                files.push(path);
            }
        }
    }
    files
}

fn module_name_from_path(file: &Path, src_dir: &Path) -> String {
    let relative = file.strip_prefix(src_dir).unwrap();
    let mut parts: Vec<String> = relative
        .components()
        .map(|c| c.as_os_str().to_string_lossy().to_string())
        .collect();

    if let Some(last) = parts.last_mut() {
        *last = last.trim_end_matches(".rs").to_string();
    }

    parts.join("::")
}

fn extract_functions(file: &Path) -> Vec<String> {
    let mut functions = Vec::new();
    if let Ok(f) = fs::File::open(file) {
        for line in io::BufReader::new(f).lines().flatten() {
            let line = line.trim();
            if line.starts_with("fn ") || line.contains(" fn ") {
                if let Some(name) = line.split_whitespace().nth(1) {
                    let name = name.split('(').next().unwrap_or(name);
                    functions.push(name.to_string());
                }
            }
        }
    }
    functions
}

fn extract_used_items(file: &Path) -> Vec<String> {
    let mut items = Vec::new();
    if let Ok(f) = fs::File::open(file) {
        for line in io::BufReader::new(f).lines().flatten() {
            let line = line.trim();
            if line.starts_with("use ") && line.contains("crate::") {
                items.push(line.trim_end_matches(';').to_string());
            } else if line.contains("::") {
                let parts = line.split(|c| c == '(' || c == ';').next().unwrap_or("").split("::");
                let path: Vec<String> = parts.map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect();
                if path.len() >= 2 {
                    items.push(path[..path.len() - 1].join("::"));
                }
            }
        }
    }
    items.sort();
    items.dedup();
    items
}
