#!/usr/bin/env zsh
# zbox-zsh-installer.sh
# Installs a custom Zsh from source, applies your patch, sets it as default, cleans up.

set -euo pipefail

# --- Variables ---
ZBOX_DIR="${HOME}/.zbox"
TMP_DIR="${ZBOX_DIR}/tmp"
LOCAL_BIN="${HOME}/.local/bin"
PATCH_SCRIPT="${ZBOX_DIR}/scripts/fix-content.sh"
ZSH_PREFIX="${LOCAL_BIN}/zbox-zsh"

mkdir -p "$TMP_DIR" "$LOCAL_BIN"
cd "$TMP_DIR"

# --- Download latest Zsh source to temp file ---
tmpfile=$(mktemp "$TMP_DIR/zsh.XXXXXX.tar.xz")
wget -O "$tmpfile" https://sourceforge.net/projects/zsh/files/latest/download

# --- Extract ---
tar -xf "$tmpfile"
cd zsh-* || { echo "Extraction failed"; exit 1 }

# --- Apply patch ---
if [[ -x "$PATCH_SCRIPT" ]]; then
    "$PATCH_SCRIPT" \
        -t "Src/init.c" \
        -f 'sourcehome(".zshrc")' \
        -r 'sourcehome(".zboxrc")' \
        -F
else
    echo "Patch script not found or not executable: $PATCH_SCRIPT"
    exit 1
fi

# --- Configure, compile, install ---
./configure --prefix="$ZSH_PREFIX"
make -j$(nproc)
make install

# --- Update PATH permanently for this user ---
PROFILE_FILE="${HOME}/.zshenv"  # minimal, always sourced by Zsh
if ! grep -q "$ZSH_PREFIX/bin" "$PROFILE_FILE"; then
    echo "export PATH=\"$ZSH_PREFIX/bin:\$PATH\"" >> "$PROFILE_FILE"
fi

# --- Set this Zsh as default shell ---
if command -v chsh >/dev/null 2>&1; then
    chsh -s "$ZSH_PREFIX/bin/zsh" || echo "chsh failed, run manually with: chsh -s $ZSH_PREFIX/bin/zsh"
fi

# --- Cleanup ---
cd "$ZBOX_DIR"
rm -rf "$TMP_DIR"

echo "✅ Zsh installed at: $ZSH_PREFIX/bin/zsh"
echo "Your PATH updated in: $PROFILE_FILE"
echo "Restart your terminal or re-login to use your new Zsh."
