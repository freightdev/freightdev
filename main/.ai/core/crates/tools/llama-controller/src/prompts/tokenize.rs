//! prompt/tokenize.rs — simple wrapper for llama_tokenize()

use std::ffi::CString;
use crate::bindings::*;

/// Tokenizes a string using the given vocab
pub fn tokenize(text: &str, vocab: *const llama_vocab, add_bos: bool) -> Vec<llama_token> {
    let cstr = CString::new(text).unwrap();
    let mut buf = [0; 2048];
    let n = unsafe {
        llama_tokenize(
            vocab,
            cstr.as_ptr(),
            text.len() as i32,
            buf.as_mut_ptr(),
            buf.len() as i32,
            add_bos,
            false,
        )
    };
    buf[..n as usize].to_vec()
}
