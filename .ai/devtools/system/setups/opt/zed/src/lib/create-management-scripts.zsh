#!/usr/bin/env zsh
# Pure Rust Zed Editor - Zed Management Script Creation

# Create management scripts
create_management_scripts() {
    log_step "Creating management scripts..."
    
    # Create uninstall script
    cat > "$ZED_INSTALL_DIR/uninstall.zsh" << EOF
#!/usr/bin/env zsh

print "${colors[yellow]}🗑️  Uninstalling Zed from $ZED_INSTALL_DIR...${colors[reset]}"

# Remove symlink
rm -f "/usr/local/bin/$ZED_LAUNCHER_NAME"

# Remove desktop entry
rm -f "/usr/share/applications/zed.desktop"

# Remove installation directory
rm -rf "$ZED_INSTALL_DIR"

print "${colors[green]}✅ Zed uninstalled successfully${colors[reset]}"
EOF

    chmod +x "$ZED_INSTALL_DIR/uninstall.zsh"
    
    # Create update script
    cat > "$ZED_INSTALL_DIR/update.zsh" << EOF
#!/usr/bin/env zsh

print "${colors[cyan]}🔄 Updating Zed...${colors[reset]}"

# Backup current binary
cp "$ZED_INSTALL_DIR/$ZED_BINARY_NAME" "$ZED_INSTALL_DIR/${ZED_BINARY_NAME}.backup"

# Re-run installer with same config
export ZED_INSTALL_DIR="$ZED_INSTALL_DIR"
export ZED_CONFIG_DIR="$ZED_CONFIG_DIR"
export ZED_BINARY_NAME="$ZED_BINARY_NAME"
export ZED_LAUNCHER_NAME="$ZED_LAUNCHER_NAME"
export ZED_BUILD_PROFILE="$ZED_BUILD_PROFILE"
export ZED_USE_PREBUILT="$ZED_USE_PREBUILT"

# Re-install (this script should be run with sudo)
exec "\$(dirname "\$0")/install.zsh"
EOF

    chmod +x "$ZED_INSTALL_DIR/update.zsh"
    
    # Create info script
    cat > "$ZED_INSTALL_DIR/info.zsh" << EOF
#!/usr/bin/env zsh

typeset -A colors
colors[cyan]='\033[0;36m'
colors[green]='\033[0;32m'
colors[yellow]='\033[0;33m'
colors[bold]='\033[1m'
colors[reset]='\033[0m'

print "${colors[bold]}Zed Installation Info${colors[reset]}"
print "━━━━━━━━━━━━━━━━━━━━━━━━━"
print "Install Directory: ${colors[green]}$ZED_INSTALL_DIR${colors[reset]}"
print "Config Directory:  ${colors[green]}$ZED_CONFIG_DIR${colors[reset]}"
print "Binary:           ${colors[green]}$ZED_INSTALL_DIR/$ZED_BINARY_NAME${colors[reset]}"
print "Launcher:         ${colors[green]}/usr/local/bin/$ZED_LAUNCHER_NAME${colors[reset]}"
print ""
print "${colors[bold]}Management${colors[reset]}"
print "Update:    ${colors[cyan]}sudo $ZED_INSTALL_DIR/update.zsh${colors[reset]}"
print "Uninstall: ${colors[yellow]}sudo $ZED_INSTALL_DIR/uninstall.zsh${colors[reset]}"
print ""
print "${colors[bold]}Usage${colors[reset]}"
print "Launch:         ${colors[cyan]}$ZED_LAUNCHER_NAME${colors[reset]}"
print "Open project:   ${colors[cyan]}$ZED_LAUNCHER_NAME /path/to/project${colors[reset]}"
print "Open file:      ${colors[cyan]}$ZED_LAUNCHER_NAME file.rs${colors[reset]}"
print ""
print "${colors[bold]}Configuration${colors[reset]}"
print "Settings: ${colors[green]}$ZED_CONFIG_DIR/settings.json${colors[reset]}"
print "Keybinds: ${colors[green]}$ZED_CONFIG_DIR/keymap.json${colors[reset]}"
print "Tasks:    ${colors[green]}$ZED_CONFIG_DIR/tasks.json${colors[reset]}"
EOF

    chmod +x "$ZED_INSTALL_DIR/info.zsh"
    
    log_success "Management scripts created"
}
