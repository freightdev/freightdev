#!/bin/bash
# setup_dotfiles.sh - Symlink dotfiles from config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config_reader.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Backup existing file
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        log_warn "Backing up existing file: $file -> $backup"
        mv "$file" "$backup"
        return 0
    fi
    return 1
}

# Create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local force="${3:-false}"
    
    # Expand home directory
    target="${target/#\~/$HOME}"
    source="${source/#\~/$HOME}"
    
    # Check if source exists
    if [ ! -e "$source" ]; then
        log_error "Source does not exist: $source"
        return 1
    fi
    
    # Create parent directory if needed
    local target_dir=$(dirname "$target")
    mkdir -p "$target_dir"
    
    # Handle existing target
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local current_link=$(readlink "$target")
            if [ "$current_link" = "$source" ]; then
                log_info "⊙ Already linked: $target"
                return 0
            fi
        fi
        
        if [ "$force" = "true" ]; then
            backup_file "$target"
            rm -f "$target"
        else
            log_warn "Target exists: $target (use --force to override)"
            return 1
        fi
    fi
    
    # Create symlink
    if ln -s "$source" "$target"; then
        log_info "✓ Linked: $target -> $source"
        return 0
    else
        log_error "✗ Failed to link: $target"
        return 1
    fi
}

# Setup from config
setup_from_config() {
    local config_file="${1:-dotfiles.yaml}"
    local force="${2:-false}"
    
    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi
    
    log_info "Setting up dotfiles from: $config_file"
    
    local linked=0
    local skipped=0
    local failed=0
    
    if command -v yq &> /dev/null; then
        local file_count=$(yq eval '.dotfiles | length' "$config_file" 2>/dev/null)
        
        if [ "$file_count" != "null" ] && [ "$file_count" -gt 0 ]; then
            for ((i=0; i<file_count; i++)); do
                local source=$(yq eval ".dotfiles[$i].source" "$config_file" 2>/dev/null)
                local target=$(yq eval ".dotfiles[$i].target" "$config_file" 2>/dev/null)
                
                if [ "$source" != "null" ] && [ "$target" != "null" ]; then
                    if create_symlink "$source" "$target" "$force"; then
                        ((linked++))
                    else
                        ((failed++))
                    fi
                fi
            done
        fi
    else
        log_error "yq required for dotfiles setup"
        return 1
    fi
    
    echo ""
    log_info "=== Dotfiles Summary ==="
    log_info "Linked: $linked"
    log_info "Skipped: $skipped"
    [ $failed -gt 0 ] && log_error "Failed: $failed" || log_info "Failed: $failed"
    
    return $failed
}

main() {
    local config_file="dotfiles.yaml"
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -h|--help)
                cat << EOF
Usage: $0 [OPTIONS]

Options:
    -c, --config FILE    Config file (default: dotfiles.yaml)
    -f, --force          Force overwrite existing files (creates backups)
    -h, --help           Show this help

Config format (YAML):
    dotfiles:
      - source: ~/dotfiles/.bashrc
        target: ~/.bashrc
      - source: ~/dotfiles/.vimrc
        target: ~/.vimrc
      - source: ~/dotfiles/config/nvim
        target: ~/.config/nvim
EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    setup_from_config "$config_file" "$force"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
