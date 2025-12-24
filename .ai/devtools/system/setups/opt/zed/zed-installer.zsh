#!/usr/bin/env zsh
# Pure Rust Zed Editor Installation Script - Zsh Style

ZED_SRC_DIR=$(pwd)/src
ZED_MAIN_SETUP=$ZED_SRC_DIR/main.zsh

# Check for source directory
if [[ ! -d "$ZED_SRC_DIR" ]]; then
    print "Source directory not found: $ZED_SRC_DIR"
    exit 1
fi

# Setup Zed Installer
setup_zed() {
    if [[ ! -f "$ZED_MAIN_SETUP" ]]; then
        print "Main source not found: $ZED_MAIN_SETUP"
        exit 1
    fi

    source "$ZED_MAIN_SETUP"
    main
}

# Begin Zed Setup
setup_zed
