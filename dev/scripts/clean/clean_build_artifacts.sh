#!/bin/bash

set -e

echo "🧹 Cleaning up build artifacts across the repo..."

# Define all the directories you want to remove
TARGETS=(
  "node_modules"
  ".next"
  ".turbo"
  "dist"
  "build"
  "out"
  ".expo"
  ".parcel-cache"
  ".cache"
  ".vite"
  "coverage"
)

# Run from the root of the repo
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

# Loop through and find/delete targets
for target in "${TARGETS[@]}"; do
  echo "🔍 Looking for: $target"
  find . -type d -name "$target" -prune -exec rm -rf {} + -print
done

echo "✅ Cleanup complete."
