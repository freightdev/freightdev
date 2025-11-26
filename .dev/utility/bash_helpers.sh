#!/bin/bash
#
# bash-helpers.sh - Ultimate Bash Script Helper Library
# Source this file in your scripts: source helper.sh
#
# Features:
# - Colored output functions
# - Logging with timestamps and levels
# - Error handling and validation
# - Progress indicators
# - User interaction helpers
# - System checks and utilities
# - File and directory operations
#

# =============================================================================
# CONFIGURATION
# =============================================================================

# Default log file (can be overridden)
LOG_FILE="${LOG_FILE:-/tmp/script_$(date +%Y%m%d_%H%M%S).log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR
QUIET_MODE="${QUIET_MODE:-false}"
FORCE_MODE="${FORCE_MODE:-false}"

# =============================================================================
# COLORS AND FORMATTING
# =============================================================================

# Standard colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'  # No Color

# Background colors
readonly BG_RED='\033[41m'
readonly BG_GREEN='\033[42m'
readonly BG_YELLOW='\033[43m'
readonly BG_BLUE='\033[44m'

# Text formatting
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly UNDERLINE='\033[4m'
readonly BLINK='\033[5m'
readonly REVERSE='\033[7m'

# =============================================================================
# LOGGING AND OUTPUT FUNCTIONS
# =============================================================================

# Get timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log to file with level
log() {
    local level="$1"
    shift
    echo "[$(timestamp)] [$level] $*" >> "$LOG_FILE"
}

# Print with color and optional logging
print_msg() {
    local color="$1"
    local prefix="$2"
    local level="$3"
    shift 3
    local message="$*"
    
    [[ "$QUIET_MODE" == "true" ]] && return 0
    
    echo -e "${color}${prefix}${NC} ${message}"
    [[ -n "$level" ]] && log "$level" "$message"
}

# Status messages
print_success() {
    print_msg "$GREEN" "[✓ SUCCESS]" "INFO" "$@"
}

print_info() {
    print_msg "$BLUE" "[ℹ INFO]" "INFO" "$@"
}

print_warning() {
    print_msg "$YELLOW" "[⚠ WARN]" "WARN" "$@"
}

print_error() {
    print_msg "$RED" "[✗ ERROR]" "ERROR" "$@"
}

print_debug() {
    [[ "$LOG_LEVEL" == "DEBUG" ]] || return 0
    print_msg "$GRAY" "[🐛 DEBUG]" "DEBUG" "$@"
}

print_header() {
    local text="$*"
    local line=$(printf "%-${#text}s" | tr ' ' '=')
    echo -e "\n${BOLD}${BLUE}$line${NC}"
    echo -e "${BOLD}${BLUE}$text${NC}"
    echo -e "${BOLD}${BLUE}$line${NC}\n"
    log "INFO" "HEADER: $text"
}

print_subheader() {
    echo -e "\n${BOLD}${CYAN}--- $* ---${NC}\n"
    log "INFO" "SUBHEADER: $*"
}

# Progress indicators
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    
    printf "\r["
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $((width - filled)) | tr ' ' '-'
    printf "] %d%% (%d/%d)" $percent $current $total
}

# =============================================================================
# ERROR HANDLING AND VALIDATION
# =============================================================================

# Exit with error message
die() {
    print_error "$@"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Require command or exit
require_command() {
    local cmd="$1"
    local package="${2:-$1}"
    
    if ! command_exists "$cmd"; then
        die "Required command '$cmd' not found. Please install '$package'"
    fi
}

# Check if running as root
check_root() {
    [[ $EUID -eq 0 ]]
}

# Require root privileges
require_root() {
    if ! is_root; then
        die "This script must be run as root"
    fi
}

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Validate required files
require_file() {
    local file="$1"
    local description="${2:-file}"
    
    if ! file_exists "$file"; then
        die "Required $description not found: $file"
    fi
}

# Validate required directories
require_dir() {
    local dir="$1"
    local description="${2:-directory}"
    
    if ! dir_exists "$dir"; then
        die "Required $description not found: $dir"
    fi
}

# =============================================================================
# USER INTERACTION
# =============================================================================

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    
    [[ "$FORCE_MODE" == "true" ]] && { echo "y"; return 0; }
    
    local prompt="[y/N]"
    [[ "$default" == "y" ]] && prompt="[Y/n]"
    
    while true; do
        echo -ne "${CYAN}$question $prompt ${NC}"
        read -r response
        
        # Use default if empty
        [[ -z "$response" ]] && response="$default"
        
        case "${response,,}" in
            y|yes) echo "y"; return 0 ;;
            n|no) echo "n"; return 1 ;;
            *) print_warning "Please answer yes or no" ;;
        esac
    done
}

# Get user input with validation
get_input() {
    local prompt="$1"
    local default="$2"
    local validator="$3"
    
    while true; do
        if [[ -n "$default" ]]; then
            echo -ne "${CYAN}$prompt [$default]: ${NC}"
        else
            echo -ne "${CYAN}$prompt: ${NC}"
        fi
        
        read -r input
        [[ -z "$input" && -n "$default" ]] && input="$default"
        
        if [[ -z "$validator" ]] || eval "$validator '$input'"; then
            echo "$input"
            return 0
        else
            print_warning "Invalid input. Please try again."
        fi
    done
}

# =============================================================================
# SYSTEM UTILITIES
# =============================================================================

# Get OS information
get_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$NAME"
    elif command_exists lsb_release; then
        lsb_release -d | cut -f2
    elif [[ -f /etc/redhat-release ]]; then
        cat /etc/redhat-release
    else
        uname -s
    fi
}

# Check if running in Docker
check_docker() {
    [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null
}

# Get available memory in MB
get_memory_mb() {
    local mem_kb
    mem_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    echo $((mem_kb / 1024))
}

# Check available disk space in GB
get_disk_space_gb() {
    local path="${1:-.}"
    df -BG "$path" | awk 'NR==2 {print $4}' | sed 's/G//'
}

# =============================================================================
# FILE AND DIRECTORY OPERATIONS
# =============================================================================

# Create directory with parents
create_dir() {
    local dir="$1"
    local mode="${2:-755}"
    
    if ! dir_exists "$dir"; then
        print_debug "Creating directory: $dir"
        mkdir -p "$dir" || die "Failed to create directory: $dir"
        chmod "$mode" "$dir"
    fi
}

# Backup file with timestamp
backup_file() {
    local file="$1"
    local backup_dir="${2:-$(dirname "$file")}"
    
    if file_exists "$file"; then
        local backup_name="$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
        local backup_path="$backup_dir/$backup_name"
        
        print_info "Backing up $file to $backup_path"
        cp "$file" "$backup_path" || die "Failed to backup file: $file"
        echo "$backup_path"
    fi
}

# Safe file replacement (backup + replace)
replace_file() {
    local source="$1"
    local target="$2"
    
    require_file "$source" "source file"
    
    # Backup existing file
    [[ -f "$target" ]] && backup_file "$target"
    
    # Replace file
    print_debug "Replacing $target with $source"
    cp "$source" "$target" || die "Failed to replace file: $target"
}

# Download file with progress
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"
    
    print_info "Downloading $description..."
    
    if command_exists wget; then
        wget -O "$output" "$url" || die "Failed to download $description"
    elif command_exists curl; then
        curl -L -o "$output" "$url" || die "Failed to download $description"
    else
        die "Neither wget nor curl found. Cannot download files."
    fi
}

# =============================================================================
# PROCESS MANAGEMENT
# =============================================================================

# Kill process by name
kill_process() {
    local name="$1"
    local signal="${2:-TERM}"
    
    local pids
    pids=$(pgrep -f "$name")
    
    if [[ -n "$pids" ]]; then
        print_info "Killing processes matching '$name' with signal $signal"
        echo "$pids" | xargs kill -"$signal"
        sleep 2
        
        # Check if still running
        if pgrep -f "$name" > /dev/null; then
            print_warning "Process still running, using KILL signal"
            echo "$pids" | xargs kill -KILL
        fi
    else
        print_debug "No processes found matching '$name'"
    fi
}

# Wait for process to finish
wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    local description="${3:-process}"
    
    print_info "Waiting for $description to finish (PID: $pid, timeout: ${timeout}s)"
    
    local count=0
    while kill -0 "$pid" 2>/dev/null; do
        if [[ $count -ge $timeout ]]; then
            print_warning "Timeout waiting for $description"
            return 1
        fi
        sleep 1
        ((count++))
    done
    
    print_success "$description finished"
    return 0
}

# =============================================================================
# SERVICE MANAGEMENT
# =============================================================================

# Check if service is running
service_running() {
    local service="$1"
    systemctl is-active --quiet "$service"
}

# Start service
start_service() {
    local service="$1"
    print_info "Starting service: $service"
    systemctl start "$service" || die "Failed to start service: $service"
}

# Stop service
stop_service() {
    local service="$1"
    print_info "Stopping service: $service"
    systemctl stop "$service" || print_warning "Failed to stop service: $service"
}

# Restart service
restart_service() {
    local service="$1"
    print_info "Restarting service: $service"
    systemctl restart "$service" || die "Failed to restart service: $service"
}

# Enable service
enable_service() {
    local service="$1"
    print_info "Enabling service: $service"
    systemctl enable "$service" || die "Failed to enable service: $service"
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Initialize helper (called when sourced)
init_helper() {
    # Create log directory
    create_dir "$(dirname "$LOG_FILE")"
    
    # Log initialization
    log "INFO" "Helper script initialized - PID: $$, User: $(whoami), PWD: $(pwd)"
    
    # Set up trap for cleanup on exit
    trap 'log "INFO" "Script finished - Exit code: $?"' EXIT
    
    print_debug "Helper script loaded successfully"
    print_debug "Log file: $LOG_FILE"
    print_debug "Log level: $LOG_LEVEL"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Only initialize if being sourced (not executed directly)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_helper
else
    # If executed directly, show usage
    cat << 'EOF'
Helper.sh - Ultimate Bash Script Helper Library

Usage:
    source helper.sh

Environment Variables:
    LOG_FILE     - Log file path (default: /tmp/script_YYYYMMDD_HHMMSS.log)
    LOG_LEVEL    - Logging level: DEBUG, INFO, WARN, ERROR (default: INFO)
    QUIET_MODE   - Suppress output: true/false (default: false)
    FORCE_MODE   - Skip confirmations: true/false (default: false)

Available Functions:
    
    Output Functions:
    - print_success, print_info, print_warning, print_error, print_debug
    - print_header, print_subheader
    - show_spinner, progress_bar
    
    Validation Functions:
    - command_exists, require_command
    - is_root, require_root
    - file_exists, dir_exists, require_file, require_dir
    
    User Interaction:
    - ask_yes_no, get_input
    
    System Utilities:
    - get_os, is_docker, get_memory_mb, get_disk_space_gb
    
    File Operations:
    - create_dir, backup_file, replace_file, download_file
    
    Process Management:
    - kill_process, wait_for_process
    
    Service Management:
    - service_running, start_service, stop_service, restart_service, enable_service

Example:
    #!/bin/bash
    source bash-helpers.sh
    
    print_header "My Script"
    require_command "curl"
    
    if ask_yes_no "Continue with installation?"; then
        print_info "Installing..."
        # Your code here
        print_success "Installation complete!"
    fi

EOF
fi
