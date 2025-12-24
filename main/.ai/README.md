# CoDriver

**Autonomous AI Agent System for Workflow Orchestration**

CoDriver is a self-directing AI coordinator that can use tools, make decisions, and orchestrate other agents. Built with Rust and powered by local LLM inference via llama.cpp, it provides a robust foundation for autonomous task execution with safety checks and state persistence.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Project Structure](#project-structure)
- [Components](#components)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development](#development)
- [License](#license)

---

## Overview

CoDriver is designed to be an autonomous coordinator that:
- Executes tasks using multiple specialized tools (Bash, file operations, web search)
- Orchestrates communication between multiple AI agents
- Maintains persistent state using SurrealDB
- Provides health monitoring and automatic recovery
- Supports multiple LLM backends (Anthropic, OpenAI, local models)

### Key Statistics
- **Components**: 4 main modules (coordinator, api-gateway, controllers, ai-wheeler)
- **Microservices**: 27 specialized services with trucking-themed names
- **Total Files**: 53,426+
- **Language**: Rust (2021 edition)
- **Database**: SurrealDB

---

## Architecture

### Multi-Agent System

```
┌─────────────────────────────────────────────────────────────┐
│                      CoDriver Coordinator                    │
│         (Primary Decision Maker & Orchestrator)              │
│         - Task decomposition                                 │
│         - Quality control                                    │
│         - Agent orchestration                                │
└──────────────┬──────────────────────────────────────────────┘
               │
               ├──> Code Assistant (qwen2.5-coder:32b @ helpbox)
               ├──> Prompt Manager (Rust service)
               ├──> Vision Controller (OpenVINO @ workbox)
               └──> 27 AI Wheeler Microservices
```

### Network Topology

- **Coordinator Node**: 192.168.12.106 (workbox)
- **Assistant Node**: 192.168.12.66 (helpbox)
- **Database Host**: 192.168.12.66 (helpbox)
- **Vision Node**: 192.168.12.136 (workbox)

### Infrastructure

- **Namespace**: openhwy
- **Database**: codriver_agency
- **LLM Engine**: llama.cpp (localhost:11435)
- **Communication**: HTTP + gRPC protocols

---

## Features

### Core Capabilities
✓ Autonomous task execution with LLM decision-making
✓ Bash command execution with safety checks
✓ File read/write/edit operations
✓ Web search integration
✓ Multi-agent orchestration
✓ Persistent state management via SurrealDB
✓ Health monitoring and auto-restart
✓ Email notification system
✓ Approval workflows for sensitive operations

### LLM Backend Support
- **Anthropic API** (via AnthropicCoordinator)
- **OpenAI API** (via OpenAICoordinator)
- **Local Models** (via LocalCoordinator + llama.cpp/Ollama)

---

## Project Structure

```
codriver/
├── src/
│   ├── coordinator/          # Main autonomous agent
│   ├── api-gateway/          # External API gateway
│   ├── controller/           # LLM and prompt controllers
│   │   ├── llama-controller/
│   │   ├── ollama-controller/
│   │   └── prompt-controller/
│   └── ai-wheeler/           # 27 specialized microservices
│       ├── auto_assist/
│       ├── big_bear/
│       ├── cargo_connect/
│       └── ...
├── .codriver.d/              # Runtime and configuration
│   ├── bin/                  # Executables
│   ├── etc/                  # Configuration files
│   │   └── agentd/
│   │       ├── agents.yaml
│   │       ├── database.yaml
│   │       └── persistence.yaml
│   ├── var/                  # Runtime data
│   │   ├── data/             # SurrealDB database files
│   │   ├── logs/             # Application logs
│   │   ├── runtime/          # PID files & type definitions
│   │   └── state/            # State snapshots
│   ├── srv/                  # Services
│   │   ├── agent.todo/       # Agent services & scripts
│   │   ├── auth.todo/
│   │   ├── docker.todo/
│   │   ├── email.todo/
│   │   ├── payment.todo/
│   │   └── user.todo/
│   └── opt/                  # Optional software
│       ├── llama.cpp/
│       ├── neovim/
│       └── surrealdb/
└── commands/                 # Custom commands
    └── command-template.md
```

---

## Components

### 1. Coordinator (`src/coordinator/`)

The brain of CoDriver - an autonomous agent that:
- Makes LLM-powered decisions
- Executes tools (Bash, file ops, web search)
- Orchestrates other agents
- Maintains conversation context

**Tech Stack:**
- Axum (HTTP framework)
- Tonic (gRPC framework)
- Tokio (async runtime)
- Reqwest (HTTP client)

**Key Files:**
- `src/main.rs` - Entry point
- `src/lib.rs` - LLM backend abstraction
- `src/agent.rs` - Autonomous agent implementation
- `src/tools.rs` - Tool implementations
- `src/system.rs` - System utilities

### 2. API Gateway (`src/api-gateway/`)

Handles external communication and request routing.

### 3. Controllers (`src/controller/`)

**llama-controller**: Manages llama.cpp model inference
**ollama-controller**: Integrates with Ollama
**prompt-controller**: Secure prompt management (port 9001)

### 4. AI Wheeler (`src/ai-wheeler/`)

27 specialized microservices with trucking-themed names:

**Operations**: auto_assist, big_bear, cargo_connect, diesel_driver
**Monitoring**: error_echo, iron_insight, radar_reach
**Security**: ghost_guard, jackknife_jailer, key_keeper, secret_safe
**Utilities**: fuel_factor, highway_helper, legal_logger, memory_mark
**Networking**: night_nexus, packet_pilot, voice_validator
**Data**: oversize_overseer, quick_quote, trucker_tales, unit_usage
**Services**: whisper_witness, xeno_xeno, yes_yes, zone_zipper

---

## Installation

### Prerequisites

- Rust 2021 edition or later
- SurrealDB
- llama.cpp or Ollama (for local inference)
- Docker (optional, for containerized services)

### Build from Source

```bash
# Clone the repository
cd ~/WORKSPACE/projects/ACTIVE/codriver

# Build coordinator
cd src/coordinator
cargo build --release

# Build API gateway
cd ../api-gateway
cargo build --release

# Build controllers
cd ../controller/prompt-controller
cargo build --release
```

### Database Setup

```bash
# Configure SurrealDB connection
# Edit: .codriver.d/etc/agentd/database.yaml

# Initialize database
surreal sql < .codriver.d/etc/agentd/init-db.surql
```

---

## Configuration

### Agent Configuration

Edit `.codriver.d/etc/agentd/agents.yaml`:

```yaml
coordinator:
  name: "CoDriver"
  model: "your-model-name"
  node: "192.168.12.106"
  capabilities:
    - task_decomposition
    - quality_control
    - complex_reasoning
```

### Database Configuration

Edit `.codriver.d/etc/agentd/database.yaml`:

```yaml
connection:
  host: "192.168.12.66"
  port: "8000"
  protocol: "http"

auth:
  namespace: "openhwy"
  database: "codriver_agency"
  username: "codriver"
```

### Email Notifications

Edit `src/coordinator/.env.example` and rename to `.env`:

```bash
USER_EMAIL=admin@open-hwy.com
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

---

## Usage

### Start the Coordinator

```bash
cd ~/WORKSPACE/projects/ACTIVE/codriver/src/coordinator
cargo run --release "Your objective here"
```

**Example:**
```bash
cargo run --release "Monitor and improve the system"
```

### State Management Scripts

Located in `.codriver.d/srv/agent.todo/src/scripts/`:

**Test Database Connection:**
```bash
./test-db.sh
```

**Restore Last State:**
```bash
./state-restore.sh
```

**Manual State Sync:**
```bash
./state-sync.sh
```

**Setup Auto-Sync (systemd):**
```bash
./setup-auto-sync.sh
```

### Check Running Services

```bash
# View PID files
ls .codriver.d/var/runtime/pids/

# Check state
cat .codriver.d/var/state/current.json
cat .codriver.d/var/state/health.json
```

---

## Development

### Adding a New Tool

Edit `src/coordinator/src/tools.rs`:

```rust
pub async fn your_new_tool(params: ToolParams) -> Result<String> {
    // Implementation
}
```

### Adding a New Agent

1. Create config in `.codriver.d/etc/agentd/agents.yaml`
2. Implement communication in `src/coordinator/src/agent.rs`
3. Add to coordinator's available resources

### Running Tests

```bash
cargo test
```

### Code Style

- Follow Rust 2021 edition conventions
- Use `cargo fmt` for formatting
- Use `cargo clippy` for linting

---

## Technology Stack

**Language**: Rust (2021 edition)
**Async Runtime**: Tokio
**Web Framework**: Axum (HTTP), Tonic (gRPC)
**Database**: SurrealDB
**LLM Engine**: llama.cpp / Ollama
**Serialization**: Serde
**Logging**: Tracing

---

## Running Services

Currently active services (based on PID files):

- api-gateway
- code-assistant
- command-coordinator
- coordinator
- data-collector
- file-ops
- messaging-service
- openvino-vision
- pdf-service
- screen-controller
- service-manager
- trading-agent
- vision-controller
- web-scraper
- web-search

---

## Health Monitoring

- **Health Check Interval**: 300 seconds (5 minutes)
- **Auto-Restart**: Enabled
- **Max Restart Attempts**: 3
- **Restart Delay**: 10 seconds

---

## State Persistence

**Snapshot Schedule:**
- High Priority: Every 5 minutes
- Medium Priority: Every 15 minutes
- Low Priority: Every hour

**Retention Policy:**
- Snapshots: 30 days
- Logs: 90 days
- Compression: After 7 days

---

## Communication Protocols

- **HTTP**: RESTful APIs
- **gRPC**: Inter-agent communication
- **Timeout**: 30 seconds
- **Retry Attempts**: 3
- **Retry Delay**: 1000ms

---

## Resource Limits

**Coordinator:**
- Max Memory: 24 GB
- Max Context Tokens: 32,768
- Threads: 20

**Assistant:**
- Max Memory: 32 GB
- Max Context Tokens: 32,768
- Threads: 8

---

## Contributing

This is an internal project for OpenHWY. Follow the standard Rust development practices and ensure all tests pass before committing.

---

## License

Internal use only - OpenHWY

---

## Support

For issues or questions, contact the development team at agency@openhwy.local

---

**Last Updated**: 2025-11-09
**Version**: 0.1.0
**Status**: Active Development
