#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 (-d <directory> | -f <file>) <source_path> [-t <target_path>]"
  echo
  echo "Options:"
  echo "  -d <directory>   Push changes from directory"
  echo "  -f <file>        Push changes from single file"
  echo "  -t <target_path> Optional target directory (where to push changes)"
  echo
  echo "If -t is not provided, script will attempt to find target folder by matching source base name"
  exit 1
}

# Parse flags
MODE=""
SOURCE_PATH=""
TARGET_PATH=""

while getopts "d:f:t:" opt; do
  case $opt in
    d) MODE="dir"; SOURCE_PATH="$OPTARG" ;;
    f) MODE="file"; SOURCE_PATH="$OPTARG" ;;
    t) TARGET_PATH="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$MODE" ]] || [[ -z "$SOURCE_PATH" ]]; then
  usage
fi

# Check source exists
if [[ "$MODE" == "dir" && ! -d "$SOURCE_PATH" ]]; then
  echo "Error: Source directory '$SOURCE_PATH' does not exist."
  exit 1
elif [[ "$MODE" == "file" && ! -f "$SOURCE_PATH" ]]; then
  echo "Error: Source file '$SOURCE_PATH' does not exist."
  exit 1
fi

# If no target given, try to guess target by basename
if [[ -z "$TARGET_PATH" ]]; then
  BASE_NAME=$(basename "$SOURCE_PATH")
  # Example: if source is ~/.zshrc.d, search in home for a matching dir
  echo "No target specified. Trying to find a matching directory named '$BASE_NAME' in your home folder..."
  TARGET_PATH=$(find "$HOME" -maxdepth 3 -type d -name "$BASE_NAME" 2>/dev/null | head -n 1 || true)
  
  if [[ -z "$TARGET_PATH" ]]; then
    echo "Could not find a matching directory named '$BASE_NAME' in your home folder."
    echo "Please provide target directory with -t."
    exit 1
  else
    echo "Found target directory: $TARGET_PATH"
  fi
fi

echo
echo "Source: $SOURCE_PATH"
echo "Target: $TARGET_PATH"
echo

confirm() {
  read -r -p "$1 [y/N]: " response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "$MODE" == "dir" ]]; then
  echo "Performing dry-run rsync to show changes:"
  rsync -avun --delete "$SOURCE_PATH"/ "$TARGET_PATH"/
  
  if confirm "Apply these changes?"; then
    rsync -avu --delete "$SOURCE_PATH"/ "$TARGET_PATH"/
    echo "✅ Directory synced successfully."
  else
    echo "Aborted by user."
    exit 0
  fi
elif [[ "$MODE" == "file" ]]; then
  FILE_NAME=$(basename "$SOURCE_PATH")
  TARGET_FILE="$TARGET_PATH/$FILE_NAME"
  
  echo "Showing diff between source and target file (if exists):"
  if [[ -f "$TARGET_FILE" ]]; then
    diff -u "$TARGET_FILE" "$SOURCE_PATH" || true
  else
    echo "Target file does not exist, will copy."
  fi
  
  if confirm "Copy file '$FILE_NAME' to '$TARGET_PATH'?"; then
    cp "$SOURCE_PATH" "$TARGET_FILE"
    echo "✅ File copied successfully."
  else
    echo "Aborted by user."
    exit 0
  fi
fi
