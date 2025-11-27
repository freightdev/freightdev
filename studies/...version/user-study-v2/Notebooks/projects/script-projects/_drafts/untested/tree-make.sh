#!/bin/zsh

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# tree-make.zsh — converts a tree into real folders/files
# Use this to create a new project structure.
# Run Command: ./tree-make.zsh path/to/tree -o output/directory
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# SAFE PATH JOIN FUNCTION
join_path() {
  local result="$1"
  shift
  for segment in "$@"; do
    [[ -n "$segment" ]] && result="${result%/}/$segment"
  done
  echo "$result"
}



# ARGUMENT PARSING
INPUT=""
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) TARGET="$2"; shift 2 ;;
    *) INPUT="$1"; shift ;;
  esac
done


if [[ -z "$INPUT" || -z "$TARGET" ]]; then
  echo "❌ Usage: $0 path/to/tree -o output/folder"
  exit 1
fi


# EXPAND GLOBS/BRACES FOR MULTIPLE FILES
if [[ "$INPUT" == *","* || "$INPUT" == *"{"* || "$INPUT" == *"*"* ]]; then
  eval "FILES=($INPUT)"
else
  FILES=("$INPUT")
fi


# TREE PARSING LOGIC
mkdir -p "$TARGET"
declare -a stack

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  # Remove leading/trailing spaces
  line="$(echo "$raw_line" | sed -E 's/^[[:space:]`|│├└─]+*[[:space:]]*//')"
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^[│\s]*$ ]] && continue

  # Remove tree drawing characters and strip inline comments
  clean_name=$(echo "$line" | sed -E 's/^[│|├└─ ]+//' | cut -d '#' -f1 | sed 's/[[:space:]]*$//')
  [[ -z "$clean_name" ]] && continue

  # Count depth based on 4-space or tree-symbol blocks
  indent_count=$(echo "$raw_line" | sed -E 's/[^│]//g' | wc -c)
  depth=$((indent_count))

  # Adjust stack to current depth
  stack=("${stack[@]:0:$depth}")

  if [[ "$clean_name" == */ ]]; then
    # Directory with trailing slash
    clean_name="${clean_name%/}"
    stack+=("$clean_name")
    dir_path=$(join_path "$TARGET" "${stack[@]}")
    mkdir -p "$dir_path"
    echo "📁 $dir_path"
  elif [[ "$clean_name" == *.* ]]; then
    # File (has an extension)
    file_fullpath=$(join_path "$TARGET" "${stack[@]}" "$clean_name")
    mkdir -p "$(dirname "$file_fullpath")"
    touch "$file_fullpath"
    echo "📄 $file_fullpath"
  else
    # Directory without slash (assume folder)
    stack+=("$clean_name")
    dir_path=$(join_path "$TARGET" "${stack[@]}")
    mkdir -p "$dir_path"
    echo "📁 $dir_path"
  fi
done < "$INPUT"

echo -e "\n✅ Tree structure generated at: $TARGET"