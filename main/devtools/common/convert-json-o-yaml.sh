#!/usr/bin/env bash
#
# json-to-yaml.sh
#
#   Converts JSON files to YAML with top-level key preserved,
#   and adds a blank line between list entries.
#
#   Usage:
#     ./json-to-yaml.sh -T ~/devbelt/models
#     ./json-to-yaml.sh -T '~/devbelt/**/*.json' -f

set -euo pipefail

usage() { echo "Usage: $0 -T <path|glob> [-f]"; exit 1; }

target=""; force=false
while getopts ":T:f" opt; do
  case "$opt" in
    T) target=$OPTARG ;;
    f) force=true ;;
    *) usage ;;
  esac
done
[[ -z $target ]] && usage

command -v yq >/dev/null 2>&1 || { echo "❌  yq (Mike Farah v4) required."; exit 1; }

shopt -s globstar nullglob
if [[ -d $target ]]; then
  mapfile -t files < <(find "$target" -type f -iname '*.json')
else
  mapfile -t files < <(eval echo "$target")
fi
[[ ${#files[@]} -eq 0 ]] && { echo "⚠️  No JSON files matched."; exit 0; }

echo "✅  Found ${#files[@]} JSON file(s)."

for json in "${files[@]}"; do
  [[ ! -f $json ]] && continue
  yaml="${json%.*}.yaml"

  if [[ -f $yaml && $force == false ]]; then
    echo "⚠️  $(basename "$json") skipped (YAML exists — use -f to overwrite)"
    continue
  fi

  header=$(basename "${json%.*}")

  yq -p=json -o=yaml -I=2 -e "{\"$header\": .}" "$json" |
    awk '{ if ($0 ~ /^  - id:/) printf "\n%s\n", $0; else print }' > "$yaml"

  echo "✅  $(basename "$json") → $(basename "$yaml")"
done

echo "✅  Done. YAML created."
