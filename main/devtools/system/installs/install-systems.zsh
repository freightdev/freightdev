#!/bin/zsh
# Lenovo Yoga 9i (Meteor Lake) Setup Script
# Run this after a fresh install to restore configuration

#=============================================================================
# MAIN LOGIC FUNCTION
#=============================================================================

main() {
    init_setup            # Initiates setup process
    install_packages      # Install packages
    install_aur_helper    # Install 'yay' package manager
    boot_configs          # Systemd-boot configuration setup
    global_envs           # Setup gloable environments
    display_configs       # Setup 'sway' display settings
    service_setup         # Setup required services
    zram_setup            # Setup zram-generator (optional)
}


#=============================================================================
# CONFIGURATIONS, VARIABLES, & LOGS
#=============================================================================

CUSTOM_PACKAGES=(
    # Hardware
    linux linux-firmware-intel fuse-overlayfs fuse3
    
    # Sway and Wayland
    sway waybar wofi foot swaylock swayidle swaybg
    wl-clipboard grim slurp mako
    
    # Graphics and drivers (Intel Arc Meteor Lake)
    mesa vulkan-intel intel-media-driver libva-intel-driver
    
    # Audio
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
    
    # Essential tools
    firefox vim nano htop fastfetch tree tmux
    sudo ranger networkmanager less

    # Add-on tools
    rsync ripgrep lsof tmux ninja which strace lm_sensors
    ioping eza

    # Security
    keychain iptables nftables
    
    # Development
    podman podman-docker podman-compose
    
    # Fonts
    ttf-liberation noto-fonts noto-fonts-emoji
    
    # File manager
    thunar thunar-volman gvfs lvm2 xfsprogs btrfs-progs 

    # RAM tools
    zram-generator
    
    # Media
    mpv imv

    # Utilities
    zstd bluez bluez-utils zram-generator

    # Shell
    bash zsh
)

typeset -A colors
colors[red]='\033[0;31m'
colors[green]='\033[0;32m'
colors[yellow]='\033[0;33m'
colors[blue]='\033[0;34m'
colors[purple]='\033[0;35m'
colors[cyan]='\033[0;36m'
colors[white]='\033[0;37m'
colors[bold]='\033[1m'
colors[dim]='\033[2m'
colors[reset]='\033[0m'

# Logging functions
prompt() {
    print -n "${colors[purple]}[ PROMPT ] $1${colors[reset]}"
    read "$2"
}

log() {
    print "${colors[cyan]}[ LOG ] $1${colors[reset]}"
}

success() {
    print "${colors[green]}[ SUCCESS ] $1${colors[reset]}"
    return 0
}

warn() {
    print "${colors[yellow]}[ WARN ] $1${colors[reset]}"
}

error() {
    print "${colors[red]}[ ERROR ] $1${colors[reset]}"
    exit 1
}

step() {
    print "${colors[blue]}${colors[bold]} $1${colors[reset]}"
}



#=============================================================================
# INITIATE SETUP PROCESS
#=============================================================================

init_setup() {

 log "Starting Lenovo Yoga 9i setup..."

    # Create setup directory structure
    sudo mkdir -p /etc/custom-setups/backups
    
}
#=============================================================================
# OS & PERMISSION DETECTION
#=============================================================================

# Detect OS and set package manager
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="${VERSION_ID:-rolling}"
    else
        error "Cannot detect OS - /etc/os-release not found"
    fi
    
    log "Detected OS: $OS_ID $OS_VERSION"
    
    # Set package manager commands
    case "$OS_ID" in
        alpine)
            PKG_UPDATE=(apk update)
            PKG_INSTALL=(apk add --no-cache)
            ;;
        ubuntu|debian|linuxmint|pop)
            PKG_UPDATE=(apt-get update)
            PKG_INSTALL=(apt-get install -y)
            ;;
        rocky|centos|rhel|fedora|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                PKG_UPDATE=(dnf makecache --refresh)
                PKG_INSTALL=(dnf install -y)
            else
                PKG_UPDATE=(yum makecache)
                PKG_INSTALL=(yum install -y)
            fi
            ;;
        arch|manjaro|endeavouros)
            PKG_UPDATE=(pacman -Sy)
            PKG_INSTALL=(pacman -S --noconfirm --needed)
            ;;
        opensuse*|sles)
            PKG_UPDATE=(zypper refresh)
            PKG_INSTALL=(zypper install -y)
            ;;
        *)
            log_error "Unsupported OS: $OS_ID"
            log_info "Supported OS: Alpine, Ubuntu/Debian, RHEL/Fedora, Arch, openSUSE"
            return 1
            ;;
    esac
    
    return 0
}

# Check if running as root (not recommended)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root is not recommended for this script"
        prompt "Continue anyway? [y/N] " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            log "Exiting..."
            return 1
        fi
    fi
    return 0
}

# Check if sudo is available and working
check_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo is required but not found"
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        log "Sudo access required for package installation"
        if ! sudo true; then
            error "Failed to obtain sudo access"
        fi
    fi
    
    return 0
}

#=============================================================================
# INSTALLATION LOGIC
#=============================================================================

# Install system dependencies
install_packages() {
    log "Installing system dependencies..."
    
    # Detect OS first
    if ! detect_os; then
        return 1
    fi
    
    # Check prerequisites
    if ! check_root || ! check_sudo; then
        return 1
    fi
    
    # Update package manager
    log "Updating package manager..."
    if ! sudo "${PKG_UPDATE[@]}"; then
        error "Failed to update package manager"
    fi
    
    # Define dependencies per OS
    local base_deps build_deps lib_deps
    
    case "$OS_ID" in
        alpine)
            base_deps=(curl wget git clang)
            build_deps=(build-base cmake pkgconf)
            lib_deps=(fontconfig-dev freetype-dev libx11-dev libxcb-dev openssl-dev)
            ;;
        ubuntu|debian|linuxmint|pop)
            base_deps=(curl wget git clang)
            build_deps=(build-essential cmake pkg-config)
            lib_deps=(libfontconfig1-dev libfreetype6-dev libx11-dev libxcb1-dev libxkbcommon-dev libssl-dev)
            ;;
        rocky|centos|rhel|fedora|almalinux)
            base_deps=(curl wget git clang)
            build_deps=(gcc gcc-c++ make cmake pkg-config)
            lib_deps=(fontconfig-devel freetype-devel libX11-devel libxcb-devel openssl-devel)
            ;;
        arch|manjaro|endeavouros)
            base_deps=(curl wget git clang)
            build_deps=(base-devel cmake pkg-config)
            lib_deps=(fontconfig freetype2 libx11 libxcb openssl)
            ;;
        opensuse*|sles)
            base_deps=(curl wget git clang)
            build_deps=(gcc gcc-c++ make cmake pkg-config)
            lib_deps=(fontconfig-devel freetype2-devel libX11-devel libxcb-devel libopenssl-devel)
            ;;
    esac
    
    # Add custom packages if defined
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        lib_deps+=($CUSTOM_PACKAGES)
    fi
    
    # Combine all dependencies
    local all_deps=($base_deps $build_deps $lib_deps)
    
    log "Installing packages: ${all_deps[@]}"
    if ! sudo "${PKG_INSTALL[@]}" "${all_deps[@]}"; then
        error "Failed to install system dependencies"
    fi
    
    success "System dependencies installed successfully"
}

# Install AUR helper (yay)
install_aur_helper() {
    if [[ ! "$OS_ID" =~ ^(arch|manjaro|endeavouros)$ ]]; then
        log "AUR not supported on $OS_ID"
        return 0
    fi
    
    if command -v yay >/dev/null; then
        log "yay already installed"
        return 0
    fi
    
    if command -v paru >/dev/null; then
        log "paru already installed, using instead of yay"
        return 0
    fi
    
    step "Installing yay AUR helper..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Clone yay
    if ! git clone https://aur.archlinux.org/yay.git; then
        error "Failed to clone yay repository"
        return 1
    fi
    
    cd yay
    
    # Build and install
    if ! makepkg -si --noconfirm; then
        error "Failed to build yay"
        return 1
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    success "yay installed successfully"
}

#=============================================================================
# SYSTEMD-BOOT & GLOBAL ENVIRONMENT SETTINGS
#=============================================================================

boot_configs() {
    log "Configuring systemd-boot with Lenovo-specific kernel parameters..."

    # Backup existing boot entry
    if [[ -f /boot/loader/entries/arch.conf ]]; then
        sudo cp /boot/loader/entries/arch.conf /etc/custom-setups/backups/arch.conf.backup.$(date +%Y%m%d-%H%M%S)
        warn "Backed up existing boot entry"
    fi

    # Create new boot entry with Lenovo Yoga 9i optimizations
    sudo tee /boot/loader/entries/arch.conf > /dev/null << 'EOF'
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=/dev/archbox/root rw ucsi_acpi.quirks=1 i915.enable_guc=3 i915.enable_psr=0 i915.force_probe=7d55 intel_iommu=on quiet loglevel=3
EOF

    log "Updated systemd-boot configuration"
}

global_envs() {
    log "Setting up global environment variables..."

    # Create Sway/Wayland environment script
    sudo tee /etc/profile.d/lenovo-sway-fixes.sh > /dev/null << 'EOF'
#!/bin/bash
# Lenovo Yoga 9i Sway/Wayland optimizations

# Use GLES2 renderer instead of Vulkan (fixes Intel Arc issues)
export WLR_RENDERER=gles2

# Set desktop environment
export XDG_CURRENT_DESKTOP=sway

# Wayland-specific app settings
export QT_QPA_PLATFORM=wayland-egl
export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland

# Fix Java apps in Wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# Firefox Wayland
export MOZ_ENABLE_WAYLAND=1

# Enable hardware video acceleration
export LIBVA_DRIVER_NAME=iHD
export VDPAU_DRIVER=va_gl
EOF

    sudo chmod +x /etc/profile.d/lenovo-sway-fixes.sh
}
    

#=============================================================================
# DISPLAY CONFIGURATION
#=============================================================================

display_configs() {
    log "Setting up Sway configuration..."

    # Create user Sway config directory
    mkdir -p ~/.config/sway

    # Create basic Sway config if it doesn't exist
    if [[ ! -f ~/.config/sway/config ]]; then
        tee ~/.config/sway/config > /dev/null << 'EOF'
# Lenovo Yoga 9i Sway Config
# Include default config
include /etc/sway/config

# Yoga 9i specific settings
output * scale 1.25
output DP-1 pos 480 -1080

# Touchpad configuration
input type:touchpad {
    tap enabled
    natural_scroll enabled
    scroll_factor 0.5
}

# Auto-start applications
exec pipewire
exec pipewire-pulse  
exec waybar
exec mako
EOF
    fi
}

#=============================================================================
# SERVICE SETUP
#=============================================================================

service_setup() {
    log "Enabling essential services..."

    # Enable NetworkManager
    sudo systemctl enable NetworkManager
}

#=============================================================================
# ZRAM SETUP (for 16GB DDR5)
#=============================================================================

zram_setup() {
    log "Configuring zram..."

    # Configure zram for 16GB system
    sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = lz4    # use 'zstd' for more compression
swap-priority = 100
fs-type = swap
EOF

    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service
}

#=============================================================================
# MAIN LOGIC INITIATION
#=============================================================================

if [[ -n $ZSH_VERSION ]]; then
    # Run main logic
    main
else
    error "This script much be ran with ZSH. Please install zsh package, then rerun."
fi
