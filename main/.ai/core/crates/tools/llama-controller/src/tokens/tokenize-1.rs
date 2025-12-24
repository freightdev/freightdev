use crate::errors::{LlamaError, Result};

/// Tokenizes a single string input into a vector of tokens.
pub fn tokenize(input: &str) -> Result<Vec<String>> {
    if input.is_empty() {
        return Err(LlamaError::TokenizationError(
            "Input string is empty".to_string(),
        ));
    }

    // Simple whitespace + punctuation splitting
    let tokens = input
        .split(|c: char| c.is_whitespace() || c.is_ascii_punctuation())
        .filter(|t| !t.is_empty())
        .map(|s| s.to_string())
        .collect();

    Ok(tokens)
}

/// Detokenizes a vector of tokens back into a string.
pub fn detokenize(tokens: &[String]) -> Result<String> {
    if tokens.is_empty() {
        return Err(LlamaError::TokenizationError(
            "Token vector is empty".to_string(),
        ));
    }

    Ok(tokens.join(" "))
}


pub fn tokenize(text: &str, vocab: *const llama_vocab, add_bos: bool) -> Result<Vec<i32>> {
    // Prompt-specific tokenization logic
    Ok(vec![1, 2, 3, 4])
}