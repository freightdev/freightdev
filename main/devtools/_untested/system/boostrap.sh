#!/bin/bash
# bootstrap.sh - Master system bootstrap script
# Orchestrates all utilities to set up a new system

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$SCRIPT_DIR/../config}"
BOOTSTRAP_CONFIG="${BOOTSTRAP_CONFIG:-$CONFIG_DIR/bootstrap.yaml}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_section() { echo -e "\n${MAGENTA}╔════════════════════════════════════════════════╗${NC}"; echo -e "${MAGENTA}║${NC}  $*"; echo -e "${MAGENTA}╚════════════════════════════════════════════════╝${NC}\n"; }
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $*"; }

# Check if running with appropriate privileges
check_privileges() {
    if [ "$EUID" -eq 0 ]; then
        log_warn "Running as root. Some operations may not work correctly."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
}

# Display banner
show_banner() {
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   ██████╗  ██████╗  ██████╗ ████████╗███████╗████████╗   ║
║   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝╚══██╔══╝   ║
║   ██████╔╝██║   ██║██║   ██║   ██║   ███████╗   ██║      ║
║   ██╔══██╗██║   ██║██║   ██║   ██║   ╚════██║   ██║      ║
║   ██████╔╝╚██████╔╝╚██████╔╝   ██║   ███████║   ██║      ║
║   ╚═════╝  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝   ╚═╝      ║
║                                                          ║
║              System Bootstrap & Configuration            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
}

# Step 1: System detection
detect_system() {
    log_section "STEP 1: System Detection"
    
    log_step "Detecting operating system and package manager..."
    eval "$(bash "${SCRIPT_DIR}/identify_package_manager.sh" shell)"
    
    if [ -z "$PKG_MGR" ]; then
        log_error "Could not detect package manager!"
        exit 1
    fi
    
    log_info "System: $OS_TYPE ($OS_VERSION)"
    log_info "Package Manager: $PKG_MGR"
    log_info "Needs Sudo: $NEEDS_SUDO"
    
    export PKG_MGR OS_TYPE OS_VERSION INSTALL_CMD UPDATE_CMD
}

# Step 2: Install dependencies
install_dependencies() {
    log_section "STEP 2: Installing Dependencies"
    
    local dep_config="${CONFIG_DIR}/dependencies.yaml"
    
    if [ ! -f "$dep_config" ]; then
        log_warn "Dependencies config not found: $dep_config"
        log_info "Skipping dependency installation"
        return 0
    fi
    
    log_step "Installing system dependencies..."
    bash "${SCRIPT_DIR}/install_dependencies.sh" -c "$dep_config"
}

# Step 3: Clone repositories
clone_repositories() {
    log_section "STEP 3: Cloning Repositories"
    
    local repo_config="${CONFIG_DIR}/repositories.yaml"
    
    if [ ! -f "$repo_config" ]; then
        log_warn "Repository config not found: $repo_config"
        log_info "Skipping repository cloning"
        return 0
    fi
    
    local dest_dir="${HOME}/projects"
    
    log_step "Cloning git repositories to: $dest_dir"
    bash "${SCRIPT_DIR}/collect_git_repos.sh" -c "$repo_config" -d "$dest_dir"
}

# Step 4: Setup dotfiles
setup_dotfiles() {
    log_section "STEP 4: Setting Up Dotfiles"
    
    local dotfiles_config="${CONFIG_DIR}/dotfiles.yaml"
    
    if [ ! -f "$dotfiles_config" ]; then
        log_warn "Dotfiles config not found: $dotfiles_config"
        log_info "Skipping dotfile setup"
        return 0
    fi
    
    log_step "Creating symlinks for dotfiles..."
    bash "${SCRIPT_DIR}/setup_dotfiles.sh" -c "$dotfiles_config" -f
}

# Step 5: Run custom scripts
run_custom_scripts() {
    log_section "STEP 5: Running Custom Scripts"
    
    local custom_dir="${CONFIG_DIR}/custom_scripts"
    
    if [ ! -d "$custom_dir" ]; then
        log_info "No custom scripts directory found"
        return 0
    fi
    
    log_step "Executing custom scripts..."
    
    for script in "$custom_dir"/*.sh; do
        if [ -f "$script" ]; then
            log_info "Running: $(basename "$script")"
            bash "$script" || log_warn "Script failed: $(basename "$script")"
        fi
    done
}

# Step 6: Final setup
final_setup() {
    log_section "STEP 6: Final Configuration"
    
    log_step "Setting up shell environment..."
    
    # Ensure directories exist
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    
    # Add local bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_info "Adding ~/.local/bin to PATH"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    
    log_info "✓ Environment configured"
}

# Main bootstrap flow
main() {
    local skip_deps=false
    local skip_repos=false
    local skip_dotfiles=false
    local skip_custom=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-deps)
                skip_deps=true
                shift
                ;;
            --skip-repos)
                skip_repos=true
                shift
                ;;
            --skip-dotfiles)
                skip_dotfiles=true
                shift
                ;;
            --skip-custom)
                skip_custom=true
                shift
                ;;
            -h|--help)
                cat << EOF
Usage: $0 [OPTIONS]

Bootstrap a new system with automated setup.

Options:
    --skip-deps        Skip dependency installation
    --skip-repos       Skip repository cloning
    --skip-dotfiles    Skip dotfile setup
    --skip-custom      Skip custom scripts
    -h, --help         Show this help

Configuration:
    Place config files in: $CONFIG_DIR
    - bootstrap.yaml     Main config
    - dependencies.yaml  Package list
    - repositories.yaml  Git repos
    - dotfiles.yaml      Dotfile mappings
    - custom_scripts/    Additional setup scripts

Environment Variables:
    CONFIG_DIR         Override config directory
    BOOTSTRAP_CONFIG   Override main config file
EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Show banner
    clear
    show_banner
    
    log_info "Starting bootstrap process..."
    log_info "Config directory: $CONFIG_DIR"
    echo ""
    
    # Check privileges
    check_privileges
    
    # Execute bootstrap steps
    detect_system
    
    [ "$skip_deps" = false ] && install_dependencies
    [ "$skip_repos" = false ] && clone_repositories
    [ "$skip_dotfiles" = false ] && setup_dotfiles
    [ "$skip_custom" = false ] && run_custom_scripts
    
    final_setup
    
    # Completion
    log_section "Bootstrap Complete! 🎉"
    
    cat << EOF
${GREEN}✓${NC} System bootstrap completed successfully!

${CYAN}Next steps:${NC}
  1. Restart your shell or run: source ~/.bashrc
  2. Verify installations: which git node python
  3. Check your dotfiles are linked correctly
  4. Review logs above for any warnings

${YELLOW}Note:${NC} Some changes may require a logout/login or system restart.

${MAGENTA}Happy hacking!${NC}
EOF
}

# Run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
