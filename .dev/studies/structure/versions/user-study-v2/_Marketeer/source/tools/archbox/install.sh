#!/bin/bash
# install.sh – Safe installer for zshctr package

ZDOTDIR="${HOME}/.zshrc.d"
BIN_DIR="${HOME}/bin"
SRC_DIR="$(pwd)"


echo "🔧 Starting zshctr install from: $SRC_DIR"

# 1. Create required directories if missing
[[ ! -d "$ZDOTDIR" ]] && { mkdir -p "$ZDOTDIR"; echo "📁 Created $ZDOTDIR"; }
[[ ! -d "$BIN_DIR" ]] && { mkdir -p "$BIN_DIR"; echo "📁 Created $BIN_DIR"; }

# 2. Copy *.zsh files (only if missing)
for f in "$SRC_DIR"/settings/.zshrc.d/*.zsh; do
  base=$(basename "$f")
  dest="$ZDOTDIR/$base"
  if [[ -f "$dest" ]]; then
    echo "⏭️  Skipped existing: $dest"
  else
    cp "$f" "$dest"
    echo "✅ Installed: $dest"
  fi
done

# 3. L the main zshctr binary (only if not present)
ZSHCTR_DEST="$BIN_DIR/zshctr"
if [[ -f "$ZSHCTR_DEST" ]]; then
  echo "⏭️  zshctr already exists at $ZSHCTR_DEST"
else
  chmod +x "$ZSHCTR_DEST"
  echo "✅ Installed zshctr to $ZSHCTR_DEST"
fi

# 4. Inject source block into .zshrc only if missing
BLOCK='for f in ~/.zshrc.d/*.zsh; do source "$f"; done'

if grep -qF "$BLOCK" ~/.zshrc; then
  echo "✅ Sourcing block already present in ~/.zshrc"
else
  echo "" >> ~/.zshrc
  echo "# ZSHCTR INIT BLOCK" >> ~/.zshrc
  echo "$BLOCK" >> ~/.zshrc
  echo "✅ Sourcing block added to ~/.zshrc"
fi

echo "🎉 zshctr install complete. Run 'zshctr' to get started."
