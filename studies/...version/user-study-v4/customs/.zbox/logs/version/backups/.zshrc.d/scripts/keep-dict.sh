#!/usr/bin/env bash
# keep-dict.sh - Manage .gitkeep files universally
# Location: scripts/repo/keep-dict.sh

set -euo pipefail

usage() {
  cat <<EOF
Usage: keep-dict.sh -T <target_directory> [--mode <add|remove|all>] [--level N] [--ignore "dir1,dir2,..."] [--dry-run] [--verbose]

Options:
  -T, --target     Root directory to process (required)
  --mode           Operation mode: add, remove, or all [default: add]
  --level          Limit recursion depth (default: unlimited)
  --ignore         Comma-separated list of directories to ignore
  --dry-run        Show what would happen without changing anything
  --verbose        Output each action taken
  -h, --help       Show this help message

Examples:
  keep-dict.sh -T ./project
  keep-dict.sh -T ./repo --mode all --ignore ".git,node_modules" --level 3 --verbose
EOF
  exit 1
}

# --- Defaults ---
TARGET=""
MODE="add"
LEVEL=""
IGNORE=()
VERBOSE=0
DRYRUN=0

# --- Argument Parser ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -T|--target) TARGET="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --level) LEVEL="$2"; shift 2 ;;
    --ignore) IFS=',' read -r -a IGNORE <<< "$2"; shift 2 ;;
    --dry-run) DRYRUN=1; shift ;;
    --verbose) VERBOSE=1; shift ;;
    -h|--help) usage ;;
    *) echo "❌ Unknown option: $1"; usage ;;
  esac
done

# --- Validation ---
[[ -z "$TARGET" ]] && echo "❌ Missing required target (-T)" && usage
[[ ! -d "$TARGET" ]] && echo "❌ Target does not exist: $TARGET" && exit 1

[[ "$MODE" != "add" && "$MODE" != "remove" && "$MODE" != "all" ]] && {
  echo "❌ Invalid mode: $MODE (use add, remove, or all)"
  exit 1
}

# --- Build Find Ignore Expression ---
FIND_IGNORE=""
for pattern in "${IGNORE[@]}"; do
  FIND_IGNORE+=" ! -path \"*/$pattern/*\""
done

# --- Compose Find Commands ---
build_find_dirs() {
  if [[ -n "$LEVEL" ]]; then
    echo "find \"$TARGET\" -maxdepth $LEVEL -type d -empty ${FIND_IGNORE}"
  else
    echo "find \"$TARGET\" -type d -empty ${FIND_IGNORE}"
  fi
}

build_find_files() {
  if [[ -n "$LEVEL" ]]; then
    echo "find \"$TARGET\" -maxdepth $LEVEL -type f -name \".gitkeep\" ${FIND_IGNORE}"
  else
    echo "find \"$TARGET\" -type f -name \".gitkeep\" ${FIND_IGNORE}"
  fi
}

# --- Actions ---
add_gitkeeps() {
  eval "$(build_find_dirs)" | while read -r dir; do
    [[ "$VERBOSE" -eq 1 ]] && echo "➕ Adding .gitkeep to: $dir"
    [[ "$DRYRUN" -eq 0 ]] && touch "$dir/.gitkeep"
  done
}

remove_gitkeeps() {
  eval "$(build_find_files)" | while read -r file; do
    [[ "$VERBOSE" -eq 1 ]] && echo "🗑️  Removing: $file"
    [[ "$DRYRUN" -eq 0 ]] && rm -f "$file"
  done
}

# --- Execute ---
[[ "$MODE" == "add" || "$MODE" == "all" ]] && add_gitkeeps
[[ "$MODE" == "remove" || "$MODE" == "all" ]] && remove_gitkeeps

echo "✅ keep-dict.sh complete."
