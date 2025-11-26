#!/bin/zsh
#############################
# ZBOX Master Environment Loader
# Hybrid approach: Always set paths, conditionally load functions
#############################

# ===================================
# STEP 1: BOOTSTRAP BASE PATHS
# These are ALWAYS set (lightweight, ensures correctness)
# ===================================
ZBOX_DIR="${HOME}/.zbox"
ZBOX_CFG="${ZBOX_DIR}/config"
ZBOX_SRC="${ZBOX_DIR}/source"
LOADER_NAME="zshrc"
LOADER_RSRC="${HOME}/.${LOADER_NAME}"
LOADER_MARK="${ZBOX_SRC}/loader.zsh"

# Export the paths so child processes and scripts can use them
export ZBOX_DIR ZBOX_CFG ZBOX_SRC LOADER_MARK LOADER_RSRC

# ===================================
# STEP 2: CONDITIONAL LOADING
# Only source heavy files if not already loaded in THIS shell
# Set ZBOX_FORCE_RELOAD=1 to force reload
# ===================================
# Check if a core function exists to determine if we need to load
# This is more reliable than checking an environment variable
if ! type zbox_load_manifest &>/dev/null || [[ -n "$ZBOX_FORCE_RELOAD" ]]; then

    # Load config loader (settings, aliases, exports, autoloads)
    if [[ -f "${ZBOX_CFG}/loader.zsh" ]]; then
        . "${ZBOX_CFG}/loader.zsh"
    else
        echo "ERROR: Config loader not found at ${ZBOX_CFG}/loader.zsh" >&2
        return 1
    fi

    # Load source loader (functions, helpers, agents, suites)
    if [[ -f "$LOADER_MARK" ]]; then
        . "$LOADER_MARK"
    else
        echo "ERROR: Source loader not found at $LOADER_MARK" >&2
        return 1
    fi

    # Mark as loaded with timestamp (per-shell, not exported to children)
    ZBOX_FUNCTIONS_LOADED="$(date +%s)"

    # Optional: Show load confirmation in debug mode
    [[ -n "$ZBOX_DEBUG" ]] && echo "[ZBOX] Environment loaded at $(date)"
fi

# ===================================
# STEP 3: MANIFEST LOADING
# Load profile-specific manifest for agent sandboxing
# ===================================
# Load manifest if not already loaded (or if forced)
# Check if ZBOX_CURRENT_PROFILE is set to see if manifest is loaded
if [[ -z "$ZBOX_CURRENT_PROFILE" ]] || [[ -n "$ZBOX_FORCE_RELOAD" ]]; then
    # Default to workspace profile if not specified
    ZBOX_PROFILE="${ZBOX_PROFILE:-workspace}"

    # Load manifest if function exists and manifest file exists
    if type zbox_load_manifest &>/dev/null; then
        if [[ -f "${ZBOX_PROFILES}/${ZBOX_PROFILE}/manifest.yaml" ]]; then
            zbox_load_manifest "$ZBOX_PROFILE" 2>/dev/null
        fi
    fi
fi

# ===================================
# STEP 4: COMPLETION
# ===================================
# Mark environment as ready
export ZBOX_READY="1"
