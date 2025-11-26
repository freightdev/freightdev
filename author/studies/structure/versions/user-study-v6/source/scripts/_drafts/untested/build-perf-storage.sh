#!/usr/bin/env bash
# =============================================================================
# THE "GO FASTER" STORAGE STACK — XFS + (optional) RAID + TUNING
# =============================================================================
# Features:
# - Optional mdadm RAID0 across NVMe devices
# - mkfs.xfs with stripe alignment (if RAID), reflink, tuned log
# - High-performance mount options (persist to fstab)
# - I/O scheduler = none (NVMe), readahead boosts, udev persistence
# - Sysctl tuning for dirty writeback & cache behavior
# - ZRAM via systemd zram-generator (zstd), sized from RAM
# - NVMe volatile write cache enable (WCE)
# - Tools: fio, nvme-cli, smartmontools
#
# Safe defaults: DRY_RUN=1 (no changes) until you set DRY_RUN=0 and confirm.
# =============================================================================

set -euo pipefail

# ------------------------------ CONFIG ---------------------------------------
# Global mode
DRY_RUN=1                 # 1 = show what would happen; 0 = actually do it
NON_INTERACTIVE=0         # 1 = skip confirms (DANGEROUS)

# Choose storage topology:
USE_RAID0=0               # 1 = build /dev/md0 from NVME_DEVICES[*]; 0 = single device

# Devices (edit to match your box)
# Examples:
#   Single device: TARGET_DEV="/dev/nvme0n1"
#   RAID0 devices: NVME_DEVICES=("/dev/nvme0n1" "/dev/nvme1n1")
TARGET_DEV="/dev/nvme0n1"
NVME_DEVICES=(/dev/nvme0n1 /dev/nvme1n1)

# Filesystem + mount
MOUNT_POINT="/srv"
FSTYPE="xfs"

# XFS mkfs tuning
# RAID: set stripe unit/width; for single device these are ignored when 0.
# Use the actual RAID stripe. Common: su=512k sw=2 (2-way RAID0 with 512K chunk)
XFS_LOG_SIZE="128m"
XFS_ALLOC_INODE_MAXPCT="25"
XFS_REFLINK=1
XFS_SU="512k"      # stripe unit for RAID
XFS_SW="2"         # stripe width (# of data devices)

# Mount options (fast path)
MOUNT_OPTS="defaults,noatime,nodiratime,logbufs=8,logbsize=64k,largeio,allocsize=64m,inode64"

# I/O scheduler + readahead
IOSCHED="none"     # for NVMe: none or mq-deadline
READAHEAD_KB=4096  # 4 MiB

# Sysctl tuning
SYSCTL_FILE="/etc/sysctl.d/99-xfs-performance.conf"
SYSCTL_TUNING=$(cat <<'EOF'
vm.swappiness = 10
vm.dirty_ratio = 40
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
vm.page-cluster = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
EOF
)

# ZRAM (systemd zram-generator)
ZRAM_CFG="/etc/systemd/zram-generator.conf"
ZRAM_SIZE_EXPR="ram / 2"       # e.g., "ram / 2", "16G", etc.
ZRAM_ALGO="zstd"
ZRAM_PRIORITY=100

# NVMe WCE: try to enable volatile write cache
ENABLE_NVME_WCE=1

# Packages to install
PKGS_COMMON=(fio smartmontools)
PKG_NVME="nvme-cli"  # Arch uses nvme-cli (nvme-tools older)
# -----------------------------------------------------------------------------

LOG="/var/log/perf-storage-setup.log"
UMASK_OLD="$(umask)"
umask 022

log()  { echo -e "[*] $*" | tee -a "$LOG"; }
ok()   { echo -e "[+] $*" | tee -a "$LOG"; }
warn() { echo -e "[!] $*" | tee -a "$LOG"; }
die()  { echo -e "[x] $*" | tee -a "$LOG"; exit 1; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY-RUN: $*"
  else
    eval "$@"
  fi
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    die "Run as root (sudo)."
  fi
}

confirm() {
  [[ "$NON_INTERACTIVE" -eq 1 ]] && return 0
  read -r -p "$1 [y/N]: " ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

detect_distro() {
  if command -v apt-get >/dev/null 2>&1; then
    echo debian
  elif command -v dnf >/dev/null 2>&1; then
    echo fedora
  elif command -v pacman >/dev/null 2>&1; then
    echo arch
  else
    echo unknown
  fi
}

install_packages() {
  local distro
  distro="$(detect_distro)"
  log "Installing required packages for distro: $distro"
  case "$distro" in
    debian)
      run "apt-get update"
      run "apt-get install -y ${PKGS_COMMON[*]} $PKG_NVME mdadm xfsprogs util-linux bc"
      ;;
    fedora)
      run "dnf install -y ${PKGS_COMMON[*]} $PKG_NVME mdadm xfsprogs util-linux bc"
      ;;
    arch)
      run "pacman -Sy --noconfirm ${PKGS_COMMON[*]} $PKG_NVME mdadm xfsprogs util-linux bc"
      ;;
    *)
      warn "Unknown distro; please install: ${PKGS_COMMON[*]} $PKG_NVME mdadm xfsprogs util-linux bc"
      ;;
  esac
}

is_block() { [[ -b "$1" ]]; }

device_model() {
  local d="$1"
  lsblk -ndo MODEL "$d" 2>/dev/null || true
}

ensure_not_mounted() {
  local d="$1"
  if findmnt -S "$d" >/dev/null 2>&1; then
    die "Device $d is mounted. Unmount it first."
  fi
}

create_raid0() {
  local arr=("$@")
  for d in "${arr[@]}"; do
    is_block "$d" || die "Not a block device: $d"
    ensure_not_mounted "$d"
  done
  if ! command -v mdadm >/dev/null 2>&1; then
    die "mdadm not installed"
  fi
  if [[ -e /dev/md0 ]]; then
    warn "/dev/md0 already exists. Skipping creation."
  else
    log "Creating RAID0 /dev/md0 from: ${arr[*]}"
    run "mdadm --create /dev/md0 --level=0 --raid-devices=${#arr[@]} ${arr[*]} --force"
    # Persist mdadm config
    if [[ "$DRY_RUN" -eq 0 ]]; then
      mdadm --detail --scan >> /etc/mdadm/mdadm.conf 2>/dev/null || true
      mdadm --detail --scan >> /etc/mdadm.conf 2>/dev/null || true
    fi
  fi
  echo "/dev/md0"
}

mkfs_xfs() {
  local dev="$1"
  local mkfs="mkfs.xfs -f -l version=2,size=${XFS_LOG_SIZE} -n size=4096 -i attr=2,maxpct=${XFS_ALLOC_INODE_MAXPCT} -m reflink=${XFS_REFLINK}"

  if [[ "$USE_RAID0" -eq 1 ]]; then
    mkfs+=" -d su=${XFS_SU},sw=${XFS_SW}"
  fi
  log "Formatting $dev with XFS: $mkfs $dev"
  confirm "FORMAT $dev (DESTROYS DATA). Continue?" || die "Aborted."
  run "$mkfs $dev"
}

ensure_mountpoint() {
  [[ -d "$MOUNT_POINT" ]] || run "mkdir -p '$MOUNT_POINT'"
}

mount_and_persist() {
  local dev="$1"
  ensure_mountpoint

  # Get UUID
  local uuid
  uuid="$(blkid -s UUID -o value "$dev")"
  [[ -n "$uuid" ]] || die "Failed to get UUID for $dev"

  # Update /etc/fstab
  local fstab_line="UUID=${uuid}  ${MOUNT_POINT}  ${FSTYPE}  ${MOUNT_OPTS}  0 0"

  if grep -qE "^[^#].*\s${MOUNT_POINT}\s" /etc/fstab; then
    log "Updating existing /etc/fstab entry for ${MOUNT_POINT}"
    if [[ "$DRY_RUN" -eq 0 ]]; then
      cp /etc/fstab /etc/fstab.bak.$(date +%s)
      sed -i.bak "/[[:space:]]$(echo "$MOUNT_POINT" | sed 's,/,\\/,g')[[:space:]]/c ${fstab_line}" /etc/fstab
    else
      echo "DRY-RUN: would replace fstab line with: $fstab_line"
    fi
  else
    log "Appending new /etc/fstab entry"
    run "bash -c 'echo \"$fstab_line\" >> /etc/fstab'"
  fi

  # Mount it
  if findmnt "$MOUNT_POINT" >/dev/null 2>&1; then
    log "Remounting $MOUNT_POINT with new options"
    run "mount -o remount ${MOUNT_POINT}"
  else
    log "Mounting $MOUNT_POINT"
    run "mount ${MOUNT_POINT}"
  fi
}

set_iosched_and_readahead() {
  local devnode="$1"  # e.g., /dev/nvme0n1
  local base
  base="$(basename "$devnode")"
  local sched_path="/sys/block/${base}/queue/scheduler"
  local ra_cmd="blockdev --setra ${READAHEAD_KB} ${devnode}"

  if [[ -e "$sched_path" ]]; then
    log "Setting I/O scheduler for $devnode -> ${IOSCHED}"
    run "bash -c 'echo ${IOSCHED} > ${sched_path}'" || warn "Failed to set scheduler on ${devnode}"
  else
    warn "No scheduler path for ${devnode} (${sched_path})"
  fi

  log "Setting readahead for $devnode -> ${READAHEAD_KB} KB"
  run "$ra_cmd"

  # Persist via udev
  local udev_rules="/etc/udev/rules.d/60-iosched-readahead.rules"
  local content=$(cat <<EOF
ACTION=="add|change", KERNEL=="$(basename "$devnode")", ATTR{queue/scheduler}="${IOSCHED}"
ACTION=="add|change", KERNEL=="$(basename "$devnode")", RUN+="/sbin/blockdev --setra ${READAHEAD_KB} /dev/%k"
EOF
)
  if [[ "$DRY_RUN" -eq 0 ]]; then
    echo "$content" > "$udev_rules"
    udevadm control --reload-rules
  else
    echo "DRY-RUN: would write $udev_rules:"
    echo "$content"
  fi
}

apply_sysctl() {
  log "Writing sysctl to ${SYSCTL_FILE}"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    echo "$SYSCTL_TUNING" > "$SYSCTL_FILE"
    sysctl --system >/dev/null || sysctl -p "$SYSCTL_FILE" || true
  else
    echo "DRY-RUN: would write ${SYSCTL_FILE}:"
    echo "$SYSCTL_TUNING"
  fi
}

setup_zram() {
  if ! systemctl list-unit-files | grep -q zram; then
    warn "zram-generator not found; install package if available on your distro."
  fi
  local cfg=$(cat <<EOF
[zram0]
zram-size = ${ZRAM_SIZE_EXPR}
compression-algorithm = ${ZRAM_ALGO}
swap-priority = ${ZRAM_PRIORITY}
EOF
)
  log "Configuring ZRAM at ${ZRAM_CFG}"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    echo "$cfg" > "$ZRAM_CFG"
    systemctl daemon-reload || true
    systemctl restart systemd-zram-setup@zram0.service || systemctl restart /dev/zram0.swap || true
  else
    echo "DRY-RUN: would write ${ZRAM_CFG}:"
    echo "$cfg"
  fi
}

enable_nvme_wce() {
  [[ "$ENABLE_NVME_WCE" -eq 1 ]] || return 0
  if ! command -v nvme >/dev/null 2>&1; then
    warn "nvme-cli not installed; skipping WCE"
    return 0
  fi
  # Try to enable WCE on the target or RAID members
  local targets=()
  if [[ "$USE_RAID0" -eq 1 ]]; then
    targets=("${NVME_DEVICES[@]}")
  else
    targets=("$TARGET_DEV")
  fi

  for d in "${targets[@]}"; do
    local node
    node="$(basename "$d")"
    # Map partition to parent if needed
    if [[ "$d" =~ p[0-9]+$ ]]; then
      d="/dev/${node%p*}"
    fi
    if [[ "$d" =~ /dev/nvme[0-9]+n[0-9]+ ]]; then
      log "Enabling NVMe Volatile Write Cache (WCE) on $d (feature 0x06)"
      run "nvme set-feature -f 0x06 -v 1 $d" || warn "Failed to set WCE on $d"
      run "nvme get-feature -f 0x06 -H $d" || true
    fi
  done
}

bench_smoke() {
  command -v fio >/dev/null 2>&1 || { warn "fio not installed; skipping benchmark"; return 0; }
  [[ -d "$MOUNT_POINT" ]] || return 0
  ok "Quick fio smoke test on ${MOUNT_POINT} (non-destructive temp file)"
  run "fio --name=seq-1m-rw --filename=${MOUNT_POINT}/fio-tempfile --size=2G --bs=1M --rw=readwrite --ioengine=io_uring --iodepth=32 --direct=1 --runtime=20 --time_based || true"
  run "rm -f ${MOUNT_POINT}/fio-tempfile || true"
}

print_summary() {
  echo
  ok "CONFIG SUMMARY"
  echo "  DRY_RUN           : $DRY_RUN"
  echo "  USE_RAID0         : $USE_RAID0"
  if [[ "$USE_RAID0" -eq 1 ]]; then
    echo "  RAID members      : ${NVME_DEVICES[*]}"
    echo "  XFS stripe        : su=${XFS_SU} sw=${XFS_SW}"
  else
    echo "  Target device     : ${TARGET_DEV}"
  fi
  echo "  Mount point       : ${MOUNT_POINT}"
  echo "  Mount opts        : ${MOUNT_OPTS}"
  echo "  IO scheduler      : ${IOSCHED}"
  echo "  Readahead (KB)    : ${READAHEAD_KB}"
  echo "  ZRAM              : size=${ZRAM_SIZE_EXPR} algo=${ZRAM_ALGO} prio=${ZRAM_PRIORITY}"
  echo "  Sysctl file       : ${SYSCTL_FILE}"
  echo "  Log               : ${LOG}"
  echo
}

main() {
  require_root
  : > "$LOG" || true
  print_summary
  install_packages

  local dev_for_fs=""
  if [[ "$USE_RAID0" -eq 1 ]]; then
    dev_for_fs="$(create_raid0 "${NVME_DEVICES[@]}")"
  else
    is_block "$TARGET_DEV" || die "Target device not found: $TARGET_DEV"
    ensure_not_mounted "$TARGET_DEV"
    dev_for_fs="$TARGET_DEV"
  fi

  # FORMAT filesystem
  mkfs_xfs "$dev_for_fs"

  # Mount & persist
  mount_and_persist "$dev_for_fs"

  # I/O scheduler + readahead (apply to backing devices)
  if [[ "$USE_RAID0" -eq 1 ]]; then
    for d in "${NVME_DEVICES[@]}"; do
      # scheduler applies to the disk, not md0
      set_iosched_and_readahead "$d"
    done
  else
    set_iosched_and_readahead "$dev_for_fs"
  fi

  # Sysctl tuning
  apply_sysctl

  # ZRAM
  setup_zram

  # NVMe WCE
  enable_nvme_wce

  # Quick fio
  bench_smoke

  ok "All steps complete."
  ok "If DRY_RUN=1, nothing was changed. Set DRY_RUN=0 and re-run to apply."
}

main "$@"
umask "$UMASK_OLD"
