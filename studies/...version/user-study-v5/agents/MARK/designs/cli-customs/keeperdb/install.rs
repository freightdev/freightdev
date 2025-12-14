#!/bin/bash
# install.sh – KEEPER installer with binary compilation via SHC

set -euo pipefail

BIN_DIR="${HOME}/devbelt/bin"
SRC_DIR="$(pwd)"
TARGET_NAME="keeper"
ORIGINAL_SCRIPT="$SRC_DIR/$TARGET_NAME"

echo "Starting install from: $SRC_DIR"

# 1. Create required directories if missing
[[ ! -d "$BIN_DIR" ]] && { mkdir -p "$BIN_DIR"; echo "Created $BIN_DIR"; }

# 3. Compile keeper to native binary using shc
echo "Compiling $TARGET_NAME into binary with shc..."
shc -f "$ORIGINAL_SCRIPT"

# Output: keeper.x (binary) and keeper.x.c (source)
BIN_OUTPUT="$SRC_DIR/${TARGET_NAME}.x"
C_OUTPUT="$SRC_DIR/${TARGET_NAME}.x.c"
FINAL_BINARY="$BIN_DIR/$TARGET_NAME"

# 4. Move binary and set permissions
mv "$BIN_OUTPUT" "$FINAL_BINARY"
chmod +x "$FINAL_BINARY"
echo "✅ Binary moved to: $FINAL_BINARY"

# 5. Clean up generated .x.c
rm -f "$C_OUTPUT"
echo "Cleaned: $C_OUTPUT"


echo "keeper install complete. Run 'keeper' anywhere to begin."
