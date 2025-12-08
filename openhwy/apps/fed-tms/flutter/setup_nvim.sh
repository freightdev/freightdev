#!/bin/bash
set -e

echo "🚀 Setting up Neovim IDE for OpenHWY..."

# Backup existing config
if [ -d "$HOME/.config/nvim" ]; then
    echo "📦 Backing up existing Neovim config..."
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
fi

# Install dependencies
echo "📥 Installing dependencies..."
sudo apt update
sudo apt install -y \
    neovim \
    git \
    curl \
    ripgrep \
    fd-find \
    nodejs \
    npm \
    python3-pip \
    python3-venv \
    lua5.4 \
    luarocks

# Install neovim python support
pip3 install --user pynvim

# Install Node packages for LSP
sudo npm install -g \
    typescript \
    typescript-language-server \
    vscode-langservers-extracted \
    yaml-language-server \
    bash-language-server

# Install Rust analyzer (for Rust)
if ! command -v rust-analyzer &> /dev/null; then
    echo "📥 Installing rust-analyzer..."
    rustup component add rust-analyzer
fi

# Install Go tools (for Go LSP)
if command -v go &> /dev/null; then
    go install golang.org/x/tools/gopls@latest
fi

# Clone LazyVim starter
echo "📥 Installing LazyVim..."
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"

echo "✅ Base installation complete!"
echo ""
echo "Now run: nvim"
echo "LazyVim will install plugins on first launch (takes 1-2 minutes)"
echo ""
echo "After that, we'll add the AI integration and custom config."
