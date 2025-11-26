#!/usr/bin/env bash
set -euo pipefail

# --- config ---
REPO="https://github.com/ggerganov/llama.cpp"
TARGET_DIR="$(pwd)/../libs/engine/llama.cpp"

mkdir -p ../libs/engine

# --- clone fresh llama.cpp repo into root ---
echo "[+] Cloning fresh llama.cpp into $TARGET_DIR..."
git clone --depth=1 "$REPO" "$TARGET_DIR"

echo "[✓] llama.cpp cloned successfully."
