#!/bin/bash
# Setup Moon Environment

echo "🌙 Setting up Moon Environment..."

# Create project
mkdir -p moon-env/src
mkdir -p moon-env/agents
mkdir -p moon-env/configs

# Copy files
cp moon-env-main.rs moon-env/src/main.rs
cp moon-env-cargo.toml moon-env/Cargo.toml
cp moon.toml moon-env/moon.toml
cp agent_script.lua moon-env/agents/codriver.lua

cd moon-env

# Build
echo "📦 Building Moon Environment..."
cargo build --release

echo "✅ Moon Environment ready!"
echo ""
echo "USAGE:"
echo "  ./target/release/moon-env                    # Interactive mode"
echo "  ./target/release/moon-env moon.toml          # With custom config"
echo "  ./target/release/moon-env moon.toml agent.lua  # Run agent script"
echo ""
echo "EXAMPLE:"
echo "  ./target/release/moon-env moon.toml agents/codriver.lua"
echo ""
echo "Files created:"
echo "  - moon-env/target/release/moon-env (binary)"
echo "  - moon-env/moon.toml (config)"
echo "  - moon-env/agents/codriver.lua (example agent)"
