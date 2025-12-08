// File: marketeer-dashboard/src/main.rs
// Marketeer Dashboard - Monitor and control all systems

use crossterm::{
    event::{self, Event, KeyCode, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{
        Block, Borders, List, ListItem, ListState, Paragraph, Gauge, Table, Row, Cell,
    },
    Frame, Terminal,
};
use serde::{Deserialize, Serialize};
use std::io;
use std::process::Command;
use std::time::{Duration, Instant};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct System {
    name: String,
    hostname: String,
    status: SystemStatus,
    cpu_usage: f32,
    memory_usage: f32,
    memory_total: String,
    agents: Vec<Agent>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Agent {
    name: String,
    status: AgentStatus,
    cpu: f32,
    memory: String,
    uptime: String,
    pid: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
enum SystemStatus {
    Online,
    Offline,
    Degraded,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
enum AgentStatus {
    Running,
    Stopped,
    Error,
}

#[derive(Debug, Clone, PartialEq)]
enum Panel {
    Systems,
    Agents,
    Logs,
    Actions,
}

struct App {
    systems: Vec<System>,
    selected_panel: Panel,
    selected_system: usize,
    selected_agent: usize,
    logs: Vec<String>,
    last_update: Instant,
    list_state_systems: ListState,
    list_state_agents: ListState,
}

impl Default for App {
    fn default() -> App {
        let mut app = App {
            systems: vec![],
            selected_panel: Panel::Systems,
            selected_system: 0,
            selected_agent: 0,
            logs: vec![
                "Dashboard started".to_string(),
                "Scanning systems...".to_string(),
            ],
            last_update: Instant::now(),
            list_state_systems: ListState::default(),
            list_state_agents: ListState::default(),
        };
        
        // Initialize systems
        app.systems = discover_systems();
        app.list_state_systems.select(Some(0));
        app.list_state_agents.select(Some(0));
        
        app
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

        // Auto-refresh every 2 seconds
        if app.last_update.elapsed() >= Duration::from_secs(2) {
            refresh_systems(app);
            app.last_update = Instant::now();
        }

        // Handle input (non-blocking)
        if event::poll(Duration::from_millis(100))? {
            if let Event::Key(key) = event::read()? {
                match key.code {
                    KeyCode::Char('q') => return Ok(()),
                    KeyCode::Tab => {
                        app.selected_panel = match app.selected_panel {
                            Panel::Systems => Panel::Agents,
                            Panel::Agents => Panel::Logs,
                            Panel::Logs => Panel::Actions,
                            Panel::Actions => Panel::Systems,
                        };
                    }
                    KeyCode::Up => {
                        match app.selected_panel {
                            Panel::Systems => {
                                if app.selected_system > 0 {
                                    app.selected_system -= 1;
                                    app.list_state_systems.select(Some(app.selected_system));
                                }
                            }
                            Panel::Agents => {
                                if app.selected_agent > 0 {
                                    app.selected_agent -= 1;
                                    app.list_state_agents.select(Some(app.selected_agent));
                                }
                            }
                            _ => {}
                        }
                    }
                    KeyCode::Down => {
                        match app.selected_panel {
                            Panel::Systems => {
                                if app.selected_system < app.systems.len() - 1 {
                                    app.selected_system += 1;
                                    app.list_state_systems.select(Some(app.selected_system));
                                }
                            }
                            Panel::Agents => {
                                let agent_count = app.systems.get(app.selected_system)
                                    .map(|s| s.agents.len())
                                    .unwrap_or(0);
                                if app.selected_agent < agent_count.saturating_sub(1) {
                                    app.selected_agent += 1;
                                    app.list_state_agents.select(Some(app.selected_agent));
                                }
                            }
                            _ => {}
                        }
                    }
                    KeyCode::Enter => {
                        match app.selected_panel {
                            Panel::Actions => {
                                // Execute action
                            }
                            _ => {}
                        }
                    }
                    KeyCode::Char('r') => {
                        refresh_systems(app);
                        app.logs.push("Manual refresh triggered".to_string());
                    }
                    KeyCode::Char('s') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                        // SSH into selected system
                        if let Some(system) = app.systems.get(app.selected_system) {
                            ssh_to_system(&system.hostname);
                        }
                    }
                    KeyCode::Char('k') => {
                        // Kill selected agent
                        kill_agent(app);
                    }
                    KeyCode::Char('l') => {
                        // Launch agent
                        launch_agent(app);
                    }
                    _ => {}
                }
            }
        }
    }
}

fn ui(f: &mut Frame, app: &mut App) {
    let size = f.size();

    // Main layout
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),     // Header
            Constraint::Min(0),        // Main content
            Constraint::Length(3),     // Footer
        ])
        .split(size);

    // Header
    render_header(f, chunks[0]);

    // Main content layout
    let main_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(30), // Systems list
            Constraint::Percentage(40), // Agents list
            Constraint::Percentage(30), // Logs/Actions
        ])
        .split(chunks[1]);

    // Render panels
    render_systems(f, main_chunks[0], app);
    render_agents(f, main_chunks[1], app);
    
    let right_chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage(60), // Logs
            Constraint::Percentage(40), // Actions
        ])
        .split(main_chunks[2]);
    
    render_logs(f, right_chunks[0], app);
    render_actions(f, right_chunks[1], app);

    // Footer
    render_footer(f, chunks[2]);
}

fn render_header(f: &mut Frame, area: Rect) {
    let title = Paragraph::new("🚛 MARKETEER DASHBOARD - OpenHWY Infrastructure Control")
        .style(
            Style::default()
                .fg(Color::Cyan)
                .add_modifier(Modifier::BOLD),
        )
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(title, area);
}

fn render_systems(f: &mut Frame, area: Rect, app: &mut App) {
    let is_selected = app.selected_panel == Panel::Systems;
    
    let items: Vec<ListItem> = app
        .systems
        .iter()
        .map(|system| {
            let status_icon = match system.status {
                SystemStatus::Online => "🟢",
                SystemStatus::Offline => "🔴",
                SystemStatus::Degraded => "🟡",
            };
            
            let content = vec![
                Line::from(vec![
                    Span::raw(status_icon),
                    Span::raw(" "),
                    Span::styled(&system.name, Style::default().add_modifier(Modifier::BOLD)),
                ]),
                Line::from(vec![
                    Span::raw("  CPU: "),
                    Span::styled(
                        format!("{:.1}%", system.cpu_usage),
                        if system.cpu_usage > 80.0 {
                            Style::default().fg(Color::Red)
                        } else {
                            Style::default().fg(Color::Green)
                        },
                    ),
                    Span::raw(" | MEM: "),
                    Span::styled(
                        format!("{:.1}%", system.memory_usage),
                        if system.memory_usage > 80.0 {
                            Style::default().fg(Color::Red)
                        } else {
                            Style::default().fg(Color::Green)
                        },
                    ),
                ]),
                Line::from(format!("  Agents: {}", system.agents.len())),
            ];
            
            ListItem::new(content).style(Style::default().fg(Color::White))
        })
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Systems")
                .border_style(if is_selected {
                    Style::default().fg(Color::Yellow)
                } else {
                    Style::default()
                }),
        )
        .highlight_style(
            Style::default()
                .bg(Color::Blue)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol(">> ");

    f.render_stateful_widget(list, area, &mut app.list_state_systems);
}

fn render_agents(f: &mut Frame, area: Rect, app: &mut App) {
    let is_selected = app.selected_panel == Panel::Agents;
    
    let agents = app.systems.get(app.selected_system)
        .map(|s| &s.agents)
        .unwrap_or(&vec![]);

    let items: Vec<ListItem> = agents
        .iter()
        .map(|agent| {
            let status_icon = match agent.status {
                AgentStatus::Running => "🟢",
                AgentStatus::Stopped => "⚫",
                AgentStatus::Error => "🔴",
            };
            
            let content = vec![
                Line::from(vec![
                    Span::raw(status_icon),
                    Span::raw(" "),
                    Span::styled(&agent.name, Style::default().add_modifier(Modifier::BOLD)),
                ]),
                Line::from(vec![
                    Span::raw("  CPU: "),
                    Span::styled(format!("{:.1}%", agent.cpu), Style::default().fg(Color::Green)),
                    Span::raw(" | MEM: "),
                    Span::raw(&agent.memory),
                ]),
                Line::from(format!("  Uptime: {}", agent.uptime)),
            ];
            
            ListItem::new(content).style(Style::default().fg(Color::White))
        })
        .collect();

    let system_name = app.systems.get(app.selected_system)
        .map(|s| s.name.as_str())
        .unwrap_or("Unknown");

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(format!("Agents on {}", system_name))
                .border_style(if is_selected {
                    Style::default().fg(Color::Yellow)
                } else {
                    Style::default()
                }),
        )
        .highlight_style(
            Style::default()
                .bg(Color::Blue)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol(">> ");

    f.render_stateful_widget(list, area, &mut app.list_state_agents);
}

fn render_logs(f: &mut Frame, area: Rect, app: &App) {
    let is_selected = app.selected_panel == Panel::Logs;
    
    let logs: Vec<Line> = app
        .logs
        .iter()
        .rev()
        .take(20)
        .map(|log| Line::from(log.as_str()))
        .collect();

    let paragraph = Paragraph::new(logs)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Logs")
                .border_style(if is_selected {
                    Style::default().fg(Color::Yellow)
                } else {
                    Style::default()
                }),
        )
        .style(Style::default().fg(Color::Gray));

    f.render_widget(paragraph, area);
}

fn render_actions(f: &mut Frame, area: Rect, app: &App) {
    let is_selected = app.selected_panel == Panel::Actions;
    
    let actions = vec![
        "l - Launch Agent",
        "k - Kill Agent",
        "r - Refresh",
        "Ctrl+S - SSH to System",
        "Tab - Next Panel",
        "q - Quit",
    ];

    let items: Vec<ListItem> = actions
        .iter()
        .map(|action| ListItem::new(*action))
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Actions")
                .border_style(if is_selected {
                    Style::default().fg(Color::Yellow)
                } else {
                    Style::default()
                }),
        );

    f.render_widget(list, area);
}

fn render_footer(f: &mut Frame, area: Rect) {
    let footer = Paragraph::new("Tab: Switch Panel | ↑↓: Navigate | Enter: Execute | q: Quit")
        .style(Style::default().fg(Color::DarkGray))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(footer, area);
}

fn discover_systems() -> Vec<System> {
    vec![
        System {
            name: "workbox".to_string(),
            hostname: "workbox".to_string(),
            status: SystemStatus::Online,
            cpu_usage: 23.5,
            memory_usage: 45.2,
            memory_total: "16GB".to_string(),
            agents: vec![
                Agent {
                    name: "codriver".to_string(),
                    status: AgentStatus::Running,
                    cpu: 12.3,
                    memory: "256MB".to_string(),
                    uptime: "2h 34m".to_string(),
                    pid: Some(1234),
                },
                Agent {
                    name: "scraper".to_string(),
                    status: AgentStatus::Running,
                    cpu: 5.1,
                    memory: "128MB".to_string(),
                    uptime: "1h 12m".to_string(),
                    pid: Some(1235),
                },
            ],
        },
        System {
            name: "laptop1".to_string(),
            hostname: "192.168.1.101".to_string(),
            status: SystemStatus::Online,
            cpu_usage: 15.2,
            memory_usage: 32.1,
            memory_total: "8GB".to_string(),
            agents: vec![
                Agent {
                    name: "watcher".to_string(),
                    status: AgentStatus::Running,
                    cpu: 3.2,
                    memory: "64MB".to_string(),
                    uptime: "3h 45m".to_string(),
                    pid: Some(2234),
                },
            ],
        },
        System {
            name: "laptop2".to_string(),
            hostname: "192.168.1.102".to_string(),
            status: SystemStatus::Online,
            cpu_usage: 8.7,
            memory_usage: 28.5,
            memory_total: "8GB".to_string(),
            agents: vec![],
        },
        System {
            name: "laptop3".to_string(),
            hostname: "192.168.1.103".to_string(),
            status: SystemStatus::Offline,
            cpu_usage: 0.0,
            memory_usage: 0.0,
            memory_total: "8GB".to_string(),
            agents: vec![],
        },
    ]
}

fn refresh_systems(app: &mut App) {
    // In real implementation, SSH to each system and get stats
    // For now, simulate with random changes
    use rand::Rng;
    let mut rng = rand::thread_rng();
    
    for system in &mut app.systems {
        if system.status == SystemStatus::Online {
            system.cpu_usage = rng.gen_range(10.0..50.0);
            system.memory_usage = rng.gen_range(20.0..60.0);
            
            for agent in &mut system.agents {
                if agent.status == AgentStatus::Running {
                    agent.cpu = rng.gen_range(2.0..15.0);
                }
            }
        }
    }
}

fn ssh_to_system(hostname: &str) {
    // This would need to properly handle dropping out of TUI mode
    let _ = Command::new("ssh")
        .arg(format!("admin@{}", hostname))
        .spawn();
}

fn kill_agent(app: &mut App) {
    if let Some(system) = app.systems.get_mut(app.selected_system) {
        if let Some(agent) = system.agents.get_mut(app.selected_agent) {
            agent.status = AgentStatus::Stopped;
            app.logs.push(format!("Stopped agent: {} on {}", agent.name, system.name));
        }
    }
}

fn launch_agent(app: &mut App) {
    // Would launch agent via SSH
    app.logs.push("Launch agent functionality TODO".to_string());
}
