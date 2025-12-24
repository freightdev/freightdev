//! src/tokens/batch.rs
use crate::errors::{LlamaError, Result};
use crate::tokens::tokenize;

/// Processes a batch of input strings and returns tokenized outputs.
pub fn process_batch(inputs: Vec<String>) -> Result<Vec<Vec<String>>> {
    if inputs.is_empty() {
        return Err(LlamaError::TokenizationError(
            "Input batch is empty".to_string(),
        ));
    }
    
    let mut results = Vec::with_capacity(inputs.len());
    
    for input in inputs {
        match tokenize::tokenize(&input) {
            Ok(tokens) => results.push(tokens),
            Err(e) => return Err(LlamaError::TokenizationError(format!(
                "Failed to tokenize input '{}': {}",
                input, e
            ))),
        }
    }
    
    Ok(results)
}

/// Processes a batch of detokenization
pub fn detokenize_batch(token_batches: Vec<Vec<String>>) -> Result<Vec<String>> {
    if token_batches.is_empty() {
        return Err(LlamaError::TokenizationError(
            "Token batch vector is empty".to_string(),
        ));
    }
    
    let mut outputs = Vec::with_capacity(token_batches.len());
    
    for tokens in token_batches {
        match tokenize::detokenize(&tokens) {
            Ok(s) => outputs.push(s),
            Err(e) => return Err(LlamaError::TokenizationError(format!(
                "Failed to detokenize batch: {}",
                e
            ))),
        }
    }
    
    Ok(outputs)
}