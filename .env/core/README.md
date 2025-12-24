# zBoxxy - The zBox Agent

## Overview
**zBoxxy** is the intelligent routing and resource management agent for zBox. While zBox handles the scripting and environment scaffolding, zBoxxy acts as the router and orchestrator for resources, agents, and isolation layers.

## Architecture

```
┌─────────────────────────────────────────┐
│             zBoxxy Agent                │
│  (Resource Router & Orchestrator)       │
├─────────────────────────────────────────┤
│  • Profile Management                   │
│  • Resource Routing                     │
│  • Isolation Layer Control              │
│  • Agent Communication                  │
│  • Manifest Processing                  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│              zBox Core                  │
│  (Environment & Scripting Engine)       │
├─────────────────────────────────────────┤
│  • Shell Environment Loading            │
│  • Function Libraries                   │
│  • Config Management                    │
│  • Tool Integration                     │
└─────────────────────────────────────────┘
```

## Responsibilities

### zBoxxy (Router/Orchestrator)
- **Profile Routing**: Determine which profile to load based on context
- **Resource Allocation**: Route resources to correct agents/profiles
- **Isolation Management**: Enforce sandbox boundaries
- **Agent Communication**: Facilitate inter-agent messaging
- **Manifest Interpretation**: Parse and execute manifest instructions

### zBox (Environment/Scripting)
- **Environment Setup**: Load shell environment, functions, configs
- **Script Execution**: Run zsh scripts and tools
- **Function Libraries**: Provide helper functions
- **Tool Integration**: Make tools available to agents

## Directory Structure

```
~/.zbox/.ai/agents/zboxxy/
├── README.md              # This file
├── config/                # zBoxxy configuration
│   ├── router.yaml       # Routing rules
│   ├── isolation.yaml    # Isolation policies
│   └── agents.yaml       # Agent registry
├── logs/                  # Agent logs
├── scripts/               # zBoxxy scripts
│   ├── router.zsh        # Resource routing logic
│   └── isolate.zsh       # Isolation enforcement
├── prompts/               # AI agent prompts
│   └── system.md         # System prompt for zBoxxy
└── TODO.md               # Development tasks

## Usage

### Start zBoxxy
```bash
zboxxy start
```

### Route to Profile
```bash
zboxxy route --profile workspace --agent claude
```

### Check Isolation
```bash
zboxxy check-isolation --agent <agent-name>
```

### List Active Agents
```bash
zboxxy list-agents
```

## Development Status

**Version**: 0.1.0-alpha
**Status**: Foundation - Basic structure created
**Next Steps**:
1. Implement routing logic
2. Build isolation enforcement
3. Create agent communication protocol
4. Develop manifest processor
5. Build TUI interface (Rust)

## Author
Jesse E.E.W. Conley
**Project**: zBox/zBoxxy Environment System
**Started**: 2024 (1 year+ development)
**Milestone**: Foundation Complete - November 2025
