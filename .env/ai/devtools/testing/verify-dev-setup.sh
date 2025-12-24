#!/bin/bash

echo "=== Development Environment Check ==="
echo ""

# Rust
echo "Rust:"
rustc --version 2>/dev/null && echo "✓ Rust installed" || echo "✗ Rust missing"
cargo --version 2>/dev/null && echo "✓ Cargo installed" || echo "✗ Cargo missing"
echo ""

# Go
echo "Go:"
go version 2>/dev/null && echo "✓ Go installed" || echo "✗ Go missing"
echo ""

# Node.js
echo "Node.js:"
node --version 2>/dev/null && echo "✓ Node installed" || echo "✗ Node missing"
npm --version 2>/dev/null && echo "✓ npm installed" || echo "✗ npm missing"
echo ""

# Tools
echo "Essential Tools:"
git --version 2>/dev/null && echo "✓ Git installed" || echo "✗ Git missing"
rg --version 2>/dev/null && echo "✓ ripgrep installed" || echo "✗ ripgrep missing"
fdfind --version 2>/dev/null && echo "✓ fd installed" || echo "✗ fd missing"
echo ""

echo "=== PATH Check ==="
echo "Cargo bin: $(echo $PATH | grep -o '[^:]*cargo[^:]*' | head -1)"
echo "Go bin: $(echo $PATH | grep -o '[^:]*go[^:]*' | head -1)"
echo "Node bin: $(dirname $(which node) 2>/dev/null)"
