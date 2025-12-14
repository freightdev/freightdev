


fn log_help() {
    println!("\n📖 Available commands:");
    println!("  help  - Show this help message");
    println!("  stats - Show model statistics");
    println!("  exit  - Exit the program");
    println!("  quit  - Exit the program");
    println!("  bye   - Exit the program");
    println!("\nJust type your message for inference!");
}

fn log_stats(context: &Context) -> Result<()> {
    println!("\n📊 Model Statistics:");
    
    if let Ok(vocab_size) = context.get_vocab_size() {
        println!("  Vocabulary size: {}", vocab_size);
    }
    
    if let Ok(ctx_size) = context.get_context_size() {
        println!("  Context size: {}", ctx_size);
    }
    
    println!("  Memory usage: [Not implemented]");
    println!("  Tokens generated: [Not implemented]");
    
    Ok(())
}