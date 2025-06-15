#!/usr/bin/env bash
# tree-delete.sh — Delete only files/folders listed in a .tree.md plan
# Run Command: ./tree-delete.sh path/to/*.tree.md -T output/directory || make tree-delete
## When creating a new *.tree.md file, remember to add it to the Makefile.
set -e

INPUT=""
TARGET=""
DRY=false

# Helper to join path
join_path() {
  local joined="$1"
  shift
  for part in "$@"; do
    joined="${joined%/}/$part"
  done
  echo "$joined"
}

# Parse args
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -T|--target) TARGET="$2"; shift 2 ;;
    --dry) DRY=true; shift ;;
    *) INPUT="$1"; shift ;;
  esac
done

if [[ -z "$INPUT" || -z "$TARGET" ]]; then
  echo "❌ Usage: ./tree-delete.sh path/to/tree.md -T path/to/output [--dry]"
  exit 1
fi

echo "🧹 Deleting based on: $INPUT"
echo "📁 Target: $TARGET"
$DRY && echo "🧪 Dry mode: enabled"
echo

declare -a stack
root_detected=false

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  line=$(echo "$raw_line" | sed 's/[[:space:]]*$//')
  [[ -z "$line" ]] && continue

  # Detect root (e.g., scripts/)
  if [[ $root_detected == false && "$line" =~ ^[^├└│].*/$ ]]; then
    root="${line%/}"
    stack=("$root")
    root_path=$(join_path "$TARGET" "$root")
    root_detected=true
    continue
  fi

  # Determine depth from │ indentation
  indent_chars=$(echo "$raw_line" | grep -o '^[[:space:]│]*')
  depth=$(echo "$indent_chars" | sed 's/[^│]//g' | wc -c)

  # Clean name and trim inline comment
  name=$(echo "$line" | sed -E 's/^[│├└─ ]+//' | cut -d '#' -f1 | sed 's/[[:space:]]*$//')
  [[ -z "$name" ]] && continue

  # Trim stack
  stack=("${stack[@]:0:$depth}")

  if [[ "$name" == *.* ]]; then
    # Delete file
    file_path=$(join_path "$TARGET" "${stack[@]}")
    file_fullpath=$(join_path "$file_path" "$name")
    if [[ -f "$file_fullpath" ]]; then
      $DRY && echo "🧪 Would delete file: $file_fullpath" || {
        rm -f "$file_fullpath"
        echo "🗑️  Deleted file: $file_fullpath"
      }
    fi
  else
    # Track folder for optional deletion
    stack+=("$name")
    dir_path=$(join_path "$TARGET" "${stack[@]}")
    if [[ -d "$dir_path" ]]; then
      $DRY && echo "🧪 Would delete folder: $dir_path" || {
        rm -rf "$dir_path"
        echo "📁 Deleted folder: $dir_path"
      }
    fi
  fi
done < "$INPUT"

echo -e "\n✅ Tree-based deletion complete."
