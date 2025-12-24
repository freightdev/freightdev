//! src/models/runners/model_check.rs
use crate::*;

pub fn check_model_compatibility(model_path: &std::path::Path) -> Result<()> {
    let model = load_model(model_path)?;
    
    if model.layers.is_empty() {
        return Err(LlamaError::ModelLoadError("Model has no layers".to_string()));
    }

    if model.vocab_size == 0 {
        return Err(LlamaError::ModelLoadError("Model vocabulary is empty".to_string()));
    }

    println!(
        "✅ Model '{}' loaded successfully with {} layers and {} tokens.",
        model_path.display(),
        model.layers.len(),
        model.vocab_size
    );

    Ok(())
}
