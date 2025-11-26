#!/usr/bin/env bash

set -e

INPUT=$1
shift

TARGET=""
NO_INDEX=false

# Flag parser
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -T|--target)
      TARGET="$2"
      shift 2
      ;;
    --no-index)
      NO_INDEX=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT" || -z "$TARGET" ]]; then
  echo "Usage: ./create-ui.sh ComponentName.tsx -T path/to/target [--no-index]"
  exit 1
fi

# Split name + extension
NAME_WITH_EXT=$(basename -- "$INPUT")
EXT="${NAME_WITH_EXT##*.}"
BASE="${NAME_WITH_EXT%.*}"

# PascalCase component folder
COMPONENT_CAP=$(echo "$BASE" | sed -E 's/(^|_)([a-z])/\U\2/g')
COMPONENT_DIR="$TARGET/$COMPONENT_CAP"

mkdir -p "$COMPONENT_DIR"

# Create empty core files
touch "$COMPONENT_DIR/$COMPONENT_CAP.$EXT"
touch "$COMPONENT_DIR/$COMPONENT_CAP.props.ts"
touch "$COMPONENT_DIR/$COMPONENT_CAP.variants.ts"

# Optional index.ts
if [ "$NO_INDEX" = false ]; then
  echo "export * from './$COMPONENT_CAP'" > "$COMPONENT_DIR/index.ts"
fi

echo "✅ $COMPONENT_CAP scaffolded in $COMPONENT_DIR"
