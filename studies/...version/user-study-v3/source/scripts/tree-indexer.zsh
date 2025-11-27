#!/bin/zsh
# tree-indexer.zsh — generates a Markdown tree of a directory
# Usage: ./tree-indexer.zsh path/to/dir -o $INPUT.tree

set -e

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   ARGUMENT PARSING                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
INPUT=""
OUTPUT=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -o|--output)
      OUTPUT="$2"
      shift
      ;;
    *)
      INPUT="$1"
      shift
      ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  echo "❌ Usage: $0 path/to/dir [-o output.md]"
  exit 1
fi

if [[ ! -d "$INPUT" ]]; then
  echo "❌ Target '$INPUT' is not a directory."
  exit 1
fi

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   DEFAULT OUTPUT PATH                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
dir_name=$(basename "$INPUT")
if [[ -z "$OUTPUT" ]]; then
  OUTPUT="$INPUT/${dir_name}.tree"
fi

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                   CREATE MARKDOWN TREE                  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
{
  echo "# ${dir_name} - Tree Structure"
  echo
  echo '```'
  tree -a --dirsfirst --noreport "$INPUT" | tail -n +2
  echo '```'
} > "$OUTPUT"

echo "✅ Tree saved to: $OUTPUT"
