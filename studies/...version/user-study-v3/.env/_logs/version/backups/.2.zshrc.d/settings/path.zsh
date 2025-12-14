# ========================================
# Path Settings (Zsh)
# ========================================

# Path typeset to keep unique entries
typeset -U path fpath

# Programming language paths (prepend if they exist)
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
[[ -d "$HOME/go/bin" ]] && path=("$HOME/go/bin" $path)
[[ -d "$HOME/.npm-global/bin" ]] && path=("$HOME/.npm-global/bin" $path)
[[ -d "$HOME/.yarn/bin" ]] && path=("$HOME/.yarn/bin" $path)
[[ -d "$HOME/.deno/bin" ]] && path=("$HOME/.deno/bin" $path)

# Export final PATH
export PATH