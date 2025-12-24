//! prompt/system.rs — system prompt helpers for REPL startup

use std::ffi::CString;
use crate::bindings::*;

/// Tokenizes and returns the default system prompt tokens
pub fn default_system_prompt_tokens(vocab: *mut llama_vocab) -> Vec<llama_token> {
    let system_prompt = "<s>System: You are a helpful assistant.\n";
    let cstr = CString::new(system_prompt).unwrap();
    let mut buf = [0; 2048];
    let n = unsafe {
        llama_tokenize(
            vocab,
            cstr.as_ptr(),
            system_prompt.len() as i32,
            buf.as_mut_ptr(),
            buf.len() as i32,
            true,
            false,
        )
    };
    buf[..n as usize].to_vec()
}
