#!/bin/bash
set -euo pipefail

# === CONFIGS ==== 
SECRET_PATH="change-me"
PROJECT_DIR="change-me"
TARGET_DIR="change-me"

# === GENERATORS ===
mkdir -p "$PROJECT_DIR"

# Try to secret file from env var, fallback to default path
SECRET_FILE="${SECRET_PATH:-$HOME/$TARGET_DIR}"

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "❌ Secret file not found at $TOKEN_FILE"
  echo "Please create it or set _PATH environment variable."
  exit 1
fi

source "$TOKEN_FILE"

[[ -z "${HF_TOKEN:-}" ]] && { echo "HF_TOKEN not set in $TOKEN_FILE"; exit 1; }

echo "🤖 Starting download with your token..."

# (rest of logic here)
