#!/usr/bin/env zsh

set -euo pipefail

echo "🚀 Sparse Clone Selector for freightdev/freightdev"

TMP_DIR="tmp-repo"

if [[ -d "$TMP_DIR" ]]; then
    echo "⚠️  Removing existing $TMP_DIR"
    rm -rf "$TMP_DIR"
fi

git clone -b main --no-checkout git@github.com:freightdev/freightdev "$TMP_DIR"
cd "$TMP_DIR"

git sparse-checkout init --cone

echo "📂 Available top-level directories:"
git ls-tree -d --name-only origin/main

echo
read -r "?👉 Enter the path you want to pull (relative to repo root): " SELECTED

if [[ -z "$SELECTED" ]]; then
    echo "❌ No selection made. Exiting."
    exit 1
fi

git sparse-checkout set "$SELECTED"

read -r "?➕ Do you want to add extras (just checking..) (y/n)? " ADD_EXTRAS

if [[ "$ADD_EXTRAS" == [Yy]* ]]; then
    echo "📂 Available top-level directories again:"
    git ls-tree -d --name-only origin/main
    echo
    read -r "?👉 Enter extra paths separated by spaces: " EXTRAS
    if [[ -n "$EXTRAS" ]]; then
        git sparse-checkout set "$SELECTED" $EXTRAS
    fi
fi

git checkout main

echo "✅ Sparse checkout complete."
ls -la "$SELECTED"
