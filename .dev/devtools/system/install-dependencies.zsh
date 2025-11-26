# Pure Rust Zed Editor - Zed Install Dependencies

# Detect OS and set package manager
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="${VERSION_ID:-rolling}"
    else
        log_error "Cannot detect OS - /etc/os-release not found"
        return 1
    fi
    
    log_info "Detected OS: $OS_ID $OS_VERSION"
    
    # Set package manager commands
    case "$OS_ID" in
        alpine)
            PKG_UPDATE=(apk update)
            PKG_INSTALL=(apk add --no-cache)
            ;;
        ubuntu|debian|linuxmint|pop)
            PKG_UPDATE=(apt-get update)
            PKG_INSTALL=(apt-get install -y)
            ;;
        rocky|centos|rhel|fedora|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                PKG_UPDATE=(dnf makecache --refresh)
                PKG_INSTALL=(dnf install -y)
            else
                PKG_UPDATE=(yum makecache)
                PKG_INSTALL=(yum install -y)
            fi
            ;;
        arch|manjaro|endeavouros)
            PKG_UPDATE=(pacman -Sy)
            PKG_INSTALL=(pacman -S --noconfirm --needed)
            ;;
        opensuse*|sles)
            PKG_UPDATE=(zypper refresh)
            PKG_INSTALL=(zypper install -y)
            ;;
        *)
            log_error "Unsupported OS: $OS_ID"
            log_info "Supported OS: Alpine, Ubuntu/Debian, RHEL/Fedora, Arch, openSUSE"
            return 1
            ;;
    esac
    
    return 0
}

# Check if running as root (not recommended)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root is not recommended for this script"
        log_prompt "Continue anyway? [y/N] " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            log_info "Exiting..."
            return 1
        fi
    fi
    return 0
}

# Check if sudo is available and working
check_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        log_error "sudo is required but not found"
        return 1
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        log_info "Sudo access required for package installation"
        if ! sudo true; then
            log_error "Failed to obtain sudo access"
            return 1
        fi
    fi
    
    return 0
}

# Install system dependencies
install_dependencies() {
    log_step "Installing system dependencies..."
    
    # Detect OS first
    if ! detect_os; then
        return 1
    fi
    
    # Check prerequisites
    if ! check_root || ! check_sudo; then
        return 1
    fi
    
    # Update package manager
    log_info "Updating package manager..."
    if ! sudo "${PKG_UPDATE[@]}"; then
        log_error "Failed to update package manager"
        return 1
    fi
    
    # Define dependencies per OS
    local base_deps build_deps lib_deps
    
    case "$OS_ID" in
        alpine)
            base_deps=(curl wget git zsh clang)
            build_deps=(build-base cmake pkgconf)
            lib_deps=(fontconfig-dev freetype-dev libx11-dev libxcb-dev openssl-dev)
            ;;
        ubuntu|debian|linuxmint|pop)
            base_deps=(curl wget git zsh clang)
            build_deps=(build-essential cmake pkg-config)
            lib_deps=(libfontconfig1-dev libfreetype6-dev libx11-dev libxcb1-dev libxkbcommon-dev libssl-dev)
            ;;
        rocky|centos|rhel|fedora|almalinux)
            base_deps=(curl wget git zsh clang)
            build_deps=(gcc gcc-c++ make cmake pkg-config)
            lib_deps=(fontconfig-devel freetype-devel libX11-devel libxcb-devel openssl-devel)
            ;;
        arch|manjaro|endeavouros)
            base_deps=(curl wget git zsh clang)
            build_deps=(base-devel cmake pkg-config)
            lib_deps=(fontconfig freetype2 libx11 libxcb openssl)
            ;;
        opensuse*|sles)
            base_deps=(curl wget git zsh clang)
            build_deps=(gcc gcc-c++ make cmake pkg-config)
            lib_deps=(fontconfig-devel freetype2-devel libX11-devel libxcb-devel libopenssl-devel)
            ;;
    esac
    
    # Add custom packages if defined
    if [[ -n "$ZED_PKG_LIB" ]]; then
        lib_deps+=($ZED_PKG_LIB)
    fi
    
    # Combine all dependencies
    local all_deps=($base_deps $build_deps $lib_deps)
    
    log_info "Installing packages: ${all_deps[*]}"
    if ! sudo "${PKG_INSTALL[@]}" "${all_deps[@]}"; then
        log_error "Failed to install system dependencies"
        return 1
    fi
    
    log_success "System dependencies installed successfully"
    return 0
}

# Install Rust toolchain
install_rust() {
    log_step "Setting up Rust toolchain..."
    
    # Set Rust environment variables
    export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
    export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
    export PATH="$CARGO_HOME/bin:$PATH"
    
    # Check if rustup exists
    if ! command -v rustup >/dev/null 2>&1; then
        log_info "Installing rustup to $CARGO_HOME..."
        
        # Download and install rustup
        if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path; then
            log_error "Failed to install rustup"
            return 1
        fi
        
        # Source the environment
        if [[ -f "$CARGO_HOME/env" ]]; then
            source "$CARGO_HOME/env"
        else
            log_error "Cargo environment file not found after installation"
            return 1
        fi
    else
        log_info "Rustup already installed: $(rustup --version)"
    fi
    
    # Verify rustup is accessible
    if ! command -v rustup >/dev/null 2>&1; then
        log_error "rustup not found in PATH after installation"
        return 1
    fi
    
    # Update to latest stable toolchain
    log_info "Updating to latest stable Rust toolchain..."
    if ! rustup update stable; then
        log_error "Failed to update Rust toolchain"
        return 1
    fi
    
    if ! rustup default stable; then
        log_error "Failed to set stable as default toolchain"
        return 1
    fi
    
    # Install rust-analyzer component
    log_info "Installing rust-analyzer component..."
    if ! rustup component add rust-analyzer; then
        log_warning "Failed to install rust-analyzer component (may not be critical)"
    fi
    
    # Verify installation
    local rust_version
    rust_version=$(rustc --version 2>/dev/null)
    if [[ -n "$rust_version" ]]; then
        log_success "Rust toolchain configured successfully: $rust_version"
        log_info "Cargo home: $CARGO_HOME"
    else
        log_error "Failed to verify Rust installation"
        return 1
    fi
    
    return 0
}

# Install all dependencies (convenience function)
install_all_dependencies() {
    log_step "Installing all dependencies for Zed..."
    
    if ! install_dependencies; then
        log_error "Failed to install system dependencies"
        return 1
    fi
    
    if ! install_rust; then
        log_error "Failed to install Rust toolchain"
        return 1
    fi
    
    log_success "All dependencies installed successfully"
    return 0
}

# Mark as loaded
DEPS_COMP=1
