//! main.rs — entry point with clap for llama-runner CLI


use std::path::Path;
use clap::Parser;

// Reuse your own library instead of declaring modules again
use llama_libs::{check_model, run_interactive};


/// Cleanest Local LLM CLI on the Market
#[derive(Parser, Debug)]
#[command(name = "llama-runner", version, about)]
struct Cli {
    /// Path to GGUF model
    #[arg(long, value_name = "PATH")]
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
        check_model(path);
    } else {
        run_interactive(path, cli.threads, cli.batch_threads, cli.max_tokens);
    }
}
