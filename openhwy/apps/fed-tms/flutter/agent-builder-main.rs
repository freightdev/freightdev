// File: agent-builder/src/main.rs
// Agent Conversation System - Talk to create agents

use crossterm::{
    event::{self, Event, KeyCode, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::{Block, Borders, List, ListItem, Paragraph, Wrap},
    Terminal,
};
use serde::{Deserialize, Serialize};
use std::io;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Agent {
    name: String,
    role: String,
    description: String,
    tools: Vec<String>,
    access: Vec<String>,
    constraints: Vec<String>,
    system_prompt: String,
}

#[derive(Debug, Clone)]
enum InputMode {
    Normal,
    Editing,
}

#[derive(Debug, Clone)]
enum Screen {
    AgentList,
    AgentBuilder,
    Chat,
}

struct App {
    input: String,
    input_mode: InputMode,
    messages: Vec<(String, String)>, // (role, content)
    current_agent: Option<Agent>,
    agents: Vec<Agent>,
    screen: Screen,
    cursor_position: usize,
    scroll: u16,
}

impl Default for App {
    fn default() -> App {
        App {
            input: String::new(),
            input_mode: InputMode::Normal,
            messages: vec![
                ("system".to_string(), "Welcome to Agent Builder. Tell me about the agent you want to create.".to_string()),
            ],
            current_agent: None,
            agents: load_agents(),
            screen: Screen::AgentList,
            cursor_position: 0,
            scroll: 0,
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app
    let mut app = App::default();
    let res = run_app(&mut terminal, &mut app);

    // Restore terminal
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("Error: {:?}", err);
    }

    Ok(())
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
) -> io::Result<()> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if let Event::Key(key) = event::read()? {
            match app.input_mode {
                InputMode::Normal => match key.code {
                    KeyCode::Char('q') => return Ok(()),
                    KeyCode::Char('i') => {
                        app.input_mode = InputMode::Editing;
                    }
                    KeyCode::Char('n') => {
                        app.screen = Screen::AgentBuilder;
                        app.messages.clear();
                        app.messages.push((
                            "system".to_string(),
                            "Let's build a new agent. What should I call it?".to_string(),
                        ));
                        app.current_agent = Some(Agent {
                            name: String::new(),
                            role: String::new(),
                            description: String::new(),
                            tools: vec![],
                            access: vec![],
                            constraints: vec![],
                            system_prompt: String::new(),
                        });
                    }
                    KeyCode::Char('l') => {
                        app.screen = Screen::AgentList;
                    }
                    KeyCode::Up => {
                        if app.scroll > 0 {
                            app.scroll -= 1;
                        }
                    }
                    KeyCode::Down => {
                        app.scroll += 1;
                    }
                    _ => {}
                },
                InputMode::Editing => match key.code {
                    KeyCode::Enter => {
                        let input = app.input.drain(..).collect::<String>();
                        app.messages.push(("user".to_string(), input.clone()));
                        
                        // Process user input
                        let response = process_input(&input, &mut app.current_agent);
                        app.messages.push(("assistant".to_string(), response));
                        
                        app.cursor_position = 0;
                    }
                    KeyCode::Char(c) => {
                        app.input.insert(app.cursor_position, c);
                        app.cursor_position += 1;
                    }
                    KeyCode::Backspace => {
                        if app.cursor_position > 0 {
                            app.input.remove(app.cursor_position - 1);
                            app.cursor_position -= 1;
                        }
                    }
                    KeyCode::Left => {
                        if app.cursor_position > 0 {
                            app.cursor_position -= 1;
                        }
                    }
                    KeyCode::Right => {
                        if app.cursor_position < app.input.len() {
                            app.cursor_position += 1;
                        }
                    }
                    KeyCode::Esc => {
                        app.input_mode = InputMode::Normal;
                    }
                    KeyCode::Char('s') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                        // Save agent
                        if let Some(agent) = &app.current_agent {
                            save_agent(agent);
                            app.messages.push((
                                "system".to_string(),
                                format!("Agent '{}' saved successfully!", agent.name),
                            ));
                            app.agents.push(agent.clone());
                        }
                    }
                    _ => {}
                },
            }
        }
    }
}

fn ui(f: &mut ratatui::Frame, app: &App) {
    let size = f.size();

    match app.screen {
        Screen::AgentList => render_agent_list(f, app),
        Screen::AgentBuilder | Screen::Chat => render_chat(f, app),
    }
}

fn render_agent_list(f: &mut ratatui::Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(1),
            Constraint::Length(3),
        ])
        .split(f.size());

    // Header
    let header = Paragraph::new("Agent Builder - Your Agents")
        .style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(header, chunks[0]);

    // Agent list
    let items: Vec<ListItem> = app
        .agents
        .iter()
        .map(|agent| {
            let content = format!("{} - {}", agent.name, agent.role);
            ListItem::new(content)
                .style(Style::default().fg(Color::White))
        })
        .collect();

    let list = List::new(items)
        .block(Block::default().borders(Borders::ALL).title("Agents"))
        .style(Style::default().fg(Color::White))
        .highlight_style(
            Style::default()
                .bg(Color::Blue)
                .add_modifier(Modifier::BOLD),
        );
    f.render_widget(list, chunks[1]);

    // Footer
    let help = Paragraph::new("n: New Agent | q: Quit | i: Enter edit mode")
        .style(Style::default().fg(Color::DarkGray))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(help, chunks[2]);
}

fn render_chat(f: &mut ratatui::Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(1),
            Constraint::Length(3),
        ])
        .split(f.size());

    // Header
    let title = if let Some(agent) = &app.current_agent {
        format!("Building Agent: {}", agent.name)
    } else {
        "Agent Builder".to_string()
    };
    let header = Paragraph::new(title)
        .style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(header, chunks[0]);

    // Messages
    let messages: Vec<Line> = app
        .messages
        .iter()
        .flat_map(|(role, content)| {
            let style = match role.as_str() {
                "user" => Style::default().fg(Color::Green),
                "assistant" => Style::default().fg(Color::Blue),
                _ => Style::default().fg(Color::Yellow),
            };
            
            let prefix = match role.as_str() {
                "user" => "You: ",
                "assistant" => "Assistant: ",
                _ => "System: ",
            };

            vec![
                Line::from(Span::styled(prefix, style.add_modifier(Modifier::BOLD))),
                Line::from(content.as_str()),
                Line::from(""),
            ]
        })
        .skip(app.scroll as usize)
        .collect();

    let messages_widget = Paragraph::new(messages)
        .block(Block::default().borders(Borders::ALL).title("Conversation"))
        .wrap(Wrap { trim: true });
    f.render_widget(messages_widget, chunks[1]);

    // Input
    let input_text = match app.input_mode {
        InputMode::Normal => "Press 'i' to start typing, 'l' for agent list, 'q' to quit",
        InputMode::Editing => "Ctrl+S: Save | Esc: Normal mode | Enter: Send",
    };

    let input = Paragraph::new(app.input.as_str())
        .style(match app.input_mode {
            InputMode::Normal => Style::default(),
            InputMode::Editing => Style::default().fg(Color::Yellow),
        })
        .block(Block::default().borders(Borders::ALL).title(input_text));
    f.render_widget(input, chunks[2]);

    // Set cursor position
    if let InputMode::Editing = app.input_mode {
        f.set_cursor(
            chunks[2].x + app.cursor_position as u16 + 1,
            chunks[2].y + 1,
        );
    }
}

fn process_input(input: &str, agent: &mut Option<Agent>) -> String {
    let agent = match agent {
        Some(a) => a,
        None => return "No agent being built. Press 'n' to start.".to_string(),
    };

    let input_lower = input.to_lowercase();

    // Parse different types of input
    if agent.name.is_empty() {
        agent.name = input.to_string();
        return format!("Great! '{}' it is. What role does this agent play?", input);
    }

    if agent.role.is_empty() {
        agent.role = input.to_string();
        return format!("Perfect. {} will be a {}. Describe what this agent does.", agent.name, agent.role);
    }

    if agent.description.is_empty() {
        agent.description = input.to_string();
        return "Got it. What tools does this agent have access to? (e.g., 'file_read, web_search, execute_code')".to_string();
    }

    if agent.tools.is_empty() {
        agent.tools = input.split(',').map(|s| s.trim().to_string()).collect();
        return format!("Tools added: {}. What can this agent access? (e.g., '/home/user/data, /var/logs').", agent.tools.join(", "));
    }

    if agent.access.is_empty() {
        agent.access = input.split(',').map(|s| s.trim().to_string()).collect();
        return format!("Access granted: {}. Any constraints? (e.g., 'read-only, no network, max 1GB memory')", agent.access.join(", "));
    }

    if agent.constraints.is_empty() {
        agent.constraints = input.split(',').map(|s| s.trim().to_string()).collect();
        
        // Generate system prompt
        agent.system_prompt = generate_system_prompt(agent);
        
        return format!(
            "Agent complete!\n\nName: {}\nRole: {}\nDescription: {}\nTools: {}\nAccess: {}\nConstraints: {}\n\nPress Ctrl+S to save, or keep chatting to refine.",
            agent.name,
            agent.role,
            agent.description,
            agent.tools.join(", "),
            agent.access.join(", "),
            agent.constraints.join(", ")
        );
    }

    // After agent is complete, allow refinement
    if input_lower.contains("add tool") || input_lower.contains("tool:") {
        let tool = input.replace("add tool", "").replace("tool:", "").trim().to_string();
        agent.tools.push(tool.clone());
        return format!("Added tool: {}", tool);
    }

    if input_lower.contains("add access") || input_lower.contains("access:") {
        let access = input.replace("add access", "").replace("access:", "").trim().to_string();
        agent.access.push(access.clone());
        return format!("Added access: {}", access);
    }

    if input_lower.contains("add constraint") || input_lower.contains("constraint:") {
        let constraint = input.replace("add constraint", "").replace("constraint:", "").trim().to_string();
        agent.constraints.push(constraint.clone());
        return format!("Added constraint: {}", constraint);
    }

    "Agent is complete. Use 'add tool:', 'add access:', or 'add constraint:' to refine. Press Ctrl+S to save.".to_string()
}

fn generate_system_prompt(agent: &Agent) -> String {
    format!(
        r#"You are {}, a {}.

{}

You have access to the following tools:
{}

You can access:
{}

Constraints:
{}

Always follow these constraints and only use the tools and access you've been given."#,
        agent.name,
        agent.role,
        agent.description,
        agent.tools.iter().map(|t| format!("- {}", t)).collect::<Vec<_>>().join("\n"),
        agent.access.iter().map(|a| format!("- {}", a)).collect::<Vec<_>>().join("\n"),
        agent.constraints.iter().map(|c| format!("- {}", c)).collect::<Vec<_>>().join("\n")
    )
}

fn save_agent(agent: &Agent) {
    let agents_dir = std::path::Path::new("./agents");
    std::fs::create_dir_all(agents_dir).unwrap();
    
    let agent_file = agents_dir.join(format!("{}.json", agent.name.to_lowercase().replace(" ", "_")));
    let json = serde_json::to_string_pretty(agent).unwrap();
    std::fs::write(agent_file, json).unwrap();
}

fn load_agents() -> Vec<Agent> {
    let agents_dir = std::path::Path::new("./agents");
    if !agents_dir.exists() {
        return vec![];
    }

    std::fs::read_dir(agents_dir)
        .unwrap()
        .filter_map(|entry| {
            let entry = entry.ok()?;
            let path = entry.path();
            if path.extension()? == "json" {
                let content = std::fs::read_to_string(path).ok()?;
                serde_json::from_str(&content).ok()
            } else {
                None
            }
        })
        .collect()
}
