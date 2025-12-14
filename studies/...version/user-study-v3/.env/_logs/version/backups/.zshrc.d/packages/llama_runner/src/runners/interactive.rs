//! runner/interactive.rs — REPL interface using llama.cpp + tokenizer/prompt.rs + loaders/model.rs

use std::ffi::CString;
use std::io::{self, Write};
use std::path::Path;
use std::{slice, str};

use crate::bindings::*;
use crate::tokens::*;
use crate::prompts::*;
use crate::loaders::model::load_model;

/// Starts an interactive REPL session with the model
pub fn run_interactive(json_path: &Path, threads: i32, batch_threads: i32, max_tokens: i32) {
    unsafe {
        llama_backend_init();

        // Load model metadata from model.json
        let Some(meta) = load_model(json_path) else {
            eprintln!("❌ Failed to load model metadata from {}", json_path.display());
            return;
        };

        let cpath = CString::new(meta.path.clone()).unwrap();
        let model = llama_load_model_from_file(cpath.as_ptr(), llama_model_default_params());
        if model.is_null() {
            eprintln!("❌ Failed to load model binary at {}", meta.path);
            return;
        }

        let vocab = llama_model_get_vocab(model) as *mut llama_vocab;
        let eos_token = llama_token_eos(vocab);

        let mut params = llama_context_default_params();
        params.n_threads = threads;
        params.n_threads_batch = batch_threads;

        let ctx = llama_new_context_with_model(model, params);
        if ctx.is_null() {
            eprintln!("❌ Failed to create context");
            llama_free_model(model);
            return;
        }

        let context_window = params.n_ctx as usize;
        let sampler = llama_sampler_init_greedy();

        println!(
            "🧠 Loaded model '{}'. Max tokens = {}. Type 'exit' to quit.\n",
            meta.name, max_tokens
        );

        let sys_tokens = default_system_prompt_tokens(vocab);
        llama_decode(ctx, build_batch(&sys_tokens, 0).batch);

        let mut history_tokens: Vec<llama_token> = Vec::new();
        let mut current_pos = sys_tokens.len() as llama_pos;

        loop {
            let available = context_window.saturating_sub(sys_tokens.len());
            if history_tokens.len() > available {
                history_tokens.drain(..history_tokens.len() - available);
                llama_kv_self_clear(ctx);
                llama_decode(ctx, build_batch(&sys_tokens, 0).batch);
                llama_decode(ctx, build_batch(&history_tokens, sys_tokens.len() as llama_pos).batch);
                current_pos = (sys_tokens.len() + history_tokens.len()) as llama_pos;
            }

            print!(">> ");
            io::stdout().flush().unwrap();

            let mut line = String::new();
            if io::stdin().read_line(&mut line).is_err() {
                break;
            }

            let line = line.trim();
            if line.eq_ignore_ascii_case("exit") {
                break;
            }
            if line.is_empty() {
                continue;
            }

            let prompt = format_user_prompt(line);
            let user_tokens = tokenize(&prompt, vocab, false);
            if user_tokens.is_empty() {
                eprintln!("❌ Tokenization failed");
                continue;
            }

            llama_decode(ctx, build_batch(&user_tokens, current_pos).batch);
            history_tokens.extend_from_slice(&user_tokens);
            current_pos += user_tokens.len() as llama_pos;

            for _ in 0..max_tokens {
                let token = llama_sampler_sample(sampler, ctx, -1);
                if token == eos_token {
                    break;
                }

                let mut piece_buf = [0i8; 64];
                let written = llama_token_to_piece(
                    vocab,
                    token,
                    piece_buf.as_mut_ptr(),
                    piece_buf.len() as i32,
                    0,
                    false,
                );
                let bytes = slice::from_raw_parts(piece_buf.as_ptr() as *const u8, written as usize);
                let piece = str::from_utf8(bytes).unwrap_or("");

                if piece.contains("[INST]") || piece.contains("[/INST]") {
                    break;
                }

                llama_decode(ctx, build_batch(&[token], current_pos).batch);
                history_tokens.push(token);
                current_pos += 1;

                print!("{}", piece);
                io::stdout().flush().unwrap();
            }

            println!();
        }

        llama_sampler_free(sampler);
        llama_free(ctx);
        llama_free_model(model);
    }
}
