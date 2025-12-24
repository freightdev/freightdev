#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
POETRY_VERSION="${POETRY_VERSION:-}"   # Empty means latest
INSTALL_DIR="${HOME}/.local/bin"       # Where Poetry binary will be linked
POETRY_BIN_PATH="${HOME}/.local/bin"

echo "📦 Setting up Poetry ${POETRY_VERSION:-"(latest)"}..."

# --- Check Python ---
if ! command -v python3 >/dev/null 2>&1; then
    echo "⚠️  Python3 not found. Installing..."

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3 python3-pip
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm python python-pip
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add --no-cache python3 py3-pip
    else
        echo "❌ Could not detect package manager. Please install Python 3 manually."
        exit 1
    fi
else
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
    if [[ "$(printf '%s\n' "3.8" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.8" ]]; then
        echo "❌ Python version $PYTHON_VERSION is too old. Poetry requires Python 3.8+."
        exit 1
    fi
fi

# --- Check if Poetry is already installed ---
if command -v poetry >/dev/null 2>&1; then
    echo "✅ Poetry already installed at: $(command -v poetry)"
    poetry --version
    exit 0
fi

# --- Install Poetry ---
echo "⬇️ Downloading and installing Poetry..."
if [[ -z "$POETRY_VERSION" ]]; then
    curl -sSL https://install.python-poetry.org | python3 -
else
    curl -sSL https://install.python-poetry.org | python3 - --version "$POETRY_VERSION"
fi

# --- Ensure binary path exists ---
mkdir -p "${INSTALL_DIR}"

# --- Add Poetry to PATH if missing ---
if [[ ":$PATH:" != *":${POETRY_BIN_PATH}:"* ]]; then
    echo "🔧 Adding Poetry to PATH..."
    SHELL_RC=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        SHELL_RC="${HOME}/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        SHELL_RC="${HOME}/.bashrc"
    else
        SHELL_RC="${HOME}/.profile"
    fi
    echo "export PATH=\"${POETRY_BIN_PATH}:\$PATH\"" >> "${SHELL_RC}"
    export PATH="${POETRY_BIN_PATH}:$PATH"
fi

# --- Verify ---
echo "✅ Poetry installation complete."
poetry --version
