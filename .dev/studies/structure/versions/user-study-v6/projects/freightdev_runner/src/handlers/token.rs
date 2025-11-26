// src/handlers/batch_handler.rs
use crate::token::tokenize;

pub async fn handle_batch_request(input: Vec<String>) -> Vec<String> {
    // Preprocessing (optional)
    let cleaned_input: Vec<String> = input.iter().map(|s| s.trim().to_string()).collect();

    // Call core logic
    let tokenized = tokenize::tokenize_batch(cleaned_input);

    // Postprocessing (optional)
    tokenized
}
