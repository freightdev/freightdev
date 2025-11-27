#!/bin/zsh

# ======================================
# Package Manager
# ======================================

# Export BIN_DIR early so links are immediately usable
export PATH="$BIN_DIR:$PATH"

# Packages list
# Format: name|type|source|optional_gpg_key
# type: pacman, git, tar, curl
PACKAGES=(
    "git|pacman|git"
    "curl|pacman|curl"
    "tree|pacman|tree"
    "tar|pacman|tar"
    "htop|pacman|htop"
    "bat|tar|https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-unknown-linux-gnu.tar.gz|"
)

# ------------------------------
# Pacman packages (link only)
# ------------------------------
install_pacman() {
    local pkg="$1"
    if command -v "$pkg" &>/dev/null; then
        ln -sf "$(command -v $pkg)" "$BIN_DIR/$pkg"
    fi
}

# ------------------------------
# Git packages (clone -> link bin -> cleanup)
# ------------------------------
install_tar() {
    local url="$1"
    local gpg_key="$2"
    local tmpfile tmpdir
    tmpdir="$ENV_DIR/tmp/tar_install"
    mkdir -p "$tmpdir"
    tmpfile="$tmpdir/archive.tar.gz"

    curl -L "$url" -o "$tmpfile"

    [[ -n "$gpg_key" ]] && {
        curl -L "$url.sig" -o "$tmpfile.sig"
        gpg --keyserver hkps://keys.openpgp.org --recv-keys "$gpg_key"
        gpg --verify "$tmpfile.sig" "$tmpfile"
    }

    tar -xzf "$tmpfile" -C "$tmpdir"
    rm -f "$tmpfile"

    setopt +o nomatch
    for pkg in "$tmpdir"/*; do
        [[ -d "$pkg/bin" ]] && ln -sf "$pkg/bin/"* "$BIN_DIR/" 2>/dev/null
    done
    setopt -o nomatch

    rm -rf "$tmpdir"
}

# ------------------------------
# Main install loop
# ------------------------------

for entry in "${PACKAGES[@]}"; do
    IFS="|" read -r name type source gpg_key <<< "$entry"
    case "$type" in
        pacman) install_pacman "$source" ;;
        git) install_git "$source" ;;
        tar|curl) install_tar "$source" "$gpg_key" ;;
    esac
done

echo "All packages installed. Only packages and their bins are linked into: $BIN_DIR"