# Pure Rust Zed Editor - Zed Main Setup Source

# Completion tracking
typeset -gA ZED_LOADED
typeset -gA ZED_COMPLETED
typeset -gA ZED_LOADED_HASH

# Load and track helper/lib/option files
__zed_load_sources() {
    local dirs=("$ZED_SRC_DIR/util" "$ZED_SRC_DIR/lib" "$ZED_SRC_DIR/option")
    local file file_hash comp_var
    
    # Initialize associative arrays if not already declared
    [[ ${+ZED_LOADED} -eq 0 ]] && typeset -gA ZED_LOADED
    [[ ${+ZED_LOADED_HASH} -eq 0 ]] && typeset -gA ZED_LOADED_HASH
    [[ ${+ZED_COMPLETED} -eq 0 ]] && typeset -gA ZED_COMPLETED

    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || continue

        for file in "$dir"/*.zsh(N.); do
            [[ -f "$file" && -r "$file" ]] || continue

            if command -v md5sum >/dev/null 2>&1; then
                file_hash=$(md5sum "$file" | awk '{print $1}')
            else
                file_hash=$(md5 -q "$file")
            fi

            base_name="${file:t:r}"
            safe_name="${base_name//-/_}"
            comp_var="${safe_name}_COMP"

            if [[ -z "${ZED_LOADED[$file]}" || "${ZED_LOADED_HASH[$file]}" != "$file_hash" ]]; then
                source "$file"
                ZED_LOADED[$file]=1
                ZED_LOADED_HASH[$file]="$file_hash"
                ZED_COMPLETED[$file]=1

                # Set marker variable safely
                : ${(P)comp_var::=1}
            fi
        done
    done
}

# Install Zed Binary
install_zed() {
    log_step "Installing Zed..."

    if ! try_prebuilt; then
        if ! build_source; then
            log_error "Failed to build Zed from source"
            return 1
        fi
    fi

    if [[ -x "$ZED_INSTALL_DIR/$ZED_BINARY_NAME" ]]; then
        log_success "Zed binary installed at $ZED_INSTALL_DIR/$ZED_BINARY_NAME"
        return 0
    else
        log_error "Failed to install Zed binary"
        return 1
    fi

    cleanup_tmp_dir    
}

# Main installation function
main() {
    # Load all source files
    __zed_load_sources
    
    # Display banner
    print "${colors[bold]}${colors[purple]}"
    print "╔══════════════════════════════════════════╗"
    print "║        Zed Editor Installer (Rust)       ║"
    print "║            Pure Zsh Edition              ║"
    print "╚══════════════════════════════════════════╝"
    print "${colors[reset]}"
    print ""
    
    # Display configuration
    print_config
    print ""
    
    # Simple prompt - no counter nonsense
    log_prompt "Proceed with installation? (y/N)" response
    
    case "$response" in
        [yY])
            log_info "Starting installation..."
            ;;
        *)
            log_info "Installation cancelled"
            return 0
            ;;
    esac
    
    print ""
    
    # Run installation steps
    detect_os || return 1
    install_dependencies || return 1
    install_rust || return 1
    install_zed || return 1
    
    # Optional steps (non-critical)
    create_launcher || log_warning "Launcher creation failed (non-critical)"
    create_management_scripts || log_warning "Management scripts creation failed (non-critical)"
    
    # Success message
    print ""
    log_success "🎉 Zed installation complete!"
    print ""
    print "${colors[bold]}📍 Installation Summary${colors[reset]}"
    print "  Directory: ${colors[green]}$ZED_INSTALL_DIR${colors[reset]}"
    print "  Command:   ${colors[cyan]}$ZED_LAUNCHER_NAME${colors[reset]}"
    print "  Config:    ${colors[yellow]}$ZED_CONFIG_DIR${colors[reset]}"
    print ""
    print "${colors[bold]}💡 Quick Start${colors[reset]}"
    print "  ${colors[cyan]}$ZED_LAUNCHER_NAME${colors[reset]}                    # Open Zed"
    print "  ${colors[cyan]}$ZED_LAUNCHER_NAME ~/workspace${colors[reset]}       # Open workspace"
    print "  ${colors[cyan]}$ZED_LAUNCHER_NAME main.rs${colors[reset]}          # Open Rust file"
    print ""
    print "${colors[bold]}🔧 Management${colors[reset]}"
    print "  ${colors[yellow]}$ZED_INSTALL_DIR/info.zsh${colors[reset]}     # Show info"
    print "  ${colors[cyan]}$ZED_INSTALL_DIR/update.zsh${colors[reset]}   # Update Zed"
    print "  ${colors[red]}$ZED_INSTALL_DIR/uninstall.zsh${colors[reset]} # Uninstall"
    print ""
    
    return 0
}

# Mark main as loaded
MAIN_LOADED=1
