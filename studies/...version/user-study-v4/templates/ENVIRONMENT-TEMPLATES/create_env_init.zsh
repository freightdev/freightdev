# ~/.zbox/init.zsh
# Main entrypoint for ZBox


ZBOX_DIR="$HOME/.zbox"
ZBOX_CONFIG="$ZBOX_DIR/config"
ZBOX_ENABLED=1   # master switch

# --- core helpers ---
zbox_log() { print -P "%F{cyan}[ZBOX]%f $*"; }
zbox_on()  { ZBOX_ENABLED=1; zbox_log "enabled"; }
zbox_off() { ZBOX_ENABLED=0; zbox_log "disabled"; }

# --- catcher: routes files by header ---
zbox_catch() {
  local file="$1"
  [[ ! -f $file ]] && return 1

  local header
  header=$(head -n 1 "$file")

  case "$header" in
    \#ZBOX:CONFIG*)
      cp "$file" "$ZBOX_CONFIG/"
      zbox_log "loaded config $(basename "$file")"
      ;;
    \#ZBOX:BIN*)
      cp "$file" "$ZBOX_DIR/bin/"
      chmod +x "$ZBOX_DIR/bin/$(basename "$file")"
      zbox_log "installed bin $(basename "$file")"
      ;;
    *)
      zbox_log "ignored $file (unknown header)"
      ;;
  esac
}

# --- load all configs ---
zbox_load() {
  [[ $ZBOX_ENABLED -eq 0 ]] && return
  for cfg in "$ZBOX_CONFIG"/*; do
    [[ -f $cfg ]] && source "$cfg"
  done
}
