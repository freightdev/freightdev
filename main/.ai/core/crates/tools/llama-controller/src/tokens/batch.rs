//! src/tokenizer/batch.rs — Input batch builder for llama.cpp

use crate::bindings::*;
use std::os::raw::c_int;
use std::ptr;

pub struct TokenBatch {
    pub batch: llama_batch,
    _tokens: Vec<llama_token>,
    _positions: Vec<llama_pos>,
    _seq_ids: Vec<*mut llama_seq_id>,
    _seq_val: Vec<llama_seq_id>,
    _n_seq: Vec<c_int>,
}

/// Build a llama_batch whose token positions start at `start_pos`,
/// ensuring Y = X+1 ordering for llama.cpp’s KV cache.
pub fn build_batch(tokens: &[llama_token], start_pos: llama_pos) -> TokenBatch {
    let n = tokens.len();

    // Copy tokens into owned Vec
    let mut tokens_vec = tokens.to_vec();

    // Positions must pick up where the last batch left off
    let mut positions: Vec<llama_pos> =
        (start_pos..start_pos + n as llama_pos).collect();

    // All tokens belong to sequence 0
    let mut seq_val = vec![0 as llama_seq_id; n];
    let mut seq_ids: Vec<*mut llama_seq_id> =
        seq_val.iter_mut().map(|v| v as *mut _).collect();

    // One sequence per token
    let mut n_seq = vec![1 as c_int; n];

    let batch = llama_batch {
        n_tokens: n as c_int,
        token: tokens_vec.as_mut_ptr(),
        embd: ptr::null_mut(),
        pos: positions.as_mut_ptr(),
        n_seq_id: n_seq.as_mut_ptr(),
        seq_id: seq_ids.as_mut_ptr(),
        logits: ptr::null_mut(),
    };

    TokenBatch {
        batch,
        _tokens: tokens_vec,
        _positions: positions,
        _seq_ids: seq_ids,
        _seq_val: seq_val,
        _n_seq: n_seq,
    }
}
