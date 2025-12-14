#!/usr/bin/env bash
# llama-runner.sh - Complete Rust Llama Runner Project Setup
# Usage: ./llama-runner.sh [--gpu] [--force] [--dev]

set -euo pipefail

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="llama_runner"
LLAMA_CPP_REPO="https://github.com/ggerganov/llama.cpp.git"
RUST_TOOLCHAIN="stable"

# Parse command line arguments
ENABLE_GPU=false
FORCE_SETUP=false
DEV_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --gpu)
            ENABLE_GPU=true
            shift
            ;;
        --force)
            FORCE_SETUP=true
            shift
            ;;
        --dev)
            DEV_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--gpu] [--force] [--dev]"
            echo "  --gpu    Enable GPU acceleration detection"
            echo "  --force  Force complete rebuild"
            echo "  --dev    Setup development environment"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

log_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and architecture
detect_system() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $OS in
        linux*)   OS="linux" ;;
        darwin*)  OS="macos" ;;
        mingw*|msys*) OS="windows" ;;
        *) log_error "Unsupported OS: $OS" ;;
    esac
    
    case $ARCH in
        x86_64|amd64) ARCH="x86_64" ;;
        arm64|aarch64) ARCH="aarch64" ;;
        *) log_warn "Untested architecture: $ARCH" ;;
    esac
    
    log_info "Detected system: $OS-$ARCH"
}

# Install system dependencies
install_system_deps() {
    log_step "Installing system dependencies..."
    
    case $OS in
        linux)
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y \
                    build-essential \
                    cmake \
                    pkg-config \
                    libssl-dev \
                    git \
                    curl \
                    wget \
                    unzip
                
                if [[ $ENABLE_GPU == true ]]; then
                    log_info "Installing GPU development packages..."
                    sudo apt-get install -y \
                        nvidia-cuda-dev \
                        opencl-headers \
                        opencl-dev \
                        libvulkan-dev \
                        vulkan-tools || log_warn "Some GPU packages may not be available"
                fi
            elif command_exists yum; then
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y cmake pkgconfig openssl-devel git curl wget unzip
            elif command_exists pacman; then
                sudo pacman -S --needed base-devel cmake pkgconf openssl git curl wget unzip
            else
                log_warn "Unknown Linux package manager. Please install build tools manually."
            fi
            ;;
        macos)
            if ! command_exists brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install cmake pkg-config openssl git curl wget
            ;;
        windows)
            log_warn "Windows setup requires manual installation of Visual Studio Build Tools and CMake"
            ;;
    esac
    
    log_success "System dependencies installed"
}

# Install Rust
install_rust() {
    if ! command_exists rustc; then
        log_step "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUST_TOOLCHAIN
        source "$HOME/.cargo/env"
    else
        log_info "Rust already installed: $(rustc --version)"
    fi
    
    # Install additional components
    rustup component add clippy rustfmt
    
    # Install useful tools
    if [[ $DEV_MODE == true ]]; then
        log_step "Installing development tools..."
        cargo install --locked \
            cargo-edit \
            cargo-audit \
            cargo-outdated \
            cargo-watch \
            just || log_warn "Some tools may have failed to install"
    fi
    
    log_success "Rust toolchain ready"
}

# Create project structure
create_project_structure() {
    log_step "Creating project structure..."
    
    # Create all directories
    mkdir -p {
        .github/workflows,
        config,
        scripts,
        tests/{integration,fixtures,common},
        benches,
        examples,
        docs,
        src/{api/{routes,handlers,middleware,extractors,responses},bindings,core,loaders,prompts,runners,tokens,utils,models,errors}
    }
    
    # Create placeholder files to maintain directory structure
    touch src/{main,lib}.rs
    touch src/api/mod.rs
    touch src/{bindings,core,loaders,prompts,runners,tokens,utils,models,errors}/mod.rs
    
    log_success "Project structure created"
}

# Setup git and submodules
setup_git() {
    log_step "Setting up git repository..."
    
    if [[ ! -d .git ]]; then
        git init
        log_info "Git repository initialized"
    fi
    
    # Add llama.cpp as submodule
    if [[ ! -d llama.cpp ]]; then
        log_info "Adding llama.cpp submodule..."
        git submodule add $LLAMA_CPP_REPO llama.cpp
        git submodule update --init --recursive
    else
        log_info "Updating llama.cpp submodule..."
        git submodule update --remote --recursive
    fi
    
    log_success "Git setup complete"
}

# Create essential files
create_essential_files() {
    log_step "Creating essential project files..."
    
    # .gitignore
    cat > .gitignore << 'EOF'
# Rust
/target/
**/*.rs.bk
Cargo.lock

# Build artifacts
llama.cpp/build/
*.o
*.a
*.so
*.dylib
*.dll

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local

# Logs
*.log

# Generated bindings backup
src/bindings/llama_cpp.old.rs
EOF

    # Cargo.toml
    cat > Cargo.toml << EOF
[package]
name = "$PROJECT_NAME"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <your.email@example.com>"]
description = "High-performance Rust FFI wrapper for llama.cpp with HTTP API"
license = "MIT OR Apache-2.0"
repository = "https://github.com/yourusername/$PROJECT_NAME"
keywords = ["llama", "ai", "llm", "inference", "rust"]
categories = ["api-bindings", "web-programming::http-server"]

[features]
default = ["api-server"]
api-server = ["tokio", "axum", "tower", "tower-http"]
regen-bindings = []
cuda = []
metal = []
opencl = []
vulkan = []

[build-dependencies]
bindgen = "0.69"
num_cpus = "1.16"

[dependencies]
# Core async runtime
tokio = { version = "1.0", features = ["full"], optional = true }

# HTTP server (optional)
axum = { version = "0.7", optional = true }
tower = { version = "0.4", optional = true }
tower-http = { version = "0.5", features = ["cors", "trace"], optional = true }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Error handling
anyhow = "1.0"
thiserror = "1.0"

# Logging and tracing
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }

# Configuration
config = "0.14"
toml = "0.8"

# Utilities
uuid = { version = "1.0", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }

[dev-dependencies]
tokio-test = "0.4"
reqwest = { version = "0.11", features = ["json"] }
tempfile = "3.0"
criterion = "0.5"

[[bin]]
name = "$PROJECT_NAME"
path = "src/main.rs"
required-features = ["api-server"]

[[example]]
name = "simple_inference"
path = "examples/simple_inference.rs"

[[bench]]
name = "inference_benchmark"
harness = false
EOF

    # justfile
    cat > justfile << 'EOF'
# Development commands for llama_runner

# Default recipe
default: check

# Run all checks (format, lint, test)
check: fmt-check lint test

# Format code
fmt:
    cargo fmt

# Check formatting
fmt-check:
    cargo fmt --check

# Run clippy
lint:
    cargo clippy --all-targets --all-features -- -D warnings

# Run tests
test:
    cargo test --all-features

# Run benchmarks
bench:
    cargo bench

# Build release binary
build:
    cargo build --release

# Regenerate FFI bindings
regen-bindings:
    cargo build --features regen-bindings

# Clean everything including llama.cpp build
clean:
    cargo clean
    rm -rf llama.cpp/build
    rm -f src/bindings/llama_cpp.rs
    rm -f src/bindings/llama_cpp.old.rs

# Update llama.cpp submodule
update-llama:
    git submodule update --remote llama.cpp

# Run development server with hot reload
dev:
    cargo watch -x 'run --features api-server'

# Check security vulnerabilities
audit:
    cargo audit

# Update dependencies
update:
    cargo update

# Install development tools
install-tools:
    cargo install cargo-watch cargo-audit cargo-outdated
EOF

    # README.md
    cat > README.md << EOF
# $PROJECT_NAME

High-performance Rust FFI wrapper for llama.cpp with optional HTTP API server.

## Features

- 🚀 Zero-copy FFI bindings to llama.cpp
- 🔥 GPU acceleration (CUDA, Metal, OpenCL, Vulkan)
- 🌐 Optional HTTP API server
- ⚡ Async/await support
- 🛡️ Memory-safe abstractions
- 📦 Easy deployment with Docker

## Quick Start

\`\`\`bash
# Setup project
./setup-project.sh

# Build and run
just build
cargo run --features api-server
\`\`\`

## GPU Support

Enable GPU acceleration:

\`\`\`bash
# CUDA
LLAMA_ENABLE_CUDA=1 cargo build --features cuda

# Metal (macOS)
cargo build --features metal

# OpenCL
cargo build --features opencl
\`\`\`

## Development

Use \`just\` for common tasks:

- \`just check\` - Run all checks
- \`just test\` - Run tests
- \`just dev\` - Development server with hot reload
- \`just regen-bindings\` - Regenerate FFI bindings

## License

Licensed under either of Apache License, Version 2.0 or MIT license at your option.
EOF

    # wrapper.h
    cat > wrapper.h << 'EOF'
#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#include "llama.h"
#include "ggml.h"

// Additional wrapper functions can be added here

#endif // LLAMA_WRAPPER_H
EOF

    # .env.example
    cat > .env.example << 'EOF'
# Server configuration
HOST=127.0.0.1
PORT=8001

# Model configuration
MODEL_PATH=./models/model.gguf
CONTEXT_SIZE=2048
GPU_LAYERS=0

# Logging
RUST_LOG=info

# GPU acceleration (uncomment to enable)
# LLAMA_ENABLE_CUDA=1
# LLAMA_ENABLE_METAL=1
# LLAMA_ENABLE_OPENCL=1
EOF

    log_success "Essential files created"
}

# Create configuration files
create_config_files() {
    log_step "Creating configuration files..."
    
    # Default config
    cat > config/default.toml << 'EOF'
[server]
host = "127.0.0.1"
port = 8001
workers = 4

[model]
path = "./models/model.gguf"
context_size = 2048
gpu_layers = 0
batch_size = 512

[inference]
temperature = 0.7
top_p = 0.9
top_k = 40
repeat_penalty = 1.1
max_tokens = 1024

[logging]
level = "info"
format = "pretty"
EOF

    # Development config
    cat > config/development.toml << 'EOF'
[server]
host = "127.0.0.1"
port = 8001

[logging]
level = "debug"
format = "pretty"
EOF

    # Production config
    cat > config/production.toml << 'EOF'
[server]
host = "0.0.0.0"
port = 8001
workers = 8

[logging]
level = "info"
format = "json"
EOF

    log_success "Configuration files created"
}

# Create CI/CD workflows
create_workflows() {
    log_step "Creating GitHub workflows..."
    
    cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  CARGO_TERM_COLOR: always

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive
    
    - uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
        components: rustfmt, clippy
        override: true
    
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y build-essential cmake
    
    - name: Cache cargo registry
      uses: actions/cache@v3
      with:
        path: ~/.cargo/registry
        key: ${{ runner.os }}-cargo-registry-${{ hashFiles('**/Cargo.lock') }}
    
    - name: Check formatting
      run: cargo fmt --check
    
    - name: Run clippy
      run: cargo clippy --all-targets --all-features -- -D warnings
    
    - name: Run tests
      run: cargo test --all-features
    
    - name: Build release
      run: cargo build --release --all-features
EOF

    log_success "CI/CD workflows created"
}

# Create basic source files
create_source_files() {
    log_step "Creating basic source files..."
    
    # lib.rs
    cat > src/lib.rs << 'EOF'
//! Llama Runner - High-performance Rust FFI wrapper for llama.cpp
//! 
//! This crate provides safe Rust bindings to llama.cpp with optional HTTP API server.

pub mod bindings;
pub mod core;
pub mod errors;
pub mod loaders;
pub mod prompts;
pub mod runners;
pub mod tokens;
pub mod utils;

#[cfg(feature = "api-server")]
pub mod api;

pub use errors::{LlamaError, Result};
EOF

    # main.rs
    cat > src/main.rs << 'EOF'
//! Llama Runner CLI and API server

use anyhow::Result;
use tracing::info;

#[cfg(feature = "api-server")]
#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    info!("🚀 Starting Llama Runner API server...");
    
    // TODO: Initialize and start API server
    
    Ok(())
}

#[cfg(not(feature = "api-server"))]
fn main() -> Result<()> {
    println!("Llama Runner CLI - Coming soon!");
    println!("Enable 'api-server' feature to run the HTTP server.");
    Ok(())
}
EOF

    # errors/mod.rs
    cat > src/errors/mod.rs << 'EOF'
//! Error types for Llama Runner

use thiserror::Error;

pub type Result<T> = std::result::Result<T, LlamaError>;

#[derive(Error, Debug)]
pub enum LlamaError {
    #[error("Model loading error: {0}")]
    ModelLoad(String),
    
    #[error("Inference error: {0}")]
    Inference(String),
    
    #[error("FFI error: {0}")]
    Ffi(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Configuration error: {0}")]
    Config(String),
}
EOF

    log_success "Basic source files created"
}

# Final setup and validation
final_setup() {
    log_step "Running final setup..."
    
    # Initialize git if not done
    if [[ ! -d .git ]]; then
        git init
        git add .
        git commit -m "Initial project setup"
    fi
    
    # Test basic build
    log_info "Testing basic build..."
    if cargo check; then
        log_success "Basic build successful"
    else
        log_warn "Build check failed - this is expected for initial setup"
    fi
    
    # Create models directory
    mkdir -p models
    echo "# Place your .gguf model files here" > models/README.md
    
    log_success "Final setup complete"
}

# Print setup summary
print_summary() {
    echo -e "${GREEN}"
    echo "🎉 Llama Runner project setup complete!"
    echo "======================================"
    echo -e "${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Place a .gguf model file in the models/ directory"
    echo "2. Copy .env.example to .env and configure"
    echo "3. Run: just regen-bindings"
    echo "4. Run: just build"
    echo "5. Run: cargo run --features api-server"
    echo ""
    echo -e "${CYAN}Development workflow:${NC}"
    echo "• just check    - Run all checks"
    echo "• just test     - Run tests"
    echo "• just dev      - Development server"
    echo "• just bench    - Run benchmarks"
    echo ""
    echo -e "${CYAN}GPU acceleration:${NC}"
    if [[ $ENABLE_GPU == true ]]; then
        echo "• GPU support enabled"
        echo "• Set LLAMA_ENABLE_CUDA=1 for CUDA"
        echo "• Use --features cuda,metal,opencl as needed"
    else
        echo "• Run with --gpu flag to enable GPU detection"
    fi
    echo ""
    echo -e "${YELLOW}⚠️  Don't forget to add a model file to models/ directory!${NC}"
}

# Main execution
main() {
    echo -e "${PURPLE}"
    echo "🦙 Llama Runner Project Setup"
    echo "============================"
    echo -e "${NC}"
    
    detect_system
    install_system_deps
    install_rust
    create_project_structure
    setup_git
    create_essential_files
    create_config_files
    create_workflows
    create_source_files
    final_setup
    print_summary
    
    log_success "🎉 Setup complete! Your Rust Llama Runner is ready to build."
}

# Run main function
main "$@"
