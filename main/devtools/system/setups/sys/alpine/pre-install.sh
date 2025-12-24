#!/bin/bash
#
# Alpine Linux Cluster Node Installation Script
# Automates setup of btrfs, iwd networking, and cluster services
#
# WARNING: THIS WILL DESTROY DATA ON TARGET DISK
# Use at your own risk
#

set -e  # Exit on error

# ==============================================
# CONFIGURATION - EDIT THESE VALUES
# ==============================================

DISK="/dev/sda"              # Target disk (WARNING: WILL BE WIPED)
HOSTNAME="node-01"           # Node hostname
TIMEZONE="America/New_York"  # Timezone
ROOT_PASSWORD=""             # Leave empty to prompt
ADMIN_USER="admin"           # Admin username
ADMIN_PASSWORD=""            # Leave empty to prompt
WIFI_SSID=""                 # WiFi network name (leave empty if wired)
WIFI_PASSWORD=""             # WiFi password
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"
ALPINE_VERSION="v3.23"       # Alpine version

# Partition sizes
EFI_SIZE="512M"
BOOT_SIZE="1G"
SWAP_SIZE="16G"  # Or set to RAM size

# Btrfs mount options
BTRFS_OPTS="noatime,compress=zstd:3,space_cache=v2,ssd"

# Services to install
INSTALL_NOMAD=true
INSTALL_CONSUL=true
INSTALL_VAULT=true
INSTALL_TERRAFORM=true
INSTALL_FIRECRACKER=true
INSTALL_PODMAN=true
INSTALL_TRAEFIK=true

# ==============================================
# HELPER FUNCTIONS
# ==============================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "ERROR: $*" >&2
    exit 1
}

prompt_if_empty() {
    local var_name="$1"
    local prompt_text="$2"
    local is_password="${3:-false}"
    
    if [ -z "${!var_name}" ]; then
        if [ "$is_password" = "true" ]; then
            read -sp "$prompt_text: " "$var_name"
            echo
        else
            read -p "$prompt_text: " "$var_name"
        fi
    fi
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
    fi
}

confirm_disk() {
    log "WARNING: This will DESTROY ALL DATA on $DISK"
    lsblk "$DISK" 2>/dev/null || error "Disk $DISK not found"
    read -p "Are you absolutely sure? Type 'yes' to continue: " confirm
    [ "$confirm" = "yes" ] || error "Installation cancelled"
}

# ==============================================
# PHASE 1: PREPARATION
# ==============================================

prepare_system() {
    log "Installing required packages for installation..."
    apk add --no-cache \
        btrfs-progs \
        cryptsetup \
        gdisk \
        blkid \
        e2fsprogs \
        dosfstools \
        util-linux
}

# ==============================================
# PHASE 2: DISK PARTITIONING
# ==============================================

partition_disk() {
    log "Partitioning disk $DISK..."
    
    # Wipe existing partitions
    wipefs -af "$DISK"
    
    # Create GPT partition table and partitions
    sgdisk -Z "$DISK"
    sgdisk -n 1:0:+${EFI_SIZE} -t 1:ef00 -c 1:"EFI System" "$DISK"
    sgdisk -n 2:0:+${SWAP_SIZE} -t 2:8200 -c 2:"Swap" "$DISK"
    sgdisk -n 3:0:0 -t 3:8300 -c 3:"Alpine Root" "$DISK"
    sgdisk -p "$DISK"
    
    # Wait for kernel to re-read partition table
    sleep 2
    partprobe "$DISK"
    sleep 2
}

format_partitions() {
    log "Formatting partitions..."
    
    # Determine partition naming (nvme uses p1, sda uses 1)
    if [[ "$DISK" =~ "nvme" ]]; then
        PART_EFI="${DISK}p1"
        PART_SWAP="${DISK}p2"
        PART_ROOT="${DISK}p3"
    else
        PART_EFI="${DISK}1"
        PART_SWAP="${DISK}2"
        PART_ROOT="${DISK}3"
    fi
    
    # Format EFI
    mkfs.vfat -F32 "$PART_EFI"
    
    # Setup swap
    mkswap "$PART_SWAP"
    
    # Format btrfs root
    mkfs.btrfs -f -L alpine-root "$PART_ROOT"
}

# ==============================================
# PHASE 3: BTRFS SUBVOLUMES
# ==============================================

create_btrfs_layout() {
    log "Creating btrfs subvolume layout..."
    
    # Mount root btrfs
    mount "$PART_ROOT" /mnt
    
    # Create subvolumes
    btrfs subvolume create /mnt/@root
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@var_log
    btrfs subvolume create /mnt/@opt
    btrfs subvolume create /mnt/@srv
    
    umount /mnt
    
    # Mount with subvolumes
    mount -o ${BTRFS_OPTS},subvol=@root "$PART_ROOT" /mnt
    
    mkdir -p /mnt/{home,var,var/log,opt,srv,.snapshots,boot,boot/efi}
    
    mount -o ${BTRFS_OPTS},subvol=@home "$PART_ROOT" /mnt/home
    mount -o ${BTRFS_OPTS},subvol=@var "$PART_ROOT" /mnt/var
    mount -o ${BTRFS_OPTS},subvol=@var_log "$PART_ROOT" /mnt/var/log
    mount -o ${BTRFS_OPTS},subvol=@opt "$PART_ROOT" /mnt/opt
    mount -o ${BTRFS_OPTS},subvol=@srv "$PART_ROOT" /mnt/srv
    mount -o ${BTRFS_OPTS},subvol=@snapshots "$PART_ROOT" /mnt/.snapshots
    
    mount "$PART_EFI" /mnt/boot/efi
}

# ==============================================
# PHASE 4: BASE SYSTEM INSTALLATION
# ==============================================

install_base_system() {
    log "Installing Alpine base system..."
    
    export ROOTFS=btrfs
    export BOOT_SIZE=512
    
    # Use setup-disk to install
    setup-disk -m sys /mnt
    
    log "Base system installed"
}

# ==============================================
# PHASE 5: CONFIGURE SYSTEM
# ==============================================

configure_fstab() {
    log "Configuring fstab..."
    
    # Get UUIDs
    ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
    EFI_UUID=$(blkid -s UUID -o value "$PART_EFI")
    SWAP_UUID=$(blkid -s UUID -o value "$PART_SWAP")
    
    cat > /mnt/etc/fstab << EOF
# <device>                              <dir>         <type>  <options>                                                         <dump> <fsck>
UUID=$ROOT_UUID                         /             btrfs   ${BTRFS_OPTS},subvol=@root                                        0      1
UUID=$ROOT_UUID                         /home         btrfs   ${BTRFS_OPTS},subvol=@home                                        0      2
UUID=$ROOT_UUID                         /var          btrfs   ${BTRFS_OPTS},subvol=@var                                         0      2
UUID=$ROOT_UUID                         /var/log      btrfs   ${BTRFS_OPTS},subvol=@var_log                                     0      2
UUID=$ROOT_UUID                         /opt          btrfs   ${BTRFS_OPTS},subvol=@opt                                         0      2
UUID=$ROOT_UUID                         /srv          btrfs   ${BTRFS_OPTS},subvol=@srv                                         0      2
UUID=$ROOT_UUID                         /.snapshots   btrfs   ${BTRFS_OPTS},subvol=@snapshots                                   0      2
UUID=$EFI_UUID                          /boot/efi     vfat    umask=0077                                                        0      2
UUID=$SWAP_UUID                         none          swap    sw                                                                0      0
EOF
}

configure_repositories() {
    log "Configuring APK repositories..."
    
    cat > /mnt/etc/apk/repositories << EOF
${ALPINE_MIRROR}/${ALPINE_VERSION}/main
${ALPINE_MIRROR}/${ALPINE_VERSION}/community
EOF
}

configure_mkinitfs() {
    log "Configuring initramfs for btrfs..."
    
    # Add btrfs to features
    sed -i 's/^features=.*/features="ata base cdrom btrfs keymap kms mmc nvme raid scsi usb"/' \
        /mnt/etc/mkinitfs/mkinitfs.conf
}

setup_hostname() {
    log "Setting hostname to $HOSTNAME..."
    echo "$HOSTNAME" > /mnt/etc/hostname
    
    cat > /mnt/etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain
::1         localhost localhost.localdomain
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
}

# ==============================================
# PHASE 6: CHROOT CONFIGURATION
# ==============================================

chroot_configure() {
    log "Configuring system in chroot..."
    
    # Mount pseudo-filesystems
    mount --bind /dev /mnt/dev
    mount --bind /proc /mnt/proc
    mount --bind /sys /mnt/sys
    mount --bind /run /mnt/run
    
    # Create chroot script
    cat > /mnt/root/configure.sh << 'EOFCHROOT'
#!/bin/bash
set -e

# Update apk
apk update
apk upgrade

# Rebuild initramfs
mkinitfs $(ls /lib/modules/ | head -n1)

# Enable btrfs-scan service
rc-update add btrfs-scan boot

# Install essential packages
apk add --no-cache \
    bash bash-completion \
    curl wget \
    htop ncdu iotop \
    git \
    sudo doas \
    tmux \
    vim \
    man-pages man-pages-posix \
    util-linux coreutils findutils \
    lsof strace \
    rsync \
    zsh \
    btrbk \
    iwd dbus \
    chrony

# Configure sudo
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Enable chrony
rc-update add chronyd default

# Enable btrfs-scan
rc-update add btrfs-scan boot
EOFCHROOT

    chmod +x /mnt/root/configure.sh
    chroot /mnt /root/configure.sh
    rm /mnt/root/configure.sh
}

configure_networking() {
    log "Configuring iwd for networking..."
    
    cat > /mnt/etc/iwd/main.conf << EOF
[General]
EnableNetworkConfiguration=true
NameResolvingService=resolvconf

[Network]
RoutePriorityOffset=200
EOF

    # Enable services in chroot
    chroot /mnt rc-update add dbus boot
    chroot /mnt rc-update add iwd boot
    chroot /mnt rc-update del networking boot || true
    
    # Setup WiFi if credentials provided
    if [ -n "$WIFI_SSID" ] && [ -n "$WIFI_PASSWORD" ]; then
        log "Pre-configuring WiFi network..."
        mkdir -p /mnt/var/lib/iwd
        
        # Generate PSK
        WIFI_SSID_HEX=$(echo -n "$WIFI_SSID" | xxd -p | tr -d '\n')
        PSK=$(echo -n "$WIFI_PASSWORD" | iconv -t UTF-16LE | openssl dgst -md4 -binary | xxd -p)
        
        cat > "/mnt/var/lib/iwd/${WIFI_SSID}.psk" << EOF
[Security]
PreSharedKey=$PSK
Passphrase=$WIFI_PASSWORD

[Settings]
AutoConnect=true
EOF
    fi
}

configure_users() {
    log "Configuring users..."
    
    # Set root password
    if [ -n "$ROOT_PASSWORD" ]; then
        echo "root:$ROOT_PASSWORD" | chroot /mnt chpasswd
    else
        log "WARNING: Root password not set"
    fi
    
    # Create admin user
    chroot /mnt adduser -D -G wheel "$ADMIN_USER"
    if [ -n "$ADMIN_PASSWORD" ]; then
        echo "$ADMIN_USER:$ADMIN_PASSWORD" | chroot /mnt chpasswd
    fi
}

# ==============================================
# PHASE 7: INSTALL CLUSTER SERVICES
# ==============================================

install_cluster_services() {
    log "Installing cluster services..."
    
    # Install from repos
    PACKAGES=""
    
    [ "$INSTALL_NOMAD" = true ] && PACKAGES="$PACKAGES nomad"
    [ "$INSTALL_CONSUL" = true ] && PACKAGES="$PACKAGES consul"
    [ "$INSTALL_VAULT" = true ] && PACKAGES="$PACKAGES vault"
    [ "$INSTALL_TERRAFORM" = true ] && PACKAGES="$PACKAGES terraform"
    [ "$INSTALL_PODMAN" = true ] && PACKAGES="$PACKAGES podman"
    [ "$INSTALL_TRAEFIK" = true ] && PACKAGES="$PACKAGES traefik"
    
    if [ -n "$PACKAGES" ]; then
        chroot /mnt apk add --no-cache $PACKAGES || log "WARNING: Some packages not available in repos"
    fi
    
    # Manual installs for packages not in repos
    install_manual_packages
}

install_manual_packages() {
    log "Installing packages requiring manual download..."
    
    # DragonflyDB
    log "Installing DragonflyDB..."
    DRAGONFLY_VER="v1.14.2"
    wget -O /tmp/dragonfly.tar.gz \
        "https://github.com/dragonflydb/dragonfly/releases/download/${DRAGONFLY_VER}/dragonfly-x86_64.tar.gz"
    tar -xzf /tmp/dragonfly.tar.gz -C /mnt/usr/local/bin/
    
    # DuckDB
    log "Installing DuckDB..."
    chroot /mnt apk add --no-cache duckdb || {
        DUCKDB_VER="v0.10.0"
        wget -O /mnt/usr/local/bin/duckdb \
            "https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VER}/duckdb_cli-linux-amd64.zip"
        unzip /mnt/usr/local/bin/duckdb.zip -d /mnt/usr/local/bin/
        chmod +x /mnt/usr/local/bin/duckdb
    }
    
    # SurrealDB
    log "Installing SurrealDB..."
    wget -O /mnt/usr/local/bin/surreal \
        "https://download.surrealdb.com/latest/surreal-linux-amd64"
    chmod +x /mnt/usr/local/bin/surreal
    
    # Qdrant
    log "Installing Qdrant..."
    QDRANT_VER="v1.7.4"
    wget -O /tmp/qdrant.tar.gz \
        "https://github.com/qdrant/qdrant/releases/download/${QDRANT_VER}/qdrant-x86_64-unknown-linux-musl.tar.gz"
    tar -xzf /tmp/qdrant.tar.gz -C /mnt/usr/local/bin/
}

# ==============================================
# PHASE 8: FINALIZATION
# ==============================================

create_snapshot_script() {
    log "Creating snapshot management script..."
    
    cat > /mnt/usr/local/bin/snapshot-create << 'EOFSNAP'
#!/bin/bash
# Create system snapshot

SNAPSHOT_NAME="@root-$(date +%Y%m%d-%H%M%S)"
SNAPSHOT_DIR="/.snapshots"

echo "Creating snapshot: $SNAPSHOT_NAME"
btrfs subvolume snapshot -r / "$SNAPSHOT_DIR/$SNAPSHOT_NAME"
echo "Snapshot created: $SNAPSHOT_DIR/$SNAPSHOT_NAME"

# Cleanup old snapshots (keep last 10)
ls -1t $SNAPSHOT_DIR/@root-* | tail -n +11 | xargs -r btrfs subvolume delete
EOFSNAP

    chmod +x /mnt/usr/local/bin/snapshot-create
}

create_btrbk_config() {
    log "Configuring btrbk for automated snapshots..."
    
    cat > /mnt/etc/btrbk/btrbk.conf << EOF
timestamp_format        long
snapshot_preserve_min   6h
snapshot_preserve       48h 7d 4w 12m

volume $PART_ROOT
  subvolume @root
    snapshot_dir @snapshots
    snapshot_create always

  subvolume @home
    snapshot_dir @snapshots
    snapshot_create always
EOF

    # Add to cron
    echo "0 */6 * * * root /usr/bin/btrbk -q -c /etc/btrbk/btrbk.conf run" \
        >> /mnt/etc/crontabs/root
}

finalize() {
    log "Finalizing installation..."
    
    # Unmount pseudo-filesystems
    umount -l /mnt/dev /mnt/proc /mnt/sys /mnt/run 2>/dev/null || true
    
    # Create initial snapshot
    log "Creating initial system snapshot..."
    btrfs subvolume snapshot -r /mnt /mnt/.snapshots/@root-initial
    
    log "Installation complete!"
    log ""
    log "System is ready to boot. Remember to:"
    log "1. Remove installation media"
    log "2. Reboot"
    log "3. Login as $ADMIN_USER or root"
    log "4. Connect to WiFi: iwctl station wlan0 connect '$WIFI_SSID'" 
    log "5. Configure cluster services"
}

# ==============================================
# MAIN INSTALLATION FLOW
# ==============================================

main() {
    log "Alpine Linux Cluster Node Installation"
    log "========================================"
    
    check_root
    
    # Prompt for missing values
    prompt_if_empty ROOT_PASSWORD "Root password" true
    prompt_if_empty ADMIN_PASSWORD "Admin user ($ADMIN_USER) password" true
    [ -z "$WIFI_SSID" ] && prompt_if_empty WIFI_SSID "WiFi SSID (leave empty if wired)"
    [ -n "$WIFI_SSID" ] && prompt_if_empty WIFI_PASSWORD "WiFi Password" true
    
    confirm_disk
    
    prepare_system
    partition_disk
    format_partitions
    create_btrfs_layout
    install_base_system
    
    configure_fstab
    configure_repositories
    configure_mkinitfs
    setup_hostname
    
    chroot_configure
    configure_networking
    configure_users
    
    install_cluster_services
    
    create_snapshot_script
    create_btrbk_config
    
    finalize
    
    read -p "Reboot now? (y/n): " do_reboot
    if [ "$do_reboot" = "y" ] || [ "$do_reboot" = "Y" ]; then
        umount -R /mnt
        reboot
    fi
}

# Run main installation
main "$@"