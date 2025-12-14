# ~/.zbox/init.zsh
# Main entrypoint for zBox

zBOX_DIR="$HOME/.zbox"
zBOX_CONFIG="$zBOX_DIR/config"
zBOX_ENABLED=1   # master switch

# --- core helpers ---
zbox_log() { print -P "%F{cyan}[zBOX]%f $*"; }
zbox_on()  { zBOX_ENABLED=1; zbox_log "enabled"; }
zbox_off() { zBOX_ENABLED=0; zbox_log "disabled"; }

# --- catcher: routes files by header ---
zbox_catch() {
    local file="$1"
    [[ ! -f $file ]] && return 1

    local header
    header=$(head -n 1 "$file")

    case "$header" in
    \#zBOX:CORE*)
        cp "$file" "$zBOX_CONFIG/"
        zbox_log "loaded config $(basename "$file")"
        ;;
    \#zBOX:BIN*)
        cp "$file" "$zBOX_DIR/bin/"
        chmod +x "$zBOX_DIR/bin/$(basename "$file")"
        zbox_log "installed bin $(basename "$file")"
        ;;
    *)
        zbox_log "ignored $file (unknown header)"
        ;;
    esac
}

# --- load all configs ---
zbox_load() {
    [[ $zBOX_ENABLED -eq 0 ]] && return
    for cfg in "$zBOX_CONFIG"/*; do
        [[ -f $cfg ]] && source "$cfg"
    done
}
