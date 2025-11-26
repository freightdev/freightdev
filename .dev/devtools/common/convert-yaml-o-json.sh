#!/usr/bin/env bash
#
# yaml-to-json.sh
# Convert every *.yaml / *.yml under a target path (file, dir, or glob) into *.json
# Originals stay untouched; sibling JSON twins are created.
#
# Basic   : yaml-to-json.sh -T ~/devbelt/_meta             # directory
# Glob    : yaml-to-json.sh -T '~/devbelt/**/*.yaml'       # recursive glob
# Force   : yaml-to-json.sh -T ~/devbelt -f                # overwrite existing .json
#

set -euo pipefail

usage() { echo "Usage: $0 -T <path|glob> [-f]"; exit 1; }

target=""
force_overwrite=false

while getopts ":T:f" opt; do
  case "$opt" in
    T) target=${OPTARG} ;;
    f) force_overwrite=true ;;
    *) usage ;;
  esac
done
[[ -z $target ]] && usage

command -v yq >/dev/null 2>&1 || { echo "❌  'yq' not found. Install Mike Farah yq."; exit 1; }

# Collect YAML files — works for single file, dir, or any glob (incl. **)
shopt -s globstar nullglob
if [[ -d $target ]]; then
  mapfile -t files < <(find "$target" -type f \( -iname '*.yaml' -o -iname '*.yml' \))
else
  mapfile -t files < <(eval echo "$target")
fi
[[ ${#files[@]} -eq 0 ]] && { echo "⚠️  No YAML files matched."; exit 0; }

echo "✅  Found ${#files[@]} YAML file(s)."

for yaml in "${files[@]}"; do
  json="${yaml%.*}.json"
  [[ -f $json && $force_overwrite == false ]] && { echo "⚠️  $(basename "$yaml") skipped (JSON exists)"; continue; }
  yq -o=json "$yaml" > "$json"
  echo "✅  $(basename "$yaml") → $(basename "$json")"
done

echo "✅ Done."
