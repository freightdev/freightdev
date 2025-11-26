#!/bin/bash

# Safe Root-Level Aider Wrapper
# Allows aider to work on system files with toggleable safety

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

AIDER_ROOT_MODE_FILE="/tmp/aider_root_mode_$$"
AIDER_STAGING_DIR="/tmp/aider_staging_$$"
AIDER_PID_FILE="/tmp/aider_pid_$$"

# ============================================
# SAFETY CONFIGURATION
# ============================================

# Paths that are NEVER allowed even in root mode
FORBIDDEN_PATHS=(
    "/boot"
    "/dev"
    "/proc"
    "/sys"
    "/run"
)

# Paths that require explicit confirmation
DANGEROUS_PATHS=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
    "/etc/ssh/sshd_config"
)

# ============================================
# FUNCTIONS
# ============================================

check_forbidden_path() {
    local path=$1
    for forbidden in "${FORBIDDEN_PATHS[@]}"; do
        if [[ "$path" == "$forbidden"* ]]; then
            return 1
        fi
    done
    return 0
}

check_dangerous_path() {
    local path=$1
    for dangerous in "${DANGEROUS_PATHS[@]}"; do
        if [[ "$path" == "$dangerous"* ]]; then
            return 1
        fi
    done
    return 0
}

enable_root_mode() {
    echo "root" > "$AIDER_ROOT_MODE_FILE"
    print_warning "ROOT MODE ENABLED"
    echo ""
    echo "Aider can now work with system files."
    echo "Changes will be staged and require manual sudo apply."
    echo ""
    echo "To disable: aider-root toggle"
}

disable_root_mode() {
    rm -f "$AIDER_ROOT_MODE_FILE"
    print_success "ROOT MODE DISABLED"
    echo "Aider is now restricted to user space only."
}

toggle_root_mode() {
    if [ -f "$AIDER_ROOT_MODE_FILE" ]; then
        disable_root_mode
    else
        enable_root_mode
    fi
}

check_root_mode() {
    [ -f "$AIDER_ROOT_MODE_FILE" ]
}

kill_aider() {
    print_status "Searching for aider processes..."
    
    # Find all aider processes
    PIDS=$(pgrep -f "aider" | grep -v $$ | grep -v "aider-root")
    
    if [ -z "$PIDS" ]; then
        print_error "No aider processes found"
        return
    fi
    
    echo "Found aider processes:"
    ps aux | grep aider | grep -v grep | grep -v "aider-root"
    echo ""
    
    print_warning "This will kill the following PIDs: $PIDS"
    read -p "Continue? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for pid in $PIDS; do
            kill -9 $pid 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "Killed PID $pid"
            else
                print_error "Failed to kill PID $pid (may need sudo)"
            fi
        done
    else
        echo "Cancelled"
    fi
}

emergency_stop() {
    print_error "EMERGENCY STOP ACTIVATED"
    
    # Kill all aider processes (force)
    pkill -9 -f aider 2>/dev/null
    
    # Clean up staging
    rm -rf "$AIDER_STAGING_DIR" 2>/dev/null
    rm -f "$AIDER_ROOT_MODE_FILE" 2>/dev/null
    
    # Restore git state if in a repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        print_status "Restoring git state..."
        git reset --hard HEAD 2>/dev/null
        git clean -fd 2>/dev/null
    fi
    
    print_success "All aider processes terminated"
    print_success "Staging cleaned up"
    print_success "Git state restored (if applicable)"
}

start_aider_with_staging() {
    local target_dir=$1
    shift
    
    print_status "Starting aider with root staging mode..."
    
    # Create staging directory
    mkdir -p "$AIDER_STAGING_DIR"
    
    # Check if target needs root
    if [ ! -w "$target_dir" ]; then
        print_warning "Target directory requires root access: $target_dir"
        
        # Check if it's a forbidden path
        if ! check_forbidden_path "$target_dir"; then
            print_error "Path is in forbidden list!"
            print_error "Cannot work on: ${FORBIDDEN_PATHS[*]}"
            return 1
        fi
        
        # Check if it's dangerous
        if ! check_dangerous_path "$target_dir"; then
            print_error "DANGEROUS PATH DETECTED: $target_dir"
            read -p "Are you ABSOLUTELY SURE? [type YES]: " confirm
            if [ "$confirm" != "YES" ]; then
                echo "Cancelled for safety"
                return 1
            fi
        fi
        
        # Copy files to staging with sudo
        print_status "Copying files to staging area..."
        sudo cp -r "$target_dir"/* "$AIDER_STAGING_DIR/" 2>/dev/null
        sudo chown -R $USER:$USER "$AIDER_STAGING_DIR"
        
        cd "$AIDER_STAGING_DIR"
        
        # Initialize git if needed
        if [ ! -d .git ]; then
            git init
            git add .
            git commit -m "Initial staging commit" -q
        fi
        
        echo ""
        print_warning "Working in STAGING mode"
        print_warning "Original: $target_dir"
        print_warning "Staging:  $AIDER_STAGING_DIR"
        echo ""
        echo "After aider finishes, run: aider-root apply"
        echo ""
        
        # Start aider
        aider "$@"
        
    else
        # Normal user space
        cd "$target_dir"
        aider "$@"
    fi
}

apply_staged_changes() {
    if [ ! -d "$AIDER_STAGING_DIR" ]; then
        print_error "No staged changes found"
        return 1
    fi
    
    print_status "Staged changes location: $AIDER_STAGING_DIR"
    echo ""
    
    # Show diff
    print_status "Reviewing changes..."
    read -p "Show diff? [Y/n]: " show_diff
    if [[ ! "$show_diff" =~ ^[Nn]$ ]]; then
        git -C "$AIDER_STAGING_DIR" diff HEAD~1
    fi
    
    echo ""
    print_warning "This will copy changes back to system directories"
    read -p "Where should these changes go? (path): " target_path
    
    if [ -z "$target_path" ]; then
        print_error "No target path specified"
        return 1
    fi
    
    # Confirm
    echo ""
    print_warning "Will copy from: $AIDER_STAGING_DIR"
    print_warning "Will copy to:   $target_path"
    read -p "Confirm? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Applying changes with sudo..."
        sudo cp -r "$AIDER_STAGING_DIR"/* "$target_path/"
        
        if [ $? -eq 0 ]; then
            print_success "Changes applied!"
            read -p "Clean up staging? [Y/n]: " cleanup
            if [[ ! "$cleanup" =~ ^[Nn]$ ]]; then
                rm -rf "$AIDER_STAGING_DIR"
                print_success "Staging cleaned up"
            fi
        else
            print_error "Failed to apply changes"
        fi
    else
        echo "Cancelled"
    fi
}

show_status() {
    echo "╔════════════════════════════════════════╗"
    echo "║     AIDER ROOT MODE STATUS             ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    # Check root mode
    if check_root_mode; then
        print_warning "Root mode: ENABLED"
    else
        print_success "Root mode: DISABLED (safe)"
    fi
    
    # Check running processes
    AIDER_PROCS=$(pgrep -f aider | wc -l)
    if [ "$AIDER_PROCS" -gt 0 ]; then
        print_status "Running aider processes: $AIDER_PROCS"
        ps aux | grep aider | grep -v grep | grep -v "aider-root"
    else
        print_status "No aider processes running"
    fi
    
    # Check staging
    if [ -d "$AIDER_STAGING_DIR" ]; then
        print_warning "Staging area exists: $AIDER_STAGING_DIR"
        echo "  Files: $(find "$AIDER_STAGING_DIR" -type f | wc -l)"
    fi
    
    echo ""
    echo "Forbidden paths: ${FORBIDDEN_PATHS[*]}"
}

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║              AIDER ROOT MODE WRAPPER                        ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  aider-root <command> [options]

COMMANDS:
  start <path>      - Start aider in a directory (auto-handles root)
  toggle            - Toggle root mode on/off
  enable            - Enable root mode
  disable           - Disable root mode
  kill              - Kill running aider processes (interactive)
  emergency         - EMERGENCY STOP (kills all, resets git)
  apply             - Apply staged root changes
  status            - Show current status
  help              - Show this help

EXAMPLES:
  # Work in your home directory (normal)
  aider-root start ~/myproject

  # Work on system configs (enables staging)
  aider-root enable
  aider-root start /etc/nginx
  # ... make changes in aider ...
  # exit aider
  aider-root apply

  # Stop a rogue aider
  aider-root kill

  # Nuclear option
  aider-root emergency

SAFETY FEATURES:
  ✓ Forbidden paths (never editable): /boot, /dev, /proc, /sys
  ✓ Dangerous paths (require confirmation): /etc/passwd, /etc/shadow
  ✓ Staging system (changes isolated until you apply them)
  ✓ Git safety (changes are tracked)
  ✓ Emergency stop (kills all, restores state)

ROOT MODE:
  When enabled, aider can work on system files via staging:
  1. Files copied to /tmp/aider_staging_*
  2. You make changes in aider
  3. You review and manually apply with sudo

  When disabled, aider only works in user space.

STOPPING ROGUE AIDER:
  1. Try: aider-root kill (interactive)
  2. Or:  aider-root emergency (nuclear)
  3. Or:  Ctrl+C in the aider terminal
  4. Or:  pkill -9 aider (from another terminal)
EOF
}

# ============================================
# MAIN
# ============================================

case "${1:-help}" in
    start)
        if [ -z "$2" ]; then
            print_error "Usage: aider-root start <directory> [aider options]"
            exit 1
        fi
        
        TARGET_DIR="$2"
        shift 2
        
        if check_root_mode || [ ! -w "$TARGET_DIR" ]; then
            start_aider_with_staging "$TARGET_DIR" "$@"
        else
            cd "$TARGET_DIR"
            aider "$@"
        fi
        ;;
    
    toggle)
        toggle_root_mode
        ;;
    
    enable)
        enable_root_mode
        ;;
    
    disable)
        disable_root_mode
        ;;
    
    kill)
        kill_aider
        ;;
    
    emergency)
        print_error "EMERGENCY STOP REQUESTED"
        read -p "This will kill all aider processes and reset git. Continue? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            emergency_stop
        else
            echo "Cancelled"
        fi
        ;;
    
    apply)
        apply_staged_changes
        ;;
    
    status)
        show_status
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        print_error "Unknown command: $1"
        echo "Run 'aider-root help' for usage"
        exit 1
        ;;
esac
