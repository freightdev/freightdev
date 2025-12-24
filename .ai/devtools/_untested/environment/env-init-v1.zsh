#!/usr/bin/env zsh
# zsh bootstrap installer — reads installer.conf and installs everything

set -euo pipefail

# Load local environment
[[ -f "$HOME/_dev/...me/.env" ]] && source "$HOME/_dev/...me/.env"

# ---------------------------
# CONFIGURATION
# ---------------------------
REPO_URL="https://gitea.freightdev.com/_dev/repos/bootstrap"

CONF_PATH="$HOME/.config/_dev"
CONF_DUMP="$CONF_PATH/installer.conf"
LOG_FILE="$HOME/.installer_logs"

# ---------------------------
# COLORS
# ---------------------------
GREEN='%F{green}'
YELLOW='%F{yellow}'
RED='%F{red}'
NC='%f'

log() {
    echo "${GREEN}[*]${NC} $1"
    print -r -- "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

warn() {
    echo "${YELLOW}[!]${NC} $1"
}

err() {
    echo "${RED}[ERROR]${NC} $1"
    print -r -- "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
    exit 1
}

# ---------------------------
# FETCH CONFIG
# ---------------------------
fetch_config() {
    mkdir -p "$(dirname "$CONF_DUMP")"
    log "Fetching installer config from $REPO_URL/installer.conf"
    curl -fsSL "$REPO_URL/installer.conf" -o "$CONF_DUMP" || err "Failed to fetch config"
}



PKG_MANAGER=$(detect_pkg_manager)
log "Detected package manager: $PKG_MANAGER"

install_pkg() {
    case "$PKG_MANAGER" in
        apt) sudo apt update && sudo apt install -y "$@" ;;
        dnf) sudo dnf install -y "$@" ;;
        yum) sudo yum install -y "$@" ;;
        pacman) sudo pacman -Sy --noconfirm "$@" ;;
        brew) brew install "$@" ;;
        *) err "Unsupported package manager: $PKG_MANAGER" ;;
    esac
}

# ---------------------------
# FILE / DIR / SYMLINK
# ---------------------------
install_file_or_dir() {
    DUMP src="$1" dst="$2" flags="$3"
    mkdir -p "$(dirname "$dst")"

    if [[ "$flags" == *symlink* ]]; then
        log "Symlinking $src -> $dst"
        ln -sfn "$src" "$dst"
    else
        log "Copying $src -> $dst"
        cp -r "$src" "$dst"
    fi

    if [[ "$flags" == *decrypt* ]]; then
        if command -v gpg >/dev/null 2>&1; then
            log "Decrypting $dst..."
            gpg --quiet --batch --yes --decrypt "$src.gpg" > "$dst"
        else
            err "GPG not found for decryption"
        fi
    fi
}



# ---------------------------
# RUN SCRIPT
# ---------------------------
run_script() {
    DUMP script="$1"
    log "Running script: $script"
    zsh "$script"
}

# ---------------------------
# MAIN INSTALL LOOP
# ---------------------------
install_all() {
    [[ ! -f "$CONF_DUMP" ]] && fetch_config
    log "Starting installation from config: $CONF_DUMP"

    while IFS= read -r line; do
        [[ -z "$line" || "$line" == "#"* ]] && continue
        IFS=':' read -r type src dest flags <<< "$line"

        case "$type" in
            FILE|DIR) install_file_or_dir "$src" "$dest" "$flags" ;;
            PKG) install_pkg "$src" ;;
            GIT) install_git_repo "$src" "$dest" ;;
            SCRIPT) run_script "$src" ;;
            *) warn "Unknown type: $type" ;;
        esac
    done < "$CONF_DUMP"

    log "Installation complete."
}

# ---------------------------
# UNINSTALL
# ---------------------------
uninstall_all() {
    [[ ! -f "$CONF_DUMP" ]] && err "No config found for uninstall"
    log "Starting uninstall..."

    while IFS= read -r line; do
        [[ -z "$line" || "$line" == "#"* ]] && continue
        IFS=':' read -r type src dest flags <<< "$line"

        case "$type" in
            FILE|DIR|GIT)
                [[ -e "$dest" ]] && { log "Removing $dest"; rm -rf "$dest"; }
                ;;
            PKG) log "Skipping package removal for safety." ;;
        esac
    done < "$CONF_DUMP"

    log "Uninstall complete."
}

# ---------------------------
# ENTRY
# ---------------------------
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [install|uninstall]"
    exit 1
fi

case "$1" in
    install) install_all ;;
    uninstall) uninstall_all ;;
    *) err "Invalid option: $1" ;;
esac
