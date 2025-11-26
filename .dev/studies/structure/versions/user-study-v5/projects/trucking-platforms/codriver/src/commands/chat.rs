// source: src/libs/chat.rs
// src/libs/chat.rs

use std::fs;
use std::path::Path;
use dialoguer::{theme::ColorfulTheme, Input, Select};

pub async fn run(dir: &str) {
    let base = Path::new(dir).join(".mark/agents");
    let Ok(entries) = fs::read_dir(&base) else {
        println!("❌ No agents found at {:?}", base);
        return;
    };

    let mut agents = vec![];

    for entry in entries.flatten() {
        let path = entry.path().join("marks");
        let md_file = path.join(format!("md.{}", entry.file_name().to_str().unwrap()));
        if md_file.exists() {
            agents.push(entry.file_name().to_str().unwrap().to_string());
        }
    }

    if agents.is_empty() {
        println!("❌ No agents with md.[agent] found.");
        return;
    }

    let theme = ColorfulTheme::default();
    let agent_index = Select::with_theme(&theme)
        .with_prompt("🧠 Select an agent to chat with")
        .items(&agents)
        .default(0)
        .interact()
        .unwrap();

    let agent_name = &agents[agent_index];
    let md_path = base.join(agent_name).join("marks").join(format!("md.{}", agent_name));
    let Ok(md_content) = fs::read_to_string(md_path) else {
        println!("❌ Could not read agent file.");
        return;
    };

    println!("\n💡 Agent `{}` loaded.\n", agent_name);
    println!("{}", md_content);
    println!("💬 Type your prompt below (type `/exit` to quit)\n");

    loop {
        let prompt: String = Input::with_theme(&theme)
            .with_prompt("🗨️  You")
            .interact_text()
            .unwrap();

        if prompt == "/exit" {
            println!("👋 Exiting chat.");
            break;
        }

        if prompt == "/clear" {
            println!("\x1B[2J\x1B[1;1H"); // ANSI clear screen
            continue;
        }

        // In future: run tool, respond from model, etc.
        println!("🤖 [{}]: \"{}\"", agent_name, fake_response(&prompt));
    }
}

fn fake_response(input: &str) -> String {
    format!("You said: '{}'. I'm not smart yet, but I hear you!", input)
}