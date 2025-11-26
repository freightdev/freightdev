# FreightDev Repository

**A systems engineering reference library built through intensive study of infrastructure, distributed systems, and production architecture patterns.**

This repository contains design patterns, reference implementations, and experimental infrastructure concepts developed while mastering systems engineering from first principles.

## What's Inside

### Infrastructure & Orchestration
- **Distributed AI Systems:** Multi-node Ollama orchestration, agent coordination, memory management
- **Custom Development Tooling:** Scaffolding systems, environment managers, deployment automation
- **Security Architecture:** GPG/SSH management, encryption patterns, secrets handling
- **Container Orchestration:** Docker configurations, service management, networking patterns

### Domain-Specific Applications
- **ai-agency:** Distributed AI orchestration for lead generation and business automation (active development)
- **openhwy:** Trucking industry AI platform with specialized agent architecture
- **zbox-environment:** Agent environment with PostgreSQL memory system and ZSH orchestration
- **bookmark-studio:** Custom knowledge management system architecture (design phase)

### Microservices & APIs
- **Authentication Service:** User auth, session management, security patterns (Go)
- **Payment Service:** Transaction processing, webhook handling (Go)
- **Email Service:** Template rendering, delivery management (Go)
- **User Service:** Profile management, CRUD operations (Go)

### Reference Documentation
Extensive documentation covering:
- Database design (DuckDB, SurrealDB, PostgreSQL, vectorization)
- Programming languages (Rust internals, Go patterns, Python, TypeScript)
- Security practices (encryption, backups, sandboxing, GPG workflows)
- System architecture (distributed systems, microservices, orchestration)
- Development environments (ZSH configuration, shell optimization, tooling)

## Purpose & Approach

These projects serve as a **personal knowledge base** - each built to understand specific concepts at a deep level:

**Learning Method:**
- Build systems from scratch to understand fundamentals
- Intentionally break and rebuild to learn failure modes
- Document patterns and architectures for future reference
- Work in terminal, avoid GUIs, master underlying systems

**Current Status:**
Most projects are **reference implementations** or **partially complete learning vehicles**. They demonstrate understanding of concepts and serve as patterns for production work. The codebase is a goldmine of tested approaches, reusable components, and architectural patterns.

**Active Development:**
- `ai-agency` - Near production-ready, operational on 4-node distributed system
- Windmill workflow integration for business automation
- Infrastructure consulting for trucking/logistics industry

## Technical Foundation

**Systems:** Linux (Arch, Debian, Rocky), NixOS exploration, custom kernel compilation  
**Languages:** Rust, Go, Python, TypeScript, Dart/Flutter, Lua  
**Infrastructure:** Docker, PostgreSQL, SurrealDB, Redis, Nginx, Caddy  
**AI/ML:** Ollama, OpenVINO, distributed model orchestration  
**Security:** GPG, SSH, encryption, secure secrets management

## Background

Built by a systems engineer with 10 years of trucking operations experience, now specializing in infrastructure and custom software for the logistics industry. Deep understanding of both domain operations and technical implementation.

---

## Usage Notes

This is a **reference repository** for studying system design patterns and architectural approaches. Components can be adapted for production use but would require proper testing, hardening, and validation for specific use cases.

**Philosophy:** Understand every layer before building production systems. These projects represent that understanding.

---

☕ **Grab a coffee and explore the architecture**

Take your time diving into the patterns, designs, and implementations. Each project teaches something specific about building robust systems.

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-%23FFDD00.svg?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/freightdev)

---

## License

All code and documentation in this repository is provided as-is for educational and reference purposes. Use, adapt, and learn from it freely - just understand what you're working with before deploying to production.
