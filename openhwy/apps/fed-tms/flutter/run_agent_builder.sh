#!/bin/bash
# Setup and run agent builder

echo "🤖 Agent Builder Setup"

# Create project structure
mkdir -p agent-builder/src
mkdir -p agent-builder/agents

# Copy files
cp agent-builder-main.rs agent-builder/src/main.rs
cp Cargo.toml agent-builder/

cd agent-builder

# Build
echo "📦 Building..."
cargo build --release

# Run
echo "🚀 Starting Agent Builder..."
echo ""
echo "CONTROLS:"
echo "  n - New agent"
echo "  l - List agents"
echo "  i - Start typing"
echo "  Esc - Exit typing mode"
echo "  Ctrl+S - Save agent (when in typing mode)"
echo "  q - Quit (when not typing)"
echo ""
cargo run --release
