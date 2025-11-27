#!/bin/bash

# marketeer Installation Script
# Installs marketeer CLI tool system-wide

set -e

PROGRAM_NAME="marketeer"
VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.config/marketeer"
SCHEMAS_DIR="$CONFIG_DIR/schemas"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${1}${2}${NC}"
}

print_status "$BLUE" "🎪 Installing $PROGRAM_NAME v$VERSION"
echo ""

# Check if running as root for system install
if [[ $EUID -eq 0 ]]; then
    print_status "$YELLOW" "⚠️  Running as root - installing system-wide"
    INSTALL_DIR="/usr/local/bin"
else
    print_status "$BLUE" "Installing to user directory"
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

# Create directories
print_status "$BLUE" "📁 Creating directories..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$SCHEMAS_DIR"
mkdir -p "$HOME/.local/share/marketeer"

# Copy main script
print_status "$BLUE" "📋 Installing marketeer executable..."
cp "$PROGRAM_NAME" "$INSTALL_DIR/$PROGRAM_NAME"
chmod +x "$INSTALL_DIR/$PROGRAM_NAME"

# Copy example schemas
print_status "$BLUE" "📄 Installing example schemas..."
if [[ -d "examples" ]]; then
    cp examples/*.yaml "$SCHEMAS_DIR/" 2>/dev/null || true
    cp examples/*.yml "$SCHEMAS_DIR/" 2>/dev/null || true
fi

# Copy documentation
print_status "$BLUE" "📚 Installing documentation..."
if [[ -d "docs" ]]; then
    cp -r docs "$HOME/.local/share/marketeer/"
fi

# Check if directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_status "$YELLOW" "⚠️  $INSTALL_DIR is not in your PATH"
    print_status "$YELLOW" "Add this line to your ~/.bashrc or ~/.zshrc:"
    print_status "$YELLOW" "export PATH=\"\$PATH:$INSTALL_DIR\""
    echo ""
fi

# Create completion script
print_status "$BLUE" "🔧 Setting up bash completion..."
cat > "$CONFIG_DIR/completion.bash" << 'EOF'
# marketeer bash completion
_marketeer_completion() {
    local cur prev opts schemas
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="--help --version --list-schemas --validate --verbose --dry-run --force --quiet"
    
    # Complete schema files
    if [[ ${cur} == *.* ]] || [[ ${#COMP_WORDS[@]} -eq 2 ]]; then
        schemas=$(find . -name "*.schema.yaml" -o -name "*.schema.yml" 2>/dev/null | sed 's|^\./||')
        COMPREPLY=( $(compgen -W "${schemas}" -- ${cur}) )
        return 0
    fi
    
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _marketeer_completion marketeer
EOF

print_status "$GREEN" "✅ Installation complete!"
print_status "$BLUE" "📍 Installed to: $INSTALL_DIR/$PROGRAM_NAME"
print_status "$BLUE" "⚙️  Config directory: $CONFIG_DIR"
print_status "$BLUE" "📄 Example schemas: $SCHEMAS_DIR"
echo ""
print_status "$GREEN" "🚀 Run 'marketeer --help' to get started!"
print_status "$GREEN" "🚀 Run 'marketeer --list-schemas' to see examples!"
echo ""

# Optional: Add completion to shell
read -p "Add bash completion to ~/.bashrc? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "source $CONFIG_DIR/completion.bash" >> ~/.bashrc
    print_status "$GREEN" "✅ Bash completion added to ~/.bashrc"
fi