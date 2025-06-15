#!/bin/bash

# Check for path argument
if [ -z "$1" ]; then
  echo "Usage: ./capitalize-folders.sh <starting-folder>"
  exit 1
fi

# Normalize input
ROOT="$1"

# Function to capitalize the first letter of a folder
capitalize() {
  local name="$1"
  local first_upper="$(echo "${name:0:1}" | tr '[:lower:]' '[:upper:]')"
  local rest="${name:1}"
  echo "$first_upper$rest"
}

# Walk the tree, find all folders (depth-first, reverse to avoid name collision)
find "$ROOT" -type d | sort -r | while read -r dir; do
  base="$(basename "$dir")"
  parent="$(dirname "$dir")"
  capitalized="$(capitalize "$base")"

  if [ "$base" != "$capitalized" ]; then
    new_path="$parent/$capitalized"
    echo "Renaming: $dir → $new_path"
    mv "$dir" "$new_path"
  fi
done
