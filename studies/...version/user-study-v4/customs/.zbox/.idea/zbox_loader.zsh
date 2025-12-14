#! /usr/bin/env zsh
#  ╔══════════════════════════════╗
#?   ZBox Configurations - v1.0.0
#  ╚══════════════════════════════╝

# -----------------------------
# 1️⃣ Determine ZBox Home
# -----------------------------
ZBOX_HOME="${ZBOX_HOME:-$(dirname ${(%):-%N})}"  # Loader's directory
ZBOX_BIN="$ZBOX_HOME/bin"
ZBOX_MODULES="$ZBOX_HOME/modules"
ZBOX_CONFIG="$ZBOX_HOME/config"

# Make sure directories exist
mkdir -p "$ZBOX_BIN" "$ZBOX_MODULES" "$ZBOX_CONFIG"

# -----------------------------
# 2️⃣ Add bin to PATH
# -----------------------------
if [[ ":$PATH:" != *":$ZBOX_BIN:"* ]]; then
    export PATH="$ZBOX_BIN:$PATH"
fi

# -----------------------------
# 3️⃣ Logging / Output Functions
# -----------------------------
log_info()  { print -P "%F{cyan}[INFO]%f $*"; }
log_warn()  { print -P "%F{208}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{121}[OK]%f $*"; }

# -----------------------------
# 4️⃣ Load Configuration
# -----------------------------
# Load all files in config folder
if [[ -d "$ZBOX_CONFIG" ]]; then
    for cfg in "$ZBOX_CONFIG"/*(.N); do
        [[ -r "$cfg" ]] && source "$cfg"
    done
fi

# -----------------------------
# 5️⃣ Module Loader Function
# -----------------------------
load_module() {
    local mod="$1"
    local path="$ZBOX_MODULES/$mod.zsh"

    if [[ -r "$path" ]]; then
        log_info "Loading module: $mod"
        source "$path"
        return 0
    else
        log_warn "Module not found: $mod"
        return 1
    fi
}

# -----------------------------
# 6️⃣ Key-Based Module Loader
# -----------------------------
# Define keys for modules you want
ZBOX_KEYS=("${ZBOX_KEYS[@]:-llama jupyter api}")  

for key in "${ZBOX_KEYS[@]}"; do
    load_module "$key"
done

# -----------------------------
# 7️⃣ Export / De-export Keys
# -----------------------------
# Usage example:
# export ZBOX_KEY="llama"
# ... run something ...
# export -n ZBOX_KEY
# unset ZBOX_KEY

# -----------------------------
# 8️⃣ Utility: Dynamic Resolver
# -----------------------------
# If a module moves, you can optionally search known locations
resolve_module() {
    local mod="$1"
    local found="$(find "$ZBOX_HOME" -name "$mod.zsh" 2>/dev/null | head -n1)"
    [[ -n "$found" ]] && echo "$found" || return 1
}

# Example of using resolver
# path=$(resolve_module "llama") && source "$path"

log_ok "ZBox environment initialized!"
