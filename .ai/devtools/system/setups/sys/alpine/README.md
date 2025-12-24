# Alpine Linux Node Cluster Setup Guide

**Target**: Production-grade multi-tenant cluster with Nomad, Consul, Vault, and more

## System Overview

You're building a sophisticated infrastructure orchestration platform on Alpine Linux with:

- **Init System**: OpenRC (not systemd)
- **Filesystem**: Btrfs with snapshots for atomic rollback
- **Networking**: iwd for WiFi management
- **Services**: Nomad, Consul, Terraform, Firecracker, Vault, Zitadel, Traefik, Podman, DragonflyDB, DuckDB, SurrealDB, Qdrant

---

## PHASE 1: Base Alpine Installation

### 1.1 Boot and Initial Setup

Boot from USB/CD and login as `root` (no password initially).

```bash
# Start setup but we'll interrupt it
setup-alpine
```

**Configure during setup**:

- Keyboard: `us` / `us`
- Hostname: `node-01` (or your preferred)
- Network: Select your interface (we'll reconfigure for iwd later)
- Timezone: Your timezone
- NTP: `chrony` (preferred for clusters)
- User: Create your admin user
- SSH: `openssh`
- **STOP at disk selection** - Press Ctrl+C

### 1.2 Default Binaries Included

Alpine ships with **BusyBox**, which provides minimal implementations of:

- Core utils: `ls`, `cp`, `mv`, `cat`, `grep`, `sed`, `awk`
- Network: `ifconfig`, `ip`, `ping`, `wget`
- Text: `vi`, `less`
- Shell: `ash` (not bash)
- Init: OpenRC service manager

---

## PHASE 2: Btrfs Partition Setup

### 2.1 Partition the Disk

```bash
# Install partitioning tools
apk add btrfs-progs cryptsetup gdisk blkid e2fsprogs

# List disks
lsblk
fdisk -l

# Use gdisk for GPT partitioning (assuming /dev/sda)
gdisk /dev/sda
```

**Partition Layout**:

1. **EFI System Partition**: 512MB (Type: ef00)
2. **Boot Partition**: 1GB (Type: 8300) - Optional, can use EFI
3. **Main Btrfs Partition**: Rest of disk (Type: 8300)
4. **Swap Partition**: RAM size or 16GB (Type: 8200)

```bash
# In gdisk:
o    # Create new GPT table
y    # Confirm

n    # New partition 1 (EFI)
1
<enter>
+512M
ef00

n    # New partition 2 (Root)
2
<enter>
<enter>  # Use remaining space
8300

w    # Write and exit
y
```

### 2.2 Format Partitions

```bash
# Format EFI partition
mkfs.vfat -F32 /dev/sda1

# Format Btrfs root
mkfs.btrfs -L alpine-root /dev/sda2

# Optional: Swap
# mkswap /dev/sda3
# swapon /dev/sda3
```

### 2.3 Create Btrfs Subvolumes

```bash
# Mount root btrfs volume
mount /dev/sda2 /mnt

# Create subvolume structure for snapshots & rollback
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@opt
btrfs subvolume create /mnt/@srv

# Unmount
umount /mnt

# Mount with proper subvolume structure
mount -o noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@root /dev/sda2 /mnt

# Create mount points
mkdir -p /mnt/{home,var,var/log,opt,srv,.snapshots,boot/efi}

# Mount subvolumes
mount -o noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@home /dev/sda2 /mnt/home
mount -o noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@var /dev/sda2 /mnt/var
mount -o noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@var_log /dev/sda2 /mnt/var/log
mount -o noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@opt /dev/sda2 /mnt/opt
mount -o noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@srv /dev/sda2 /mnt/srv
mount -o noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@snapshots /dev/sda2 /mnt/.snapshots

# Mount EFI
mount /dev/sda1 /mnt/boot/efi
```

---

## PHASE 3: Install Alpine to Btrfs

### 3.1 Install Base System

```bash
# Set environment for btrfs
export ROOTFS=btrfs
export BOOT_SIZE=512

# Install to /mnt
setup-disk -m sys /mnt
```

### 3.2 Configure fstab

```bash
# Get UUIDs
blkid

# Edit fstab in chroot or from live system
vi /mnt/etc/fstab
```

**Example `/etc/fstab`**:

```
UUID=<root-uuid>  /            btrfs  noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@root      0 1
UUID=<root-uuid>  /home        btrfs  noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@home      0 2
UUID=<root-uuid>  /var         btrfs  noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@var       0 2
UUID=<root-uuid>  /var/log     btrfs  noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@var_log   0 2
UUID=<root-uuid>  /opt         btrfs  noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@opt       0 2
UUID=<root-uuid>  /srv         btrfs  noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@srv       0 2
UUID=<root-uuid>  /.snapshots  btrfs  noatime,compress=zstd:3,space_cache=v2,ssd,subvol=@snapshots 0 2
UUID=<efi-uuid>   /boot/efi    vfat   umask=0077                                                    0 2
```

### 3.3 Enable Btrfs Module

```bash
# Chroot into new system
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
chroot /mnt

# Edit mkinitfs config
vi /etc/mkinitfs/mkinitfs.conf
```

Add `btrfs` to features:

```
features="ata base cdrom btrfs keymap kms mmc nvme raid scsi usb"
```

```bash
# Rebuild initramfs
mkinitfs $(ls /lib/modules/)

# Enable btrfs-scan service
rc-update add btrfs-scan boot

# Exit chroot
exit
```

---

## PHASE 4: Repository & Mirror Setup

### 4.1 Configure APK Repositories

```bash
# Chroot back in
chroot /mnt

# Edit repositories
vi /etc/apk/repositories
```

**Production Config**:

```
https://dl-cdn.alpinelinux.org/alpine/v3.23/main
https://dl-cdn.alpinelinux.org/alpine/v3.23/community
```

**For Edge/Testing** (not recommended for production):

```
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing
```

### 4.2 Update & Essential Packages

```bash
# Update package index
apk update

# Upgrade all packages
apk upgrade

# Install essential tools
apk add \
    bash bash-completion \
    curl wget \
    htop ncdu \
    git \
    sudo doas \
    tmux screen \
    vim nano \
    man-pages man-pages-posix \
    util-linux coreutils \
    lsof strace \
    rsync \
    zsh

# Exit chroot for now
exit
```

---

## PHASE 5: Reboot and Networking with iwd

### 5.1 First Boot

```bash
# Unmount all
umount -R /mnt
reboot
```

### 5.2 Configure iwd for WiFi

After reboot, login as root or your user:

```bash
# Install iwd and dbus
apk add iwd dbus

# Configure iwd for standalone mode (handles DHCP)
vi /etc/iwd/main.conf
```

**`/etc/iwd/main.conf`**:

```ini
[General]
EnableNetworkConfiguration=true
NameResolvingService=resolvconf

[Network]
RoutePriorityOffset=200
```

```bash
# Start services
rc-service dbus start
rc-service iwd start

# Enable at boot
rc-update add dbus boot
rc-update add iwd boot
```

### 5.3 Connect to WiFi

```bash
# Interactive mode
iwctl

# Or command line
iwctl device list
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect "YourSSID"
# Enter password when prompted

# Verify connection
ip addr show wlan0
ping -c 4 8.8.8.8
```

### 5.4 Disable Old Networking

```bash
# If networking service is still enabled
rc-update del networking boot

# Edit /etc/network/interfaces and comment out everything except loopback
vi /etc/network/interfaces
```

---

## PHASE 6: OpenRC vs systemd - Understanding the Differences

### Key Differences

| Feature              | systemd                    | OpenRC                                     |
| -------------------- | -------------------------- | ------------------------------------------ |
| Init script location | `/usr/lib/systemd/system/` | `/etc/init.d/`                             |
| Enable service       | `systemctl enable foo`     | `rc-update add foo`                        |
| Start service        | `systemctl start foo`      | `rc-service foo start`                     |
| Stop service         | `systemctl stop foo`       | `rc-service foo stop`                      |
| Restart service      | `systemctl restart foo`    | `rc-service foo restart`                   |
| Service status       | `systemctl status foo`     | `rc-service foo status`                    |
| List services        | `systemctl list-units`     | `rc-status`                                |
| Service logs         | `journalctl -u foo`        | Check `/var/log/` or service-specific logs |
| Runlevels            | targets                    | boot, default, shutdown, etc.              |

### OpenRC Runlevels

```bash
# List runlevels
rc-status --list

# Common runlevels:
# - boot: Services needed for system boot
# - default: Normal operation services
# - shutdown: Cleanup services
```

### Creating OpenRC Service Files

Services in `/etc/init.d/` are shell scripts with specific functions:

**Example `/etc/init.d/myservice`**:

```bash
#!/sbin/openrc-run

name="My Service"
description="My custom service"
command="/usr/bin/myservice"
command_args="--config /etc/myservice.conf"
command_background=true
pidfile="/run/myservice.pid"

depend() {
    need net
    after firewall
    use dns
}

start_pre() {
    checkpath --directory --owner myuser:mygroup --mode 0755 /run/myservice
}
```

```bash
chmod +x /etc/init.d/myservice
rc-update add myservice default
rc-service myservice start
```

---

## PHASE 7: Install Cluster Services

### 7.1 HashiCorp Stack

```bash
# Enable community repo if not already
apk add \
    nomad \
    consul \
    vault \
    terraform

# These might need manual download from HashiCorp if not in repos
# For ARM64 or specific versions:
```

**Manual Installation Template**:

```bash
cd /tmp
wget https://releases.hashicorp.com/nomad/1.7.2/nomad_1.7.2_linux_amd64.zip
unzip nomad_1.7.2_linux_amd64.zip
mv nomad /usr/local/bin/
chmod +x /usr/local/bin/nomad
nomad --version
```

### 7.2 Container & Virtualization

```bash
apk add \
    podman \
    firecracker

# For Docker if needed
apk add docker docker-compose docker-cli-compose
rc-update add docker default
rc-service docker start
```

### 7.3 Databases

```bash
# DragonflyDB (if available, may need manual install)
# Check: https://github.com/dragonflydb/dragonfly

# DuckDB
apk add duckdb

# SurrealDB - manual install
wget https://download.surrealdb.com/latest/surreal-linux-amd64
mv surreal-linux-amd64 /usr/local/bin/surreal
chmod +x /usr/local/bin/surreal

# Qdrant - manual install
wget https://github.com/qdrant/qdrant/releases/download/v1.7.4/qdrant-x86_64-unknown-linux-musl.tar.gz
tar xzf qdrant-x86_64-unknown-linux-musl.tar.gz
mv qdrant /usr/local/bin/
```

### 7.4 Reverse Proxy & Identity

```bash
# Traefik
apk add traefik

# Zitadel - manual install or Docker
# https://zitadel.com/docs/self-hosting/deploy/linux
```

---

## PHASE 8: Btrfs Snapshot Management

### 8.1 Manual Snapshots

```bash
# Create snapshot of root
btrfs subvolume snapshot /mnt/@root /.snapshots/@root-$(date +%Y%m%d-%H%M%S)

# Create read-only snapshot
btrfs subvolume snapshot -r /mnt/@root /.snapshots/@root-$(date +%Y%m%d-%H%M%S)

# List snapshots
btrfs subvolume list /.snapshots/
```

### 8.2 Rollback to Snapshot

```bash
# Boot from live USB
mount /dev/sda2 /mnt

# List snapshots
btrfs subvolume list /mnt

# Delete current root
btrfs subvolume delete /mnt/@root

# Snapshot to restore as new root
btrfs subvolume snapshot /mnt/@snapshots/@root-20250101-120000 /mnt/@root

# Reboot
umount -R /mnt
reboot
```

### 8.3 Automated Snapshots with btrbk

```bash
apk add btrbk

vi /etc/btrbk/btrbk.conf
```

**`/etc/btrbk/btrbk.conf`**:

```
timestamp_format        long
snapshot_preserve_min   6h
snapshot_preserve       48h 7d 4w 12m

volume /mnt
  subvolume @root
    snapshot_dir .snapshots
    snapshot_create always

  subvolume @home
    snapshot_dir .snapshots
    snapshot_create always
```

```bash
# Test config
btrbk -c /etc/btrbk/btrbk.conf -v -n run

# Run snapshot
btrbk -c /etc/btrbk/btrbk.conf run

# Add to cron
echo "0 */6 * * * root /usr/bin/btrbk -q run" >> /etc/crontabs/root
```

---

## PHASE 9: Multi-Tenant Architecture

### 9.1 Schema-Based User Profiles

Create a profile schema system:

**Directory Structure**:

```
/etc/cluster/
├── schemas/
│   ├── user-base.yaml
│   └── service-base.yaml
├── manifests/
│   ├── user-alice.yaml
│   └── service-nomad.yaml
└── snapshots/
    └── metadata/
```

**Example User Schema** `/etc/cluster/schemas/user-base.yaml`:

```yaml
apiVersion: v1
kind: UserProfile
metadata:
  version: "1.0"
spec:
  filesystem:
    subvolume: true
    snapshot_interval: "6h"
    quota: "50G"
  services:
    allowed: []
    resources:
      cpu_quota: "2.0"
      memory_limit: "4G"
  network:
    namespace: true
    firewall_profile: "default"
```

### 9.2 Service Isolation

Use Linux namespaces + cgroups via Podman/Nomad for isolation.

---

## PHASE 10: Guix-Style Generation Management

For a Guix-inspired approach, you'd need to:

1. **Build a custom package manager** in Rust that:
   - Tracks system generations
   - Uses Btrfs snapshots as "generations"
   - Maintains activation scripts
   - Handles rollback atomically

2. **Profile system**:
   - Each generation = Btrfs snapshot + metadata
   - Symlink `/run/current-system` to active generation
   - Boot menu shows available generations

This is a massive undertaking. Consider using **NixOS** instead if you want declarative config, or build incrementally on Alpine.

---

## Key Takeaways

1. **OpenRC is simpler** than systemd but requires manual service scripts
2. **Btrfs snapshots** give you atomic rollback capability
3. **iwd** handles WiFi elegantly in standalone mode
4. **Multi-tenancy** requires careful namespace/cgroup management
5. **Guix-style** generation management needs custom tooling
