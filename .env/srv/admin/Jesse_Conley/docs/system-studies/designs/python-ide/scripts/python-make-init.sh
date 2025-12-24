#!/usr/bin/env bash
set -euo pipefail

DIR="$1"

if [[ ! -d "$DIR" ]]; then
  echo "Error: Directory '$DIR' does not exist"
  exit 1
fi

INIT_FILE="$DIR/__init__.py"

# Clear or create __init__.py
> "$INIT_FILE"

declare -a all_exports=()

for file in "$DIR"/*.py; do
  filename=$(basename "$file")
  modname="${filename%.py}"

  if [[ "$modname" == "__init__" ]]; then
    continue
  fi

  # Extract top-level defs and classes (no indent, lines starting with def or class)
  exports=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^def[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
      exports+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^class[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
      exports+=("${BASH_REMATCH[1]}")
    fi
  done < <(grep -E '^(def |class )' "$file")

  if [[ ${#exports[@]} -gt 0 ]]; then
    # join exports with commas for valid python import
    joined_exports=$(IFS=, ; echo "${exports[*]}")
    echo "from .${modname} import ${joined_exports}" >> "$INIT_FILE"

    all_exports+=("${exports[@]}")
  fi
done

# Remove duplicates preserving order
unique_exports=()
declare -A seen
for e in "${all_exports[@]}"; do
  if [[ -z "${seen[$e]:-}" ]]; then
    unique_exports+=("$e")
    seen[$e]=1
  fi
done

# Write __all__ list
{
  echo ""
  echo "__all__ = ["
  for name in "${unique_exports[@]}"; do
    echo "    '${name}',"
  done
  echo "]"
} >> "$INIT_FILE"

echo "Barrel __init__.py generated at $INIT_FILE"
