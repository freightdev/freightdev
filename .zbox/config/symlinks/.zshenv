#!/bin/zsh
###################################
# ZBOX Environment Initialization
# Loaded for ALL shell types
###################################

# Source the master environment loader
# This ensures zBox is available in interactive, login, and non-interactive shells
if [[ -f "${HOME}/.zbox/main.zsh" ]]; then
    . "${HOME}/.zbox/main.zsh"
fi

# Source cargo environment if it exists
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

## Add custom user overrides below
## These will persist across ZBOX updates
