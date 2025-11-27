#!/usr/bin/env bash
set -euo pipefail

# CONFIG: Directories to search for templates/resources
SOURCE_DIRS=(
    "$HOME/Workspace/Templates"
    "$HOME/Workspace/Tools"
    "/usr/local/share/archives"
)

# Where projects get created
PROJECTS_DIR="$HOME/Workspace"

# Dependency check
if ! command -v fzf >/dev/null; then
    echo "Error: fzf is required (install with: sudo pacman -S fzf)" >&2
    exit 1
fi

# Build a file list from all SOURCE_DIRS
FILES=()
for dir in "${SOURCE_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        while IFS= read -r -d '' file; do
            FILES+=("$file")
        done < <(find "$dir" -mindepth 1 -maxdepth 3 -print0)
    fi
done

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No files found in source directories."
    exit 1
fi

# Use fzf to select multiple items
SELECTED=($(printf '%s\n' "${FILES[@]}" | fzf --multi --preview 'ls -l {}'))

if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo "No components selected."
    exit 1
fi

# Ask for project name
read -rp "Project name: " PROJECT_NAME
TARGET_DIR="$PROJECTS_DIR/$PROJECT_NAME"

if [[ -e "$TARGET_DIR" ]]; then
    echo "Error: $TARGET_DIR already exists."
    exit 1
fi

mkdir -p "$TARGET_DIR"

# Link each selected item
for item in "${SELECTED[@]}"; do
    base=$(basename "$item")
    ln -s "$item" "$TARGET_DIR/$base"
    echo "[+] Linked $base"
done

echo "Done! Project created at $TARGET_DIR"
