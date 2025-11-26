# Pure Rust Zed Editor - Zed Source Builder
# Build Zed from source
build_source() {
    local install_dir build_dir repo_url build bin jobs env 
    install_dir="${ZED_INSTALL_DIR}"
    build_dir="${ZED_TMP_DIR}/zed"
    repo_url="${ZED_REPO_URL}"
    build="${ZED_CARGO_BUILD}"
    bin="${ZED_BINARY_NAME}"
    jobs="${ZED_CARGO_JOBS}"
    env="${CARGO_ENV_PATH}"
    
    # Validate required variables
    if [[ -z "$install_dir" || -z "$build_dir" || -z "$repo_url" || -z "$env" ]]; then
        log_error "Missing required environment variables"
        return 1
    fi
    
    # Handle existing build directory
    if [[ -d "$build_dir" ]]; then
        log_warning "Existing *ZED CLONE* detected: $build_dir"
        log_prompt "Would you like to remove and clone fresh? [Y/n] " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ || -z "$CONFIRM" ]]; then
            log_info "Removing existing build directory..."
            rm -rf "$build_dir"
        else
            log_info "Using existing build directory..."
        fi
    fi
    
    # Create build directory if it doesn't exist
    if [[ ! -d "$build_dir" ]]; then
        log_step "Building Zed from source..."
        mkdir -p "$build_dir"
        
        log_info "Cloning Zed repository..."
        if ! git clone --depth 1 "$repo_url" "$build_dir"; then
            log_error "Failed to clone repository"
            return 1
        fi
    fi
    
    # Change to build directory
    if ! cd "$build_dir"; then
        log_error "Failed to change to build directory: $build_dir"
        return 1
    fi
    
    log_info "Building Zed (this may take 10-30 minutes)..."
    
    # Set Rust environment
    if [[ -f "$env" ]]; then
        source "$env"
    else
        log_warning "Cargo environment file not found: $env"
    fi
    
    # Build with specified profile
    log_info "Running cargo build with profile: $build"
    if ! cargo build --profile="$build" --jobs "$jobs" --bin "$bin"; then
        log_error "Cargo build failed"
        return 1
    fi
    
    # Determine binary location based on profile
    local binary_path
    if [[ "$build" == "release" ]]; then
        binary_path="target/release/$bin"
    else
        binary_path="target/$build/$bin"
    fi
    
    # Verify binary exists
    if [[ ! -f "$binary_path" ]]; then
        log_error "Binary not found at expected location: $binary_path"
        return 1
    fi
    
    # Install binary
    log_info "Installing binary to: $install_dir"
    if ! mkdir -p "$install_dir"; then
        log_error "Failed to create install directory: $install_dir"
        return 1
    fi
    
    if ! cp "$binary_path" "$install_dir/$bin"; then
        log_error "Failed to copy binary to install directory"
        return 1
    fi
    
    chmod +x "$install_dir/$bin"
    
    # Return to original directory before cleanup
    cd - > /dev/null
    
    # Optional cleanup (commented out for safety)
    log_info "Cleaning up build directory..."
    rm -rf "$build_dir"
    
    log_success "Zed built and installed from source to: $install_dir/$bin"
    return 0
}
