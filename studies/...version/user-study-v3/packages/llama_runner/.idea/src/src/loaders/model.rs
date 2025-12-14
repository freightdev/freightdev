//! loaders/model.rs — load model metadata JSON from `$ROOT/models/*/model.json`

use std::fs;
use std::path::Path;
use std::io::Read;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelMetadata {
    pub name: String,
    pub variant: String,
    pub path: String,
    pub size: String,
    pub quantization: String,
    pub license: String,
    pub source: String,
}

pub fn load_all_models(models_dir: &str) -> Vec<ModelMetadata> {
    let base = Path::new(models_dir);
    if !base.exists() {
        eprintln!("❌ Models directory not found: {}", models_dir);
        return vec![];
    }

    let mut models = Vec::new();

    for entry in fs::read_dir(base).expect("❌ Failed to read models directory") {
        if let Ok(entry) = entry {
            let subdir = entry.path();
            let meta_path = subdir.join("model.json");
            if meta_path.exists() {
                match fs::File::open(&meta_path) {
                    Ok(mut file) => {
                        let mut contents = String::new();
                        if file.read_to_string(&mut contents).is_ok() {
                            match serde_json::from_str::<ModelMetadata>(&contents) {
                                Ok(meta) => models.push(meta),
                                Err(e) => eprintln!("⚠️ Invalid JSON in {}: {}", meta_path.display(), e),
                            }
                        }
                    }
                    Err(e) => eprintln!("⚠️ Could not open {}: {}", meta_path.display(), e),
                }
            }
        }
    }

    models
}

/// Load a single model.json given a path like models/mistral-7b/model.json
pub fn load_model<P: AsRef<Path>>(model_json_path: P) -> Option<ModelMetadata> {
    let path = model_json_path.as_ref();
    if !path.exists() {
        eprintln!("❌ Model file not found: {}", path.display());
        return None;
    }

    match fs::read_to_string(path) {
        Ok(contents) => match serde_json::from_str::<ModelMetadata>(&contents) {
            Ok(model) => Some(model),
            Err(e) => {
                eprintln!("⚠️ Failed to parse model JSON: {}", e);
                None
            }
        },
        Err(e) => {
            eprintln!("⚠️ Could not read {}: {}", path.display(), e);
            None
        }
    }
}
