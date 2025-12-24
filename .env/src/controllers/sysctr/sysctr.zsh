#!/bin/bash
# keeper

BELT_DIR="$HOME/devbelt"
BIN_DIR="$HOME/devbelt/bin"
BOOK_DIR="$BELT_DIR/books"
SOURCE_DIR="$BELT_DIR/src"

BOOK="$1"

[[ -z "$BOOK" ]] && { echo "Usage: keeper <bookname>"; exit 1; }

BOOK_PATH="$BOOK_DIR/$BOOK.book"
[[ ! -f "$BOOK_PATH" ]] && { echo "❌ Book not found: $BOOK_PATH"; exit 1; }

BELTS=$(yq e '.belts[]' "$BOOK_PATH")

for BELT in $BELTS; do
  echo "Building: $BELT"

  SRC_PATH="$SOURCE_DIR/$BELT"
  INSTALL_SCRIPT="$SRC_PATH/$(yq e '.build.entry')"
  DEST_BIN=$(yq e '.build.output')

  if [[ -f "$INSTALL_SCRIPT" ]]; then
    echo "Installing $BELT..."
    (cd "$SRC_PATH" && bash "$INSTALL_SCRIPT")
    mv "$SRC_PATH/$DEST_BIN" "$BIN_DIR/$DEST_BIN"
    chmod +x "$BIN_DIR/$DEST_BIN"
    echo "✅ Installed to $BIN_DIR/$DEST_BIN"
  else
    echo "❌ No install.sh found for $BELT"
  fi
done
