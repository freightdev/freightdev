#!/usr/bin/env bash
# tree-copy.sh — converts a markdown-like tree into real folders/files
# Use this to create a new project structure.
# Run Command: ./tree-copy.sh path/to/tree.md -T output/directory || make tree-copy

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   SET ERROR TRAP                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
set -e

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   SAFE PATH JOIN FUNCTION               ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
# Example: join_path "a/b" "c" "d" returns "a/b/c/d"
# Example: join_path "a/b" "c/" "d" returns "a/b/c/d"
# Example: join_path ".a/" returns ".a/"
join_path() {
  local result="$1"
  shift
  for segment in "$@"; do
    result="${result%/}/$segment"
  done
  echo "$result"
}


# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   ARGUMENT PARSING                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
INPUT=""
TARGET=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -T|--target)
      TARGET="$2"
      shift 2
      ;;
    *)
      INPUT="$1"
      shift
      ;;
  esac
done

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   ARGUMENT PARSING                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
if [[ -z "$INPUT" || -z "$TARGET" ]]; then
  echo "❌ Usage: ./tree-copy.sh path/to/tree.md -T output/folder"
  exit 1
fi

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃             EXPAND GLOBS/BRACES FOR MULTIPLE FILES     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
if [[ "$INPUT" == *","* || "$INPUT" == *"{"* || "$INPUT" == *"*"* ]]; then
  eval "FILES=($INPUT)"
else
  FILES=("$INPUT")
fi

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   TREE PARSING LOGIC                    ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
for INPUT_FILE in "${FILES[@]}"; do
  echo "🌲 Reading: $INPUT_FILE"
  echo "📁 Target: $TARGET"
  echo

  mkdir -p "$TARGET"
  declare -a stack
  root_detected=0

  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line="$(echo "$raw_line" | sed 's/^[[:space:]]*//')"

    # Skip blank or box-only lines
    if [[ -z "$line" || "$line" =~ ^[│|\s]*$ ]]; then
      continue
    fi

    # Detect root entry (like scripts/)
    if [[ $root_detected == false && "$line" =~ ^[^├└│].*/$ ]]; then
      root="${line%/}"
      stack=("$root")
      root_path=$(join_path "$TARGET" "$root")
      mkdir -p "$root_path"
      echo "📁 $root_path"
      root_detected=true
      continue
    fi

    # Determine tree depth
    indent_chars=$(echo "$raw_line" | grep -o '^[[:space:]│]*')
    depth=$(echo "$indent_chars" | sed 's/[^│]//g' | wc -c)
    echo "🧱 Stack depth $depth: ${stack[*]}"

    # Trim stack to depth
    stack=("${stack[@]:0:$depth}")

    # sed to remove special characters / 
    # cut to remove the # and trailing space / 
    # sed to remove the trailing space
    name=$(echo "$line" | sed -E 's/^[│├└─ ]+//' | cut -d '#' -f1 | sed 's/[[:space:]]*$//')
    [[ -z "$name" ]] && continue
    [[ "$name" =~ ^[│├└] ]] && continue

    # ┌ Detect if it's a folder (trailing slash)
    is_dir=false
    if [[ "$name" == */ ]]; then
      name="${name%/}"
      is_dir=true
    fi

    # ┌ Folder or file?
    if [[ "$is_dir" == true ]]; then
      stack+=("$name")
      dir_path=$(join_path "$TARGET" "${stack[@]}")
      mkdir -p "$dir_path"
      echo "📁 $dir_path"
    elif [[ "$name" == *.* ]]; then
      file_fullpath=$(join_path "$TARGET" "${stack[@]}" "$name")
      mkdir -p "$(dirname "$file_fullpath")"
      touch "$file_fullpath"

    else
      # assume it's a folder if no dot, no trailing slash
      stack+=("$name")
      dir_path=$(join_path "$TARGET" "${stack[@]}")
      mkdir -p "$dir_path"
      echo "📁 $dir_path"
    fi
  done < "$INPUT_FILE"
done

echo -e "\n✅ Tree structure generated."