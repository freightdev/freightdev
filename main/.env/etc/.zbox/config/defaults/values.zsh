#######################
# ZBOX Default Values
#######################

# 1. Define the base directory first.
BASE_DIR="$HOME"

# 2. Define the main ZBOX Directory and its components.
ZBOX_DIR="$BASE_DIR/.zbox"
ZBOX_CFG="$ZBOX_DIR/config"
ZBOX_SRC="$ZBOX_DIR/source"

# 3. Export the main directories.
export ZBOX_DIR
export ZBOX_CFG
export ZBOX_SRC

# 4. Define the Loader Configs using the set paths.
LOADER_NAME="zshrc"
LOADER_RSRC="$BASE_DIR/.$LOADER_NAME"
