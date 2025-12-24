# Pure Rust Zed Editor - Zed Logging Utilities

# Colors for output
typeset -Ag colors
colors[red]='\033[0;31m'
colors[green]='\033[0;32m'
colors[yellow]='\033[0;33m'
colors[blue]='\033[0;34m'
colors[purple]='\033[0;35m'
colors[cyan]='\033[0;36m'
colors[white]='\033[0;37m'
colors[bold]='\033[1m'
colors[reset]='\033[0m'

# Logging functions
log_prompt() {
    print -n "${colors[purple]} $1${color[reset]}"
    read "$2"
}
log_info() {
    print "${colors[cyan]} $1${colors[reset]}"
}

log_success() {
    print "${colors[green]} $1${colors[reset]}"
}

log_warning() {
    print "${colors[yellow]} $1${colors[reset]}"
}

log_error() {
    print "${colors[red]} $1${colors[reset]}"
}

log_step() {
    print "${colors[blue]}${colors[bold]} $1${colors[reset]}"
}

# Print configuration
print_config() {
    log_info "Installation Configuration:"
    print "  Install Directory: ${colors[bold]}$ZED_INSTALL_DIR${colors[reset]}"
    print "  Config Directory:  ${colors[bold]}$ZED_CONFIG_DIR${colors[reset]}"
    print "  Binary Name:       ${colors[bold]}$ZED_BINARY_NAME${colors[reset]}"
    print "  Launcher Name:     ${colors[bold]}$ZED_LAUNCHER_NAME${colors[reset]}"
    print "  Cargo Build:       ${colors[bold]}$ZED_CARGO_BUILD${colors[reset]}"
    print "  Use Prebuilt:      ${colors[bold]}$ZED_USE_PREBUILT${colors[reset]}"
    print ""
}

# Mark as loaded
LOGGING_COMP=1
