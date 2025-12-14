use std::path::{Path, PathBuf};

/// Returns the default path to the primary model file.
pub fn default_model_path() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("src/providers/mistral-7b/Q4_K_M/model.gguf")
}

/// Resolves a model name like "mistral" to its path
pub fn resolve_model_path(name: &str) -> Option<PathBuf> {
    let base = Path::new(env!("CARGO_MANIFEST_DIR")).join("src/providers");

    match name {
        "mistral" => Some(base.join("mistral-7b/Q4_K_M/model.gguf")),
        "codellama" => Some(base.join("codellama-7b/Q4_K_M/model.gguf")),
        "zephyr" => Some(base.join("zephyr-7b/Q4_K_M/model.gguf")),
        _ => None,
    }
}
