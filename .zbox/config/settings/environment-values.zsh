##################
# ZBOX Default Values
##################

# 1. Define the base directory first.
BASE_DIR="$HOME"

# 2. Define the main ZBOX Directory and its components.
#    Use direct assignment to ensure they are set every time this script runs.
ZBOX_DIR="$BASE_DIR/.zbox"
ZBOX_SRC="$ZBOX_DIR/source"
ZBOX_CFG="$ZBOX_DIR/config"
ZBOX_BIN="$ZBOX_DIR/.bin"
ZBOX_PROFILES="$ZBOX_DIR/profiles"
ZBOX_TOOLS="$ZBOX_DIR/tools"
ZBOX_CRATES="$ZBOX_DIR/crates"
ZBOX_APPS="$ZBOX_DIR/apps"
ZBOX_PLUGINS="$ZBOX_DIR/plugins"
ZBOX_RESOURCES="$ZBOX_DIR/resources"
ZBOX_SERVICES="$ZBOX_DIR/services"
ZBOX_AI="$ZBOX_DIR/.ai"

# 3. Export the main directories.
#    Exporting makes them available to any script or program executed
#    from the shell (like helper scripts or background processes).
export ZBOX_DIR
export ZBOX_SRC
export ZBOX_CFG
export ZBOX_BIN
export ZBOX_PROFILES
export ZBOX_TOOLS
export ZBOX_CRATES
export ZBOX_APPS
export ZBOX_PLUGINS
export ZBOX_RESOURCES
export ZBOX_SERVICES
export ZBOX_AI

# 4. Define the Loader Configs using the set paths.
LOADER_NAME="zshrc"
LOADER_RSRC="$BASE_DIR/.$LOADER_NAME"
LOADER_MARK="$ZBOX_SRC/loader.zsh"

# 5. zBoxxy Agent Paths
ZBOXXY_DIR="$ZBOX_AI/agents/zboxxy"
ZBOXXY_CONFIG="$ZBOXXY_DIR/config"
ZBOXXY_LOGS="$ZBOXXY_DIR/logs"
export ZBOXXY_DIR ZBOXXY_CONFIG ZBOXXY_LOGS
