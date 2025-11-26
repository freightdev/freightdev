# Pure Rust Zed Editor - Zed Configuration Utilities

# Zed Paths - Configs
: "${ZED_INSTALL_DIR:=$HOME/.zed/zed}"
: "${ZED_TMP_DIR:=$HOME/tmp}"

# Zed Customs - Configs
: "${ZED_BINARY_NAME:=zed}"
: "${ZED_LAUNCHER_NAME:=zed}"
: "${ZED_USE_PREBUILT:=false}"

# Zed Repos - Configs
: "${ZED_REPO_URL:=https://github.com/zed-industries/zed.git}"

# Cargo Paths - Configs
: "${RUSTUP_HOME:=$HOME/.rustup}"
: "${CARGO_HOME:=$HOME/.cargo}"
: "${CARGO_ENV_PATH:=$CARGO_HOME/env}"

# Update PATH only if cargo bin not already in path
if [[ ":$PATH:" != *":$CARGO_HOME/bin:"* ]]; then
    export PATH="$CARGO_HOME/bin:$PATH"
fi

# Cargo Flags - Configs
: "${ZED_CARGO_BUILD:=release}"
: "${ZED_CARGO_JOBS:=8}"

# Extra package libraries for custom uses
# Add or Remove for your specific hardware features
# ZED_PKG_LIB=(vulkan-tools vulkan-intel)

# Export important variables
export ZED_INSTALL_DIR ZED_TMP_DIR ZED_CONFIG_DIR
export ZED_BINARY_NAME ZED_LAUNCHER_NAME ZED_USE_PREBUILT
export ZED_REPO_URL
export RUSTUP_HOME CARGO_HOME CARGO_ENV_PATH
export ZED_CARGO_BUILD ZED_CARGO_JOBS

# Mark as loaded
CONFIG_COMP=1
