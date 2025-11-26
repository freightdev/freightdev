#!/usr/bin/env bash
# =============================================================================
# Host-aware NVMe + XFS performance tuner (Lenovo + ASUS profiles)
# Non-destructive: remounts/tunes only. No formatting.
# =============================================================================
set -euo pipefail

# ------------------------------ CONFIG ---------------------------------------
DRY_RUN=1                 # 1 = preview; 0 = apply
NON_INTERACTIVE=1         # 1 = no prompts

# Global mount options (runtime-safe; no mkfs needed)
# NOTE: logbsize is mkfs-time; we keep logbufs here (runtime), not logbsize.
MOUNT_OPTS_BASE="defaults,noatime,nodiratime,inode64,largeio,allocsize=64m,logbufs=8"

# Per-host overrides
HOSTNAME="$(hostname -s 2>/dev/null || hostname)"
case "$HOSTNAME" in
  echo-ops)   # Lenovo — Samsung PM9C1a (PCIe 4.0 x4, DRAM-less)
    NVME_DEV="/dev/nvme0n1"
    IO_SCHED="none"
    READAHEAD_KB=4096         # 4 MiB
    NVME_APST_LATENCY_US=0    # 0 = max performance (no APST)
    TARGET_MOUNTS=(/home /srv /var /opt)  # leave / alone if you want
    ;;
  archbox)    # ASUS — Crucial P3 / Micron 2550 (DRAM-less)
    NVME_DEV="/dev/nvme0n1"
    IO_SCHED="none"
    READAHEAD_KB=4096
    NVME_APST_LATENCY_US=0
    TARGET_MOUNTS=(/home /srv /var /opt)  # adjust if needed
    ;;
  *)
    # Fallback: detect first NVMe & all XFS mounts on it
    NVME_DEV="$(lsblk -ndo NAME,TYPE | awk '$2=="disk" && $1 ~ /^nvme/ {print "/dev/"$1; exit}')"
    IO_SCHED="none"
    READAHEAD_KB=4096
    NVME_APST_LATENCY_US=0
    # All mounted XFS (except /boot*/efi)
    mapfile -t TARGET_MOUNTS < <(findmnt -rn -t xfs | awk '!/\/boot|\/efi/ {print $1}')
    ;;
esac

# Sysctl tuning (balanced for throughput without insanity)
SYSCTL_FILE="/etc/sysctl.d/99-perf-io.conf"
read -r -d '' SYSCTL_TUNING <<'EOF'
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 40
vm.page-cluster = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
EOF

# zram via systemd zram-generator if available; otherwise best-effort skip
ZRAM_CFG="/etc/systemd/zram-generator.conf"
ZRAM_SIZE_EXPR="ram / 2"
ZRAM_ALGO="zstd"
ZRAM_PRIORITY=100
# -----------------------------------------------------------------------------

LOG="/var/log/nvme-xfs-tune.log"
: >"$LOG" || true
log()  { echo -e "[*] $*" | tee -a "$LOG"; }
ok()   { echo -e "[+] $*" | tee -a "$LOG"; }
warn() { echo -e "[!] $*" | tee -a "$LOG"; }
run()  { [[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN: $*" | tee -a "$LOG" || { echo "$*" >>"$LOG"; eval "$@"; } }

require_root() { [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }; }

edit_fstab_mountopts() {
  local mp="$1" opts="$2"
  # Get UUID for the backing device of mountpoint
  local src uuid fstype
  src="$(findmnt -no SOURCE "$mp" 2>/dev/null || true)" || true
  fstype="$(findmnt -no FSTYPE "$mp" 2>/dev/null || true)" || true
  [[ -z "$src" || -z "$fstype" ]] && { warn "Skip $mp (not mounted)."; return; }
  uuid="$(blkid -s UUID -o value "$src" 2>/dev/null || true)"
  [[ -z "$uuid" ]] && { warn "No UUID for $src, skipping fstab edit."; return; }

  local new="UUID=${uuid}  ${mp}  ${fstype}  ${opts}  0 0"
  if grep -qE "^[^#].*\s${mp}\s" /etc/fstab; then
    log "Updating /etc/fstab for $mp"
    run "cp /etc/fstab /etc/fstab.bak.$(date +%s)"
    run "sed -i \"/[[:space:]]$(echo "$mp" | sed 's,/,\\/,g')[[:space:]]/c ${new}\" /etc/fstab"
  else
    log "Appending fstab entry for $mp"
    run "bash -c 'echo \"$new\" >> /etc/fstab'"
  fi
}

remount_with_opts() {
  local mp="$1" opts="$2"
  if findmnt "$mp" >/dev/null 2>&1; then
    log "Remount $mp with: $opts"
    run "mount -o remount,${opts} ${mp}"
  else
    warn "$mp not mounted; skipping remount"
  fi
}

set_iosched_readahead() {
  local dev="$1"
  local base; base="$(basename "$dev")"
  local sched="/sys/block/${base}/queue/scheduler"
  [[ -e "$sched" ]] && run "bash -c 'echo ${IO_SCHED} > ${sched}'" || warn "No scheduler path $sched"
  run "blockdev --setra ${READAHEAD_KB} ${dev}"

  # Persist via udev
  local rules="/etc/udev/rules.d/60-iosched-readahead.rules"
  read -r -d '' CONTENT <<EOF
ACTION=="add|change", KERNEL=="${base}", ATTR{queue/scheduler}="${IO_SCHED}"
ACTION=="add|change", KERNEL=="${base}", RUN+="/sbin/blockdev --setra ${READAHEAD_KB} /dev/%k"
EOF
  run "bash -c 'printf \"%s\n\" \"$CONTENT\" > \"$rules\"'"
  run "udevadm control --reload-rules"
}

enable_wce_nvme() {
  if ! command -v nvme >/dev/null 2>&1; then warn "nvme-cli missing; skipping WCE"; return; fi
  local parent="$NVME_DEV"
  # If they pass a partition, strip to controller namespace
  [[ "$parent" =~ p[0-9]+$ ]] && parent="/dev/$(basename "$parent" | sed 's/p[0-9]\+$//')"
  log "Enable NVMe Volatile Write Cache (feature 0x06) on $parent"
  run "nvme set-feature -f 0x06 -v 1 ${parent} || true"
  run "nvme get-feature -f 0x06 -H ${parent} || true"
}

apst_to_performance() {
  # Disable NVMe APST or set max latency low for performance
  local param="/sys/module/nvme_core/parameters/default_ps_max_latency_us"
  if [[ -w "$param" ]]; then
    log "Setting NVMe APST latency to ${NVME_APST_LATENCY_US} us (performance)"
    run "bash -c 'echo ${NVME_APST_LATENCY_US} > ${param}'"
    # Persist in modprobe.d
    local cfg="/etc/modprobe.d/nvme_apst_performance.conf"
    run "bash -c 'echo options nvme_core default_ps_max_latency_us=${NVME_APST_LATENCY_US} > ${cfg}'"
  else
    warn "Cannot set APST (no $param); skipping"
  fi
}

apply_sysctl() {
  log "Apply sysctl to ${SYSCTL_FILE}"
  run "bash -c 'cat > ${SYSCTL_FILE} <<EOF
${SYSCTL_TUNING}
EOF'"
  run "sysctl -p ${SYSCTL_FILE} || sysctl --system || true"
}

enable_trim() {
  # enable weekly fstrim
  if systemctl list-unit-files | grep -q fstrim.timer; then
    log "Enable fstrim.timer"
    run "systemctl enable --now fstrim.timer"
  fi
}

setup_zram() {
  # Prefer systemd zram-generator
  if command -v zramctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q zram; then
    log "Configuring zram via zram-generator"
    read -r -d '' CFG <<EOF
[zram0]
zram-size = ${ZRAM_SIZE_EXPR}
compression-algorithm = ${ZRAM_ALGO}
swap-priority = ${ZRAM_PRIORITY}
EOF
    run "bash -c 'printf \"%s\n\" \"$CFG\" > ${ZRAM_CFG}'"
    run "systemctl daemon-reload || true"
    # Try both service names commonly seen
    run "systemctl restart systemd-zram-setup@zram0.service || systemctl restart /dev/zram0.swap || true"
    run "systemctl enable systemd-zram-setup@zram0.service || true"
  else
    warn "zram-generator not detected; skipping zram config"
  fi
}

install_tools() {
  if command -v pacman >/dev/null 2>&1; then
    run "pacman -Sy --noconfirm fio nvme-cli smartmontools util-linux bc"
  elif command -v apt-get >/dev/null 2>&1; then
    run "apt-get update"
    run "apt-get install -y fio nvme-cli smartmontools util-linux bc"
  elif command -v dnf >/dev/null 2>&1; then
    run "dnf install -y fio nvme-cli smartmontools util-linux bc"
  else
    warn "Unknown distro; install fio nvme-cli smartmontools util-linux bc manually"
  fi
}

smoke_fio() {
  command -v fio >/dev/null 2>&1 || { warn "fio missing; skip test"; return; }
  # Choose a mounted target with space
  local mp="${TARGET_MOUNTS[0]:-}"
  [[ -z "$mp" ]] && mp="/tmp"
  ok "Quick fio smoke (20s, 1MiB rw) on ${mp}"
  run "fio --name=seq-1m-rw --filename=${mp}/fio-tempfile --size=2G --bs=1M --rw=readwrite --ioengine=io_uring --iodepth=32 --direct=1 --runtime=20 --time_based || true"
  run "rm -f ${mp}/fio-tempfile || true"
}

# --------------------------------- MAIN --------------------------------------
require_root
ok "Host: ${HOSTNAME}"
ok "NVMe dev: ${NVME_DEV:-<auto>}"
ok "Targets: ${TARGET_MOUNTS[*]:-<auto>}"
ok "Mount opts: ${MOUNT_OPTS_BASE}"
ok "IO sched: ${IO_SCHED}, readahead=${READAHEAD_KB} KB"
ok "NVMe APST latency: ${NVME_APST_LATENCY_US} us (0 = perf)"

install_tools

# If TARGET_MOUNTS empty, derive all mounted XFS (skip /boot, /efi)
if [[ ${#TARGET_MOUNTS[@]} -eq 0 ]]; then
  mapfile -t TARGET_MOUNTS < <(findmnt -rn -t xfs | awk '!/\/boot|\/efi/ {print $1}')
fi

# Remount/ persist opts
for mp in "${TARGET_MOUNTS[@]}"; do
  remount_with_opts "$mp" "$MOUNT_OPTS_BASE"
  edit_fstab_mountopts "$mp" "$MOUNT_OPTS_BASE"
done

# Scheduler & readahead
if [[ -n "${NVME_DEV:-}" && -b "${NVME_DEV:-/nope}" ]]; then
  set_iosched_readahead "$NVME_DEV"
fi

# NVMe cache + APST perf
enable_wce_nvme
apst_to_performance

# Sysctl + trim + zram
apply_sysctl
enable_trim
setup_zram

# Quick fio
smoke_fio

ok "Done. Log: $LOG"
[[ $DRY_RUN -eq 1 ]] && warn "This was a DRY RUN. Set DRY_RUN=0 to apply."
