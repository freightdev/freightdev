# Pure Rust Zed Editor - Zed Prebuilt Binary Code Source
# Download prebuilt binary if available
try_prebuilt() {
    if [[ "$ZED_USE_PREBUILT" != "true" ]]; then
        return 1
    fi
    
    # Validate required variables
    if [[ -z "$ZED_TMP_DIR" || -z "$ZED_INSTALL_DIR" || -z "$ZED_BINARY_NAME" ]]; then
        log_error "Missing required environment variables"
        return 1
    fi
    
    local arch os
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    # Only try prebuilt for supported architectures
    if [[ "$arch" != "x86_64" ]]; then
        log_warning "Prebuilt binaries not available for $arch"
        return 1
    fi
    
    # Only try prebuilt for Linux (adjust as needed)
    if [[ "$os" != "linux" ]]; then
        log_warning "Prebuilt binaries not available for $os"
        return 1
    fi
    
    log_info "Attempting to download prebuilt binary for $os-$arch..."
    
    # Create temp directory
    local temp_dir
    temp_dir="$ZED_TMP_DIR/zed-prebuilt"
    
    if ! mkdir -p "$temp_dir"; then
        log_error "Failed to create temporary directory: $temp_dir"
        return 1
    fi
    
    # Store current directory
    local original_dir
    original_dir="$(pwd)"
    
    # Try official releases
    local latest_url
    log_info "Fetching latest release information..."
    
    if ! latest_url=$(curl -fsSL --max-time 30 https://api.github.com/repos/zed-industries/zed/releases/latest 2>/dev/null | \
        grep "browser_download_url.*linux.*tar.gz" | \
        cut -d '"' -f 4 | head -1); then
        log_error "Failed to fetch release information"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    if [[ -z "$latest_url" ]]; then
        log_warning "No suitable prebuilt binary found for $os-$arch"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    log_info "Downloading prebuilt Zed from: $latest_url"
    
    # Download the archive
    if ! curl -fsSL --max-time 300 "$latest_url" -o "$temp_dir/zed.tar.gz"; then
        log_error "Failed to download prebuilt binary"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    # Change to temp directory safely
    if ! cd "$temp_dir"; then
        log_error "Failed to change to temporary directory"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    # Extract the archive
    log_info "Extracting archive..."
    if ! tar -xzf zed.tar.gz 2>/dev/null; then
        log_error "Failed to extract archive"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    # Find the binary
    log_info "Locating Zed binary..."
    local binary_path
    binary_path=$(find . -name "zed" -type f -executable 2>/dev/null | head -1)
    
    if [[ -z "$binary_path" ]]; then
        log_error "Zed binary not found in extracted files"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    log_info "Found binary at: $binary_path"
    
    # Create install directory
    if ! mkdir -p "$ZED_INSTALL_DIR"; then
        log_error "Failed to create install directory: $ZED_INSTALL_DIR"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    # Install the binary
    if ! cp "$binary_path" "$ZED_INSTALL_DIR/$ZED_BINARY_NAME"; then
        log_error "Failed to install binary"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    # Set executable permissions
    chmod +x "$ZED_INSTALL_DIR/$ZED_BINARY_NAME"
    
    # Verify installation
    if [[ ! -x "$ZED_INSTALL_DIR/$ZED_BINARY_NAME" ]]; then
        log_error "Binary installation verification failed"
        cleanup_temp_dir "$temp_dir" "$original_dir"
        return 1
    fi
    
    # Cleanup and return to original directory
    cd "$original_dir"
    rm -rf "$temp_dir"
    
    log_success "Prebuilt binary installed successfully to: $ZED_INSTALL_DIR/$ZED_BINARY_NAME"
    return 0
}

# Helper function for cleanup
cleanup_temp_dir() {
    local temp_dir="$1"
    local original_dir="$2"
    
    if [[ -n "$original_dir" ]]; then
        cd "$original_dir" 2>/dev/null
    fi
    
    if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
        rm -rf "$temp_dir" 2>/dev/null
    fi
}
