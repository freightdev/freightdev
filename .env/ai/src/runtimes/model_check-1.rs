//! runner/check.rs — model integrity check utility

use std::ffi::CString;
use std::path::Path;

use crate::bindings::*;

/// Loads the model and performs a minimal integrity check.
/// Exits the program on failure.
pub fn check_model(model_path: &Path) {
    unsafe {
        llama_backend_init();

        let cpath = CString::new(model_path.to_str().unwrap()).unwrap();
        let model = llama_load_model_from_file(cpath.as_ptr(), llama_model_default_params());
        if model.is_null() {
            eprintln!("❌ Model failed to load: {}", model_path.display());
            std::process::exit(1);
        }

        let vocab = llama_model_get_vocab(model);
        let eos = llama_token_eos(vocab);

        println!("✅ Model loaded: {}", model_path.display());
        println!("📚 Vocab pointer: {:p}", vocab);
        println!("🔚 EOS Token ID: {}", eos);

        llama_free_model(model);
    }
}
