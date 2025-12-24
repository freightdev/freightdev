//! src/models/runners/interactive.rs
use crate::*;
use std::io::{self, Write};

pub fn run_interactive(model_path: &std::path::Path, threads: i32, batch_threads: i32, max_tokens: i32) {
    // Load model
    let model = match load_model(model_path) {
        Ok(m) => m,
        Err(e) => {
            eprintln!("Failed to load model: {}", e);
            return;
        }
    };

    println!("Model loaded successfully. Enter your prompts:");

    loop {
        print!("> ");
        io::stdout().flush().unwrap();

        let mut input = String::new();
        if io::stdin().read_line(&mut input).is_err() {
            eprintln!("Failed to read input");
            continue;
        }

        let input = input.trim();
        if input.is_empty() {
            continue;
        }

        if input.eq_ignore_ascii_case("exit") || input.eq_ignore_ascii_case("quit") {
            println!("Exiting interactive session...");
            break;
        }

        match generate_response(&model, input, threads, batch_threads, max_tokens) {
            Ok(output) => println!("{}", output),
            Err(e) => eprintln!("Error generating response: {}", e),
        }
    }
}
