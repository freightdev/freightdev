// source: src/libs/setup.rs
// src/libs/setup.rs

use std::fs::{self, create_dir_all};
use std::io::Write;
use std::path::Path;
use dialoguer::{theme::ColorfulTheme, Confirm, Input};

pub async fn run(dir: &str) {
    println!("\n🛠️ --setup: Full project setup at {dir}\n");

    setup_tools(dir).await;
    setup_paths(dir).await;
    setup_marks(dir).await;
    setup_markers(dir).await;
    setup_bookmarks(dir).await;

    println!("\n✅ Full project setup completed in `{dir}`\n");
}

async fn setup_tools(dir: &str) {
    println!("\n🔧 [TOOLS] Starting tool setup...");

    let theme = ColorfulTheme::default();

    let tools_root = Path::new(dir).join(".mark/tools");
    create_dir_all(&tools_root).unwrap();

    let mut tool_list = Vec::new();

    loop {
        let name: String = Input::with_theme(&theme)
            .with_prompt("🔩 Tool name")
            .interact_text()
            .unwrap();

        let intent: String = Input::with_theme(&theme)
            .with_prompt("🧠 Tool intent")
            .interact_text()
            .unwrap();

        let output: String = Input::with_theme(&theme)
            .with_prompt("📤 Example output")
            .interact_text()
            .unwrap();

        let tool_dir = tools_root.join(&name).join("marks");
        create_dir_all(&tool_dir).unwrap();

        let tool_md_path = tool_dir.join(format!("md.{}", name));
        let tool_md = format!(
            r#"# Tool: {name}

## Intent
{intent}

## Example Output
{output}
"#
        );
        fs::write(&tool_md_path, tool_md).unwrap();

        tool_list.push(name);

        let again = Confirm::with_theme(&theme)
            .with_prompt("Add another tool?")
            .interact()
            .unwrap();
        if !again {
            break;
        }
    }

    let index = tools_root.join("tool.marks");
    let index_content = tool_list
        .iter()
        .map(|tool| format!("- tools/{}/marks/marks.{}", tool, tool))
        .collect::<Vec<_>>()
        .join("\n");
    fs::write(index, format!("# Tool Index\n{}\n", index_content)).unwrap();

    println!("✅ Tools setup complete.\n");
}

async fn setup_paths(dir: &str) {
    println!("\n📂 [PATHS] Creating base directory structure...");

    let folders = [
        ".mark/agents",
        ".mark/tools",
        ".mark/agents/workspace",
        ".mark/agents/notebook",
        ".mark/tools/workspace",
        ".mark/tools/notebook",
    ];

    for f in folders.iter() {
        create_dir_all(Path::new(dir).join(f)).unwrap();
    }

    let mstp = Path::new(dir).join(".mark/mark.mstp");
    fs::write(mstp, "# MARK Setup Path\n- .mark/agents/agent.marks\n- .mark/tools/tool.marks\n").unwrap();

    println!("✅ Directory and mark.mstp setup complete.\n");
}

async fn setup_marks(dir: &str) {
    println!("\n✍️ [MARKS] Add task files for agents...");

    let theme = ColorfulTheme::default();

    loop {
        let agent: String = Input::with_theme(&theme)
            .with_prompt("🤖 Agent name")
            .interact_text()
            .unwrap();

        let task: String = Input::with_theme(&theme)
            .with_prompt("🎯 Task name")
            .interact_text()
            .unwrap();

        let steps: String = Input::with_theme(&theme)
            .with_prompt("📋 What should this task do?")
            .interact_text()
            .unwrap();

        let marks_path = Path::new(dir).join(".mark/agents").join(&agent).join("marks");
        create_dir_all(&marks_path).unwrap();

        let mark_path = marks_path.join(format!("marks.{}", agent));

        let content = format!(
            r#"\n## Task: {task}

### Description
{steps}
"#
        );
        fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&mark_path)
            .unwrap()
            .write_all(content.as_bytes())
            .unwrap();

        let again = Confirm::with_theme(&theme)
            .with_prompt("Add another task?")
            .interact()
            .unwrap();

        if !again {
            break;
        }
    }

    println!("✅ Task marks created.\n");
}

async fn setup_markers(dir: &str) {
    println!("\n📍 [MARKERS] Defining marker agents...");

    let theme = ColorfulTheme::default();

    loop {
        let agent: String = Input::with_theme(&theme)
            .with_prompt("🤖 Target agent for this marker")
            .interact_text()
            .unwrap();

        let marker_name: String = Input::with_theme(&theme)
            .with_prompt("📛 Marker name")
            .interact_text()
            .unwrap();

        let trigger: String = Input::with_theme(&theme)
            .with_prompt("🎯 When should this marker be used?")
            .interact_text()
            .unwrap();

        let effect: String = Input::with_theme(&theme)
            .with_prompt("🌀 What should the marker trigger or assist with?")
            .interact_text()
            .unwrap();

        let marks_path = Path::new(dir).join(".mark/agents").join(&agent).join("marks");
        create_dir_all(&marks_path).unwrap();

        let marker_path = marks_path.join(format!("markers.{}", agent));

        let content = format!(
            r#"\n## Marker: {marker_name}

### Trigger
{trigger}

### Effect
{effect}
"#
        );
        fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&marker_path)
            .unwrap()
            .write_all(content.as_bytes())
            .unwrap();

        let continue_prompt = Confirm::with_theme(&theme)
            .with_prompt("Add another marker?")
            .interact()
            .unwrap();

        if !continue_prompt {
            break;
        }
    }

    println!("✅ Marker setup complete.\n");
}

async fn setup_bookmarks(dir: &str) {
    println!("\n📚 [BOOKMARKS] Initializing story bookmarks...");

    let bookmarks = r#"# Bookmarks Cache

- Last Active Agent: None
- Last Completed Task: None
- Current Story Path: .mark/mark.mstp
"#;

    let path = Path::new(dir).join(".mark/bookmarks.mstp");
    fs::write(&path, bookmarks).unwrap();

    println!("✅ Bookmarks cache created.\n");
}