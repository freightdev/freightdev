#!/bin/zsh
##################################
# Master Environment Loader
##################################

# ===================================
# STEP 1: BOOTSTRAP BASE PATHS
# ===================================
ZBOX_DIR="${HOME}/.zbox"
ZBOX_CFG="${ZBOX_DIR}/config"
ZBOX_SRC="${ZBOX_DIR}/source"
LOADER_NAME="zshrc"
LOADER_RSRC="${HOME}/.${LOADER_NAME}"

# ===================================
# STEP 2: CONDITIONAL LOADING
# ===================================
if [[ -f "${ZBOX_CFG}/loader.zsh" ]]; then
    . "${ZBOX_CFG}/loader.zsh"
else
    echo "ERROR: Config loader not found at ${ZBOX_CFG}/loader.zsh" >&2
    return 1
fi

if [[ -f "${ZBOX_SRC}/loader.zsh" ]]; then
    . "${ZBOX_SRC}/loader.zsh"
else
    echo "ERROR: Source loader not found at ${ZBOX_SRC}/loader.zsh" >&2
    return 1
fi
