use std::fs;
use std::io::{self, BufRead};
use std::path::{Path, PathBuf};
use std::collections::{HashMap, HashSet};

fn main() {
    let src_dir = Path::new("src");
    let mut module_funcs: HashMap<String, Vec<String>> = HashMap::new();
    let mut module_uses: HashMap<String, Vec<String>> = HashMap::new();

    fn read_rs_files(path: &Path, prefix: String, 
                    module_funcs: &mut HashMap<String, Vec<String>>, 
                    module_uses: &mut HashMap<String, Vec<String>>) {
        if path.is_dir() {
            for entry in fs::read_dir(path).unwrap() {
                let entry = entry.unwrap();
                let path = entry.path();
                let name = entry.file_name().into_string().unwrap();
                if path.is_dir() {
                    let new_prefix = if prefix.is_empty() { name.clone() } else { format!("{}::{}", prefix, name) };
                    read_rs_files(&path, new_prefix, module_funcs, module_uses);
                } else if name.ends_with(".rs") {
                    let module_name = if name == "mod.rs" { prefix.clone() } else {
                        if prefix.is_empty() { name.trim_end_matches(".rs").to_string() } else { format!("{}::{}", prefix, name.trim_end_matches(".rs")) }
                    };
                    let file = fs::File::open(&path).unwrap();
                    let reader = io::BufReader::new(file);
                    let mut funcs = Vec::new();
                    let mut uses = Vec::new();
                    for line in reader.lines() {
                        let line = line.unwrap();
                        if let Some(f) = line.trim().strip_prefix("pub fn ") {
                            let f_name = f.split('(').next().unwrap().to_string();
                            funcs.push(f_name);
                        } else if let Some(f) = line.trim().strip_prefix("fn ") {
                            let f_name = f.split('(').next().unwrap().to_string();
                            funcs.push(f_name);
                        } else if line.trim().starts_with("use crate::") {
                            let used_module = line.trim().trim_start_matches("use crate::").split(|c| c==';' || c==' ').next().unwrap().to_string();
                            uses.push(used_module);
                        }
                    }
                    module_funcs.insert(module_name.clone(), funcs);
                    module_uses.insert(module_name.clone(), uses);
                }
            }
        }
    }

    read_rs_files(src_dir, String::new(), &mut module_funcs, &mut module_uses);

    println!("Modules and their declared functions:\n");
    for (module, funcs) in &module_funcs {
        println!("Module: {}", module);
        for f in funcs {
            println!("  {}", f);
        }
        println!();
    }

    println!("Checking for missing imports...\n");
    let all_modules: HashSet<String> = module_funcs.keys().cloned().collect();
    for (module, uses) in &module_uses {
        for u in uses {
            if !all_modules.contains(u) {
                println!("Module '{}' uses module '{}' but it is not declared", module, u);
            }
        }
    }
}
