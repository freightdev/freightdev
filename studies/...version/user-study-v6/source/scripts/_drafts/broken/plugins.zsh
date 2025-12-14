#!/bin/zsh

# ======================================
# Plugin Manager
# ======================================

# Plugin List: name|repo_url
PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "zsh-completions|https://github.com/zsh-users/zsh-completions.git"
    "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search.git"
)


install_plugin() {
    local name="$1"
    local url="$2"
    local tmpdir="$ENV_DIR/tmp/plugin_$name"
    mkdir -p "$tmpdir"
    git clone --depth=1 "$url" "$tmpdir/$name" &>/dev/null

    setopt +o nomatch
    for file in "$tmpdir/$name"/*.zsh(N); do
        ln -sf "$file" "$BIN_DIR/${name}_$(basename "$file")"
    done
    setopt -o nomatch

    rm -rf "$tmpdir"
}

# Loop and install
for entry in "${PLUGINS[@]}"; do
    IFS="|" read -r name url <<< "$entry"
    install_plugin "$name" "$url"
done

echo "All plugins installed. $BIN_DIR contains plugin scripts only."
