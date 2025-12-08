#!/bin/bash
# Setup Marketeer Dashboard

echo "🚛 Setting up Marketeer Dashboard..."

# Create project
mkdir -p marketeer-dashboard/src

# Copy files
cp marketeer-dashboard-main.rs marketeer-dashboard/src/main.rs
cp marketeer-cargo.toml marketeer-dashboard/Cargo.toml

cd marketeer-dashboard

# Build
echo "📦 Building Marketeer Dashboard..."
cargo build --release

echo "✅ Marketeer Dashboard ready!"
echo ""
echo "CONTROLS:"
echo "  Tab       - Switch between panels"
echo "  ↑/↓       - Navigate lists"
echo "  r         - Refresh systems"
echo "  l         - Launch agent"
echo "  k         - Kill agent"
echo "  Ctrl+S    - SSH to selected system"
echo "  q         - Quit"
echo ""
echo "Starting dashboard..."
./target/release/marketeer-dashboard
