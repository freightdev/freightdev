//! src/main.rs - Entry point for freightdev-runner CLI

use std::path::Path;
use clap::Parser;
use crate::*;
mod bindings;

#[derive(Parser, Debug)]
#[command(name = "freightdev-runner", version, about = "LLM CLI for MARK System")]
struct Cli {
    /// Path to model.json file
    #[arg(short, long, value_name = "PATH")]
    model: String,

    /// Number of threads to use
    #[arg(long, default_value_t = 16)]
    threads: i32,

    /// Threads per batch
    #[arg(long = "batch", default_value_t = 8)]
    batch_threads: i32,

    /// Maximum number of tokens to generate
    #[arg(long = "max", default_value_t = 256)]
    max_tokens: i32,

    /// Just check that the model loads (no interactive loop)
    #[arg(long)]
    check: bool,
}

fn main() {
    let cli = Cli::parse();
    let path = Path::new(&cli.model);

    if cli.check {
        if let Err(e) = models::runners::model_check::check_model_compatibility(path) {
            eprintln!("❌ Model check failed: {}", e);
        }
    } else {
        runners::interactive::run_interactive(path, cli.threads, cli.batch_threads, cli.max_tokens);
    }
}
