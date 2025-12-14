#!/usr/bin/env bash
#
# archive-manager.sh — Advanced archive indexing, mounting & selective extraction tool
# Version: 2025-08-12
#
# Requirements:
#  - Linux (systemd-based preferred)
#  - sudo privileges for installing missing packages
#  - curl, jq, unzip, zip, tar, zstd, fuse-zip, ratarmount (auto installed if missing)
#
# Features:
#  - Index contents of ZIP or TAR.ZST archives to JSON file (fast queries)
#  - Mount archives via FUSE for transparent filesystem access
#  - Extract individual files on demand without full decompression
#  - Cleanly unmount and remove temporary resources
#
# Usage:
#   ./archive-manager.sh index <archive_path>
#   ./archive-manager.sh mount <archive_path> <mount_point>
#   ./archive-manager.sh extract <archive_path> <file_path_inside_archive> <output_path>
#   ./archive-manager.sh unmount <mount_point>
#   ./archive-manager.sh status <mount_point>
#
# Configurable variables below:

set -Eeuo pipefail
IFS=$'\n\t'

### CONFIGURATION - MODIFY THESE AS NEEDED ###
ARCHIVE_PATH=""           # e.g. /path/to/archive.zip or /path/to/archive.tar.zst
MOUNT_POINT=""            # e.g. /mnt/archive
INDEX_DIR="${HOME}/.archive_manager"
LOG_FILE="${INDEX_DIR}/archive_manager.log"
FORCE_INSTALL_PACKAGES=true   # set to false if you don't want auto-install
###############################################

### COLORS for output ###
c_ok="\e[32m"
c_warn="\e[33m"
c_err="\e[31m"
c_info="\e[36m"
c_end="\e[0m"

log()  { printf "%s %s\n" "$(date -Iseconds)" "$*" | tee -a "$LOG_FILE"; }
info() { printf "${c_ok}[INFO]${c_end} %s\n" "$*" | tee -a "$LOG_FILE"; }
warn() { printf "${c_warn}[WARN]${c_end} %s\n" "$*" | tee -a "$LOG_FILE"; }
err()  { printf "${c_err}[ERROR]${c_end} %s\n" "$*" | tee -a "$LOG_FILE"; }
info2() { printf "${c_info}[INFO]${c_end} %s\n" "$*" | tee -a "$LOG_FILE"; }

### Utils ###

check_command() {
  command -v "$1" >/dev/null 2>&1
}

sudo_install() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm "$@"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "$@"
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y "$@"
  else
    err "Unsupported package manager. Please install packages manually: $*"
    exit 1
  fi
}

auto_install_packages() {
  local missing=()
  for pkg in curl jq unzip zip tar zstd fuse-zip ratarmount; do
    if ! check_command "$pkg"; then
      missing+=("$pkg")
    fi
  done
  if (( ${#missing[@]} )); then
    warn "Missing packages: ${missing[*]}"
    if $FORCE_INSTALL_PACKAGES; then
      info "Installing missing packages via sudo..."
      sudo_install "${missing[@]}"
    else
      err "Packages missing and FORCE_INSTALL_PACKAGES=false. Please install manually: ${missing[*]}"
      exit 1
    fi
  else
    info "All required packages are installed."
  fi
}

index_zip() {
  local archive="$1"
  local index_file="$2"
  info "Indexing ZIP archive: $archive"
  # zipinfo outputs format: Length   Method   Size  Ratio   Date   Time   CRC-32   Name
  # We'll parse filename and size, date for each entry to JSON
  unzip -l "$archive" | tail -n +4 | head -n -2 | \
  awk 'BEGIN {print "["} \
  {gsub(/^ +| +$/,"",$0); if(length($0)>0) { \
    printf "%s{\"filename\":\"%s\",\"size\":%d}",sep,$4,$1; sep=","} } \
  END {print "]"}' > "$index_file"
  info "Index saved to $index_file"
}

index_tar_zst() {
  local archive="$1"
  local index_file="$2"
  info "Indexing TAR.ZST archive: $archive"
  # Use tar with zstd decompression, list files with sizes and timestamps
  tar --use-compress-program=unzstd -tvf "$archive" | \
  awk 'BEGIN {print "["} \
  {printf "%s{\"mode\":\"%s\",\"owner\":\"%s\",\"group\":\"%s\",\"size\":%d,\"date\":\"%s %s\",\"filename\":\"%s\"}", \
   sep,$1,$3,$4,$5,$6,$7,$8; sep=","} END {print "]"}' > "$index_file"
  info "Index saved to $index_file"
}

index_archive() {
  local archive="$1"
  mkdir -p "$INDEX_DIR"
  local idx_file="${INDEX_DIR}/$(basename "$archive").index.json"
  if [[ ! -f "$archive" ]]; then
    err "Archive $archive does not exist."
    exit 1
  fi
  case "$archive" in
    *.zip)   index_zip "$archive" "$idx_file" ;;
    *.tar.zst|*.tzst) index_tar_zst "$archive" "$idx_file" ;;
    *) err "Unsupported archive format for indexing: $archive"; exit 1 ;;
  esac
  info "Indexing complete. Index file: $idx_file"
}

mount_archive() {
  local archive="$1"
  local mountpoint="$2"
  if [[ ! -f "$archive" ]]; then
    err "Archive $archive does not exist."
    exit 1
  fi
  mkdir -p "$mountpoint"
  info "Mounting archive $archive at $mountpoint"
  case "$archive" in
    *.zip)
      if ! check_command fuse-zip; then
        err "fuse-zip not installed or not in PATH"
        exit 1
      fi
      fuse-zip "$archive" "$mountpoint"
      ;;
    *.tar.zst|*.tzst)
      if ! check_command ratarmount; then
        err "ratarmount not installed or not in PATH"
        exit 1
      fi
      ratarmount "$archive" "$mountpoint"
      ;;
    *)
      err "Unsupported archive format for mounting: $archive"
      exit 1
      ;;
  esac
  info "Mounted successfully."
}

extract_file() {
  local archive="$1"
  local file_in_archive="$2"
  local output_path="$3"
  if [[ ! -f "$archive" ]]; then
    err "Archive $archive does not exist."
    exit 1
  fi
  case "$archive" in
    *.zip)
      info "Extracting $file_in_archive from $archive to $output_path"
      unzip -p "$archive" "$file_in_archive" > "$output_path"
      ;;
    *.tar.zst|*.tzst)
      info "Extracting $file_in_archive from $archive to $output_path"
      tar --use-compress-program=unzstd -xOf "$archive" "$file_in_archive" > "$output_path"
      ;;
    *)
      err "Unsupported archive format for extraction: $archive"
      exit 1
      ;;
  esac
  info "Extraction complete."
}

unmount_archive() {
  local mountpoint="$1"
  if mountpoint -q "$mountpoint"; then
    info "Unmounting $mountpoint"
    fusermount -u "$mountpoint" || umount "$mountpoint"
    info "Unmounted successfully."
  else
    warn "$mountpoint is not a mountpoint"
  fi
}

status_mount() {
  local mountpoint="$1"
  if mountpoint -q "$mountpoint"; then
    info "$mountpoint is mounted:"
    mount | grep "on $mountpoint "
  else
    warn "$mountpoint is not mounted."
  fi
}

usage() {
  cat <<EOF
archive-manager.sh — Advanced archive index, mount & extract manager

Usage:
  $0 index <archive_path>              # Build index JSON for archive contents
  $0 mount <archive_path> <mount_pt>  # Mount archive transparently via FUSE
  $0 extract <archive_path> <file_inside_archive> <output_path>
                                      # Extract a single file from archive
  $0 unmount <mount_point>             # Unmount FUSE-mounted archive
  $0 status <mount_point>              # Show mount status of mount point

Notes:
- Supports ZIP and TAR.ZST archives
- Requires sudo for installing missing packages if FORCE_INSTALL_PACKAGES=true
- Index files stored at $INDEX_DIR as <archive_basename>.index.json
EOF
}

### Main ###

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

cmd="$1"; shift

auto_install_packages

case "$cmd" in
  index)
    if [[ $# -ne 1 ]]; then
      err "index requires 1 argument: archive_path"
      usage
      exit 1
    fi
    index_archive "$1"
    ;;
  mount)
    if [[ $# -ne 2 ]]; then
      err "mount requires 2 arguments: archive_path mount_point"
      usage
      exit 1
    fi
    mount_archive "$1" "$2"
    ;;
  extract)
    if [[ $# -ne 3 ]]; then
      err "extract requires 3 arguments: archive_path file_in_archive output_path"
      usage
      exit 1
    fi
    extract_file "$1" "$2" "$3"
    ;;
  unmount)
    if [[ $# -ne 1 ]]; then
      err "unmount requires 1 argument: mount_point"
      usage
      exit 1
    fi
    unmount_archive "$1"
    ;;
  status)
    if [[ $# -ne 1 ]]; then
      err "status requires 1 argument: mount_point"
      usage
      exit 1
    fi
    status_mount "$1"
    ;;
  *)
    err "Unknown command: $cmd"
    usage
    exit 1
    ;;
esac
