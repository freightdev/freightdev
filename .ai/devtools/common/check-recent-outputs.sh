#!/usr/bin/env bash
# recent-output.sh
# Finds the most recently modified script in ~/Workspace

set -euo pipefail

SEARCH_ROOT="${1:-$HOME}"
AGE_MINUTES="${2:-10}"

find "$SEARCH_ROOT" \
  -type f \( -iname '*.sh' -o -iname '*.zsh' \) \
  -mmin -"$AGE_MINUTES" \
  -printf '%T@ %p\n' | sort -n | tail -n 5 | while read -r line; do
    timestamp=$(cut -d' ' -f1 <<< "$line")
    filepath=$(cut -d' ' -f2- <<< "$line")
    echo "🕒 $(date -d @"$timestamp") → $filepath"
done
