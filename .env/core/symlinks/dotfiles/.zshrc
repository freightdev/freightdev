#!/bin/zsh
#############################
# ZBOX Interactive Shell Init
# (Already loaded via .zshenv)
#############################

# Note: zBox is already loaded via .zshenv for all shell types
# This file is for interactive-only customizations

## Add interactive shell customizations below
## (aliases, functions, prompts that only make sense in interactive mode)

## Examples:
# alias ll='ls -lah'
# Custom prompt tweaks
# Interactive-only keybindings

# bun completions
[ -s "/home/admin/.bun/_bun" ] && source "/home/admin/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
