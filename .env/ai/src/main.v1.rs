// Autonomous Coordinator - Self-directing AI agent
// Can use tools, make decisions, orchestrate agents
// Uses local llama.cpp for decision-making

mod tools;
mod llm;
mod agent;
mod system;

use agent::AutonomousAgent;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    println!("╔════════════════════════════════════════════════════════════╗");
    println!("║        🤖 Autonomous Coordinator - Self-Directing AI      ║");
    println!("╚════════════════════════════════════════════════════════════╝");
    println!();
    println!("Capabilities:");
    println!("  ✓ Bash command execution");
    println!("  ✓ File read/write/edit operations");
    println!("  ✓ Web search");
    println!("  ✓ Agent orchestration");
    println!("  ✓ LLM-powered decision making");
    println!();
    println!("Brain: llama.cpp (http://localhost:11435)");
    println!("Mode: Autonomous with safety checks");
    println!();

    // Get objective from command line or use default
    let objective = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "Monitor and improve CoDriver system".to_string());

    println!("🎯 Objective: {}", objective);
    println!();
    println!("Press Ctrl+C to stop");
    println!();

    // Create and run autonomous agent with objective
    let mut agent = AutonomousAgent::with_objective(objective).await?;

    agent.run().await?;

    Ok(())
}
