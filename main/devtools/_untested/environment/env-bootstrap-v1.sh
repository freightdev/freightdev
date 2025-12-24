#!/usr/bin/env bash
# env-bootstrap.sh — Portable, secure, idempotent environment bootstrapper
# Version: 0.1.0
# Shell: bash 4+ (set -Eeuo pipefail)
# License: MIT (yours to keep)

###############################################################################
# SAFETY, STRICTNESS, AND TRAPS
###############################################################################
set -Eeuo pipefail
IFS=$'\n\t'

# Fail-safe cleanup on error or ctrl+c
cleanup() {
  local ec=$?
  [[ ${ec} -ne 0 ]] && log_error "Aborted with exit code ${ec}."
  log_info "Cleanup complete."
}
trap cleanup EXIT
trap 'log_error "Interrupted"; exit 130' INT

###############################################################################
# CONFIG (EDIT HERE OR OVERRIDE VIA ENV/CLI)
###############################################################################
# REQUIRED-ish: Your GPG identity (key ID, fingerprint, or email). Used to decrypt & lock secrets.
: "${GPG_ID:=}"                 # e.g., export GPG_ID="YOURKEYIDORMAIL"
# Optional: Path to your private key (ASCII-armored) if you need to import it on a fresh box
: "${GPG_PRIVATE_KEY_FILE:=}"   # e.g., ~/.keys/my-private-key.asc
# Optional: Passphrase file for non-interactive secret ops (store securely)
: "${GPG_PASSPHRASE_FILE:=}"    # e.g., ~/.keys/my-private-key.pass

# Repo source. If REPO_URL is set, we clone there; otherwise we use current dir.
: "${REPO_URL:=}"               # e.g., "https://github.com/you/your-dotfiles.git"
: "${REPO_BRANCH:=main}"
: "${REPO_DIR:=$HOME/.bootstrap/env}"

# Where we stage and track things
: "${STATE_DIR:=$HOME/.env-bootstrap}"
: "${BACKUP_DIR:=$STATE_DIR/backups}"
: "${MANIFEST_DIR:=$STATE_DIR/manifests}"
: "${LOG_DIR:=$STATE_DIR/logs}"
: "${SECRETS_DST_DIR:=$HOME/.secrets}"        # decrypted secrets land here
: "${BIN_DST_DIR:=$HOME/.local/bin}"          # user bin
: "${SYMLINK_MODE:=copy}"                     # "link" or "copy" (copy is safer; link is dynamic)
: "${DRY_RUN:=0}"                             # 1 = show actions only
: "${PURGE_PACKAGES_ON_UNINSTALL:=0}"         # dangerous: removes pkgs it installed

# Dotfiles layout inside the repo (default conventions)
: "${DOTFILES_DIR:=dotfiles}"                 # files to link/copy to $HOME or ~/.config
: "${DOTFILES_MAP_FILE:=${DOTFILES_DIR}/map.txt}" # mapping (src -> dest) lines (space or tab)
: "${TOOLS_DIR:=tools}"                       # per-tool installers live in tools/*/install.sh
: "${SECRETS_DIR:=secrets}"                   # encrypted secrets (*.gpg) live here

# Package sets (tune as needed). Keys are abstract package names; resolver maps per-OS.
COMMON_PACKAGES=(
  git curl unzip tar rsync gnupg stow jq coreutils findutils gawk sed
)
DEV_PACKAGES=(
  make gcc pkg-config
)
EXTRA_PACKAGES=(
  openssh tmux ripgrep fzf tree direnv
)

# Services or daemons to enable/launch per OS (optional hooks)
SYSTEMD_SERVICES=( )     # e.g., ["docker","podman"]
LAUNCHCTL_SERVICES=( )   # macOS plist labels if you include them

###############################################################################
# LOGGING
###############################################################################
log_ts() { date +"%Y-%m-%dT%H:%M:%S%z"; }
log()     { printf "[%s] %s\n" "$(log_ts)" "$*"; }
log_info(){ log "INFO  $*"; }
log_warn(){ log "WARN  $*"; }
log_error(){ log "ERROR $*" >&2; }
die()     { log_error "$*"; exit 1; }

maybe() { [[ "${DRY_RUN}" == "1" ]] && printf "(dry-run) "; }

###############################################################################
# SUDO / PRIVILEGES
###############################################################################
need_sudo() {
  if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      echo sudo
    else
      die "sudo not available and not root. Install sudo or run as root."
    fi
  fi
}

###############################################################################
# OS / DISTRO DETECTION
###############################################################################
OS_FAMILY=""
OS_ID=""
OS_VERSION=""
IS_WSL=0
IS_MAC=0
detect_os() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    OS_FAMILY="macos"; IS_MAC=1
    OS_ID="macos"
    OS_VERSION="$(sw_vers -productVersion || true)"
  elif [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-linux}"
    OS_VERSION="${VERSION_ID:-}"
    OS_FAMILY="$(
      case "${ID_LIKE:-$ID}" in
        *debian*|*ubuntu*) echo "debian" ;;
        *rhel*|*fedora*|*centos*) echo "rhel" ;;
        *arch*) echo "arch" ;;
        *suse*) echo "suse" ;;
        *alpine*) echo "alpine" ;;
        *) echo "linux" ;;
      esac
    )"
  else
    die "Unsupported OS. No /etc/os-release and not macOS."
  fi

  # WSL detection
  if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    IS_WSL=1
  fi

  log_info "Detected OS: family=${OS_FAMILY} id=${OS_ID} version=${OS_VERSION} wsl=${IS_WSL} mac=${IS_MAC}"
}

###############################################################################
# PACKAGE MANAGER ABSTRACTION
###############################################################################
pkg_update() {
  case "$OS_FAMILY" in
    debian) $(need_sudo) apt-get update -y ;;
    rhel)   $(need_sudo) dnf makecache -y || $(need_sudo) yum makecache -y ;;
    arch)   $(need_sudo) pacman -Sy --noconfirm ;;
    suse)   $(need_sudo) zypper refresh ;;
    alpine) $(need_sudo) apk update ;;
    macos)  true ;;
    *)      die "pkg_update: unsupported family $OS_FAMILY" ;;
  esac
}

pkg_install() {
  local pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  case "$OS_FAMILY" in
    debian) maybe; $(need_sudo) apt-get install -y "${pkgs[@]}" ;;
    rhel)   maybe; $(need_sudo) dnf install -y "${pkgs[@]}" 2>/dev/null || $(need_sudo) yum install -y "${pkgs[@]}" ;;
    arch)   maybe; $(need_sudo) pacman -S --noconfirm --needed "${pkgs[@]}" ;;
    suse)   maybe; $(need_sudo) zypper install -y "${pkgs[@]}" ;;
    alpine) maybe; $(need_sudo) apk add --no-cache "${pkgs[@]}" ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
      fi
      maybe; brew install "${pkgs[@]}" || true
      ;;
    *) die "pkg_install: unsupported family $OS_FAMILY" ;;
  end
}

pkg_remove() {
  local pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  case "$OS_FAMILY" in
    debian) maybe; $(need_sudo) apt-get remove -y "${pkgs[@]}" ;;
    rhel)   maybe; $(need_sudo) dnf remove -y "${pkgs[@]}" 2>/dev/null || $(need_sudo) yum remove -y "${pkgs[@]}" ;;
    arch)   maybe; $(need_sudo) pacman -Rns --noconfirm "${pkgs[@]}" ;;
    suse)   maybe; $(need_sudo) zypper remove -y "${pkgs[@]}" ;;
    alpine) maybe; $(need_sudo) apk del "${pkgs[@]}" ;;
    macos)  maybe; brew uninstall "${pkgs[@]}" || true ;;
    *) die "pkg_remove: unsupported family $OS_FAMILY" ;;
  esac
}

###############################################################################
# RESOLVE PACKAGE NAMES PER OS
###############################################################################
resolve_packages() {
  # Map abstract names -> actual per OS if they differ, else keep name.
  local name="$1"
  case "$OS_FAMILY" in
    debian)
      case "$name" in
        coreutils)    echo "coreutils" ;;
        findutils)    echo "findutils" ;;
        sed)          echo "sed" ;;
        gawk)         echo "gawk" ;;
        stow)         echo "stow" ;;
        *)            echo "$name" ;;
      esac
      ;;
    rhel|suse|alpine|arch|macos)
      echo "$name"
      ;;
    *) echo "$name" ;;
  esac
}

expand_package_set() {
  local -n setref=$1
  local out=()
  for p in "${setref[@]}"; do
    out+=( "$(resolve_packages "$p")" )
  done
  printf "%s\n" "${out[@]}"
}

###############################################################################
# GPG / SECRETS
###############################################################################
gpg_ensure_key() {
  command -v gpg >/dev/null 2>&1 || die "gpg not installed"
  if [[ -n "${GPG_PRIVATE_KEY_FILE}" && ! -s "${GPG_PRIVATE_KEY_FILE}" ]]; then
    die "GPG_PRIVATE_KEY_FILE is set but file not found: ${GPG_PRIVATE_KEY_FILE}"
  fi

  if [[ -n "${GPG_ID}" ]]; then
    if ! gpg --list-keys "${GPG_ID}" >/dev/null 2>&1; then
      if [[ -n "${GPG_PRIVATE_KEY_FILE}" ]]; then
        log_info "Importing GPG private key for ${GPG_ID}..."
        if [[ -n "${GPG_PASSPHRASE_FILE}" && -f "${GPG_PASSPHRASE_FILE}" ]]; then
          gpg --pinentry-mode loopback --passphrase-file "${GPG_PASSPHRASE_FILE}" --import "${GPG_PRIVATE_KEY_FILE}"
        else
          gpg --import "${GPG_PRIVATE_KEY_FILE}"
        fi
      else
        log_warn "No local key for ${GPG_ID}; secrets decryption may be skipped."
      fi
    fi
  else
    log_warn "GPG_ID not set; will skip secrets."
  fi
}

decrypt_secrets() {
  [[ -z "${GPG_ID}" ]] && { log_warn "Skipping secrets: GPG_ID not set"; return 0; }
  [[ ! -d "${REPO_DIR}/${SECRETS_DIR}" ]] && { log_info "No secrets dir found."; return 0; }

  mkdir -p "${SECRETS_DST_DIR}"
  local manifest="${MANIFEST_DIR}/secrets.manifest"
  : > "${manifest}"

  shopt -s nullglob
  for enc in "${REPO_DIR}/${SECRETS_DIR}"/*.gpg; do
    local base; base="$(basename "${enc}" .gpg)"
    local out="${SECRETS_DST_DIR}/${base}"
    log_info "Decrypting secret: ${base}"
    if [[ -n "${GPG_PASSPHRASE_FILE}" && -f "${GPG_PASSPHRASE_FILE}" ]]; then
      maybe; gpg --quiet --yes --pinentry-mode loopback --passphrase-file "${GPG_PASSPHRASE_FILE}" -o "${out}" -d "${enc}"
    else
      maybe; gpg --quiet --yes -o "${out}" -d "${enc}"
    fi
    chmod 600 "${out}"
    echo "${out}" >> "${manifest}"
  done
  shopt -u nullglob
}

encrypt_secret_file() {
  local src="$1"
  [[ -z "${GPG_ID}" ]] && die "Set GPG_ID to lock secrets."
  [[ ! -f "${src}" ]] && die "Secret file not found: ${src}"
  local dst="${REPO_DIR}/${SECRETS_DIR}/$(basename "${src}").gpg"
  mkdir -p "${REPO_DIR}/${SECRETS_DIR}"
  log_info "Encrypting ${src} -> ${dst}"
  maybe; gpg --yes --encrypt --recipient "${GPG_ID}" -o "${dst}" "${src}"
  log_info "Encrypted. You can now remove the plaintext and keep only ${dst}."
}

shred_secrets() {
  local manifest="${MANIFEST_DIR}/secrets.manifest"
  [[ -f "${manifest}" ]] || { log_info "No decrypted secrets tracked."; return 0; }
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    log_warn "Shredding secret: $f"
    maybe; command -v shred >/dev/null 2>&1 && shred -u -z -n 3 "$f" || rm -f "$f"
  done < "${manifest}"
  rm -f "${manifest}"
}

###############################################################################
# REPO SYNC
###############################################################################
ensure_repo() {
  if [[ -n "${REPO_URL}" ]]; then
    if [[ -d "${REPO_DIR}/.git" ]]; then
      log_info "Repo exists at ${REPO_DIR}; pulling ${REPO_BRANCH}..."
      ( cd "${REPO_DIR}" && maybe; git fetch --all --tags && git checkout "${REPO_BRANCH}" && git pull --rebase )
    else
      log_info "Cloning ${REPO_URL} -> ${REPO_DIR}"
      mkdir -p "$(dirname "${REPO_DIR}")"
      maybe; git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${REPO_DIR}"
    fi
  else
    # Use current dir
    REPO_DIR="$(pwd)"
    log_info "Using current directory as REPO_DIR=${REPO_DIR}"
  fi
}

###############################################################################
# LINK/COPY DOTFILES WITH BACKUPS + MANIFEST
###############################################################################
timestamp() { date +"%Y%m%d-%H%M%S"; }

backup_path_for() {
  local dst="$1"
  local t; t="$(timestamp)"
  local rel="${dst/#$HOME\//}"   # strip home prefix for shape
  echo "${BACKUP_DIR}/${t}/${rel}"
}

install_dotfile_entry() {
  local src_rel="$1"; shift
  local dst="$1";     shift

  local src="${REPO_DIR}/${DOTFILES_DIR}/${src_rel}"
  [[ -e "${src}" ]] || { log_warn "Dotfile source missing: ${src_rel}"; return 0; }

  mkdir -p "${MANIFEST_DIR}"
  mkdir -p "${BACKUP_DIR}"
  mkdir -p "$(dirname "${dst}")"

  # Backup if exists and not already our link/copy
  if [[ -e "${dst}" && ! ( -L "${dst}" && "$(readlink "${dst}")" == "${src}" ) ]]; then
    local bak; bak="$(backup_path_for "${dst}")"
    log_warn "Backing up existing ${dst} -> ${bak}"
    mkdir -p "$(dirname "${bak}")"
    maybe; rsync -a "${dst}" "${bak}"
  fi

  case "${SYMLINK_MODE}" in
    link)
      if [[ -L "${dst}" ]]; then
        log_info "Updating symlink ${dst} -> ${src}"
        maybe; ln -sfn "${src}" "${dst}"
      else
        log_info "Linking ${dst} -> ${src}"
        maybe; ln -sfn "${src}" "${dst}"
      fi
      ;;
    copy)
      log_info "Copying ${src} -> ${dst}"
      maybe; rsync -a --delete "${src}/" "${dst}/" 2>/dev/null || maybe rsync -a "${src}" "${dst}"
      ;;
    *)
      die "Unknown SYMLINK_MODE: ${SYMLINK_MODE}"
      ;;
  esac

  echo "${dst}" >> "${MANIFEST_DIR}/dotfiles.manifest"
}

install_dotfiles() {
  [[ -d "${REPO_DIR}/${DOTFILES_DIR}" ]] || { log_info "No dotfiles directory."; return 0; }
  local mapfile="${REPO_DIR}/${DOTFILES_MAP_FILE}"
  if [[ -f "${mapfile}" ]]; then
    while IFS=$'\t ' read -r src_rel dst; do
      [[ -z "${src_rel}" || "${src_rel:0:1}" == "#" ]] && continue
      # Expand ~ in destination
      dst="${dst/#\~/$HOME}"
      install_dotfile_entry "${src_rel}" "${dst}"
    done < "${mapfile}"
  else
    # default behavior: mirror to ~/.config/<name> for directories, or ~ for files
    find "${REPO_DIR}/${DOTFILES_DIR}" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' path; do
      local base; base="$(basename "${path}")"
      if [[ -d "${path}" ]]; then
        install_dotfile_entry "${base}" "${HOME}/.config/${base}"
      else
        install_dotfile_entry "${base}" "${HOME}/.${base}"
      fi
    done
  fi
}

###############################################################################
# USER BIN + TOOLS
###############################################################################
install_user_bin() {
  mkdir -p "${BIN_DST_DIR}"
  echo "${BIN_DST_DIR}" >> "${MANIFEST_DIR}/paths.manifest"
  if [[ -d "${REPO_DIR}/bin" ]]; then
    log_info "Syncing user bin -> ${BIN_DST_DIR}"
    maybe; rsync -a "${REPO_DIR}/bin/" "${BIN_DST_DIR}/"
    chmod -R u+rx,go-rwx "${BIN_DST_DIR}" || true
  fi
}

run_tool_installers() {
  [[ -d "${REPO_DIR}/${TOOLS_DIR}" ]] || { log_info "No ${TOOLS_DIR}/ found"; return 0; }
  find "${REPO_DIR}/${TOOLS_DIR}" -mindepth 2 -maxdepth 2 -type f -name "install.sh" -print0 | while IFS= read -r -d '' script; do
    log_info "Running tool installer: ${script#${REPO_DIR}/}"
    chmod +x "${script}"
    if [[ "${DRY_RUN}" == "1" ]]; then
      echo "(dry-run) ${script} --non-interactive || true"
    else
      "${script}" --non-interactive || true
    fi
    echo "${script}" >> "${MANIFEST_DIR}/tools.manifest"
  done
}

###############################################################################
# SERVICES
###############################################################################
enable_services() {
  if [[ "${OS_FAMILY}" != "macos" && ${#SYSTEMD_SERVICES[@]} -gt 0 ]]; then
    for svc in "${SYSTEMD_SERVICES[@]}"; do
      log_info "Enabling systemd service: ${svc}"
      maybe; $(need_sudo) systemctl enable --now "${svc}" || true
    done
  fi
  if [[ "${OS_FAMILY}" == "macos" && ${#LAUNCHCTL_SERVICES[@]} -gt 0 ]]; then
    for label in "${LAUNCHCTL_SERVICES[@]}"; do
      log_info "Loading launchctl service: ${label}"
      maybe; launchctl load -w "${label}" || true
    done
  fi
}

###############################################################################
# PERMISSIONS HARDENING
###############################################################################
harden_permissions() {
  umask 077
  mkdir -p "${SECRETS_DST_DIR}" "${BIN_DST_DIR}"
  chmod 700 "${SECRETS_DST_DIR}" "${BIN_DST_DIR}" || true
  [[ -d "$HOME/.ssh" ]] && chmod 700 "$HOME/.ssh" && chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
}

###############################################################################
# INSTALL / UPDATE / UNINSTALL
###############################################################################
install_all() {
  detect_os
  mkdir -p "${STATE_DIR}" "${BACKUP_DIR}" "${MANIFEST_DIR}" "${LOG_DIR}"
  harden_permissions
  ensure_repo

  # Base packages
  pkg_update
  mapfile -t pkgs_common < <(expand_package_set COMMON_PACKAGES)
  mapfile -t pkgs_dev    < <(expand_package_set DEV_PACKAGES)
  mapfile -t pkgs_extra  < <(expand_package_set EXTRA_PACKAGES)
  pkg_install "${pkgs_common[@]}" "${pkgs_dev[@]}" "${pkgs_extra[@]}"

  # GPG + secrets
  gpg_ensure_key
  decrypt_secrets

  # Dotfiles & bin
  install_dotfiles
  install_user_bin

  # Per-tool installers
  run_tool_installers

  # Services
  enable_services

  # Final message
  log_info "Install complete."
  log_info "Manifests under: ${MANIFEST_DIR}"
  log_info "Backups under:   ${BACKUP_DIR}"
}

update_all() {
  detect_os
  ensure_repo
  pkg_update
  # Re-run installers and dotfiles (idempotent)
  decrypt_secrets
  install_dotfiles
  install_user_bin
  run_tool_installers
  enable_services
  log_info "Update complete."
}

uninstall_all() {
  log_warn "Starting uninstall — tracked files only."
  # Remove dotfiles we managed
  local mf="${MANIFEST_DIR}/dotfiles.manifest"
  if [[ -f "${mf}" ]]; then
    tac "${mf}" | while IFS= read -r dst; do
      [[ -z "${dst}" ]] && continue
      if [[ -L "${dst}" ]]; then
        log_info "Unlink ${dst}"
        maybe; rm -f "${dst}"
      elif [[ -e "${dst}" ]]; then
        log_info "Remove ${dst}"
        maybe; rm -rf "${dst}"
      fi
    done
    rm -f "${mf}"
  fi

  # Remove user bin files we synced
  if [[ -d "${BIN_DST_DIR}" && -f "${REPO_DIR}/bin/.bootstrap-owned" ]]; then
    log_info "Removing repo-owned binaries from ${BIN_DST_DIR}"
    while IFS= read -r f; do
      [[ -f "${BIN_DST_DIR}/${f}" ]] && { maybe; rm -f "${BIN_DST_DIR}/${f}"; }
    done < "${REPO_DIR}/bin/.bootstrap-owned"
  fi

  # Shred secrets
  shred_secrets

  # Optional: remove packages
  if [[ "${PURGE_PACKAGES_ON_UNINSTALL}" == "1" ]]; then
    detect_os
    mapfile -t pkgs_common < <(expand_package_set COMMON_PACKAGES)
    mapfile -t pkgs_dev    < <(expand_package_set DEV_PACKAGES)
    mapfile -t pkgs_extra  < <(expand_package_set EXTRA_PACKAGES)
    pkg_remove "${pkgs_extra[@]}" "${pkgs_dev[@]}" "${pkgs_common[@]}" || true
  fi

  log_info "Uninstall complete (tracked artifacts removed)."
}

doctor() {
  detect_os
  log_info "Shell: $SHELL"
  command -v git >/dev/null 2>&1 || log_warn "git missing"
  command -v gpg >/dev/null 2>&1 || log_warn "gpg missing"
  [[ -n "${GPG_ID}" ]] || log_warn "GPG_ID not set"
  echo "STATE_DIR: ${STATE_DIR}"
  echo "REPO_DIR:  ${REPO_DIR}"
  echo "WSL: ${IS_WSL}  macOS: ${IS_MAC}  OS_FAMILY: ${OS_FAMILY}"
}

###############################################################################
# CLI / HELP
###############################################################################
usage() {
  cat <<'EOF'
env-bootstrap.sh — portable environment bootstrapper

USAGE:
  env-bootstrap.sh [command] [--flags]

COMMANDS:
  install            Run full installation (idempotent).
  update             Pull repo (if REPO_URL) and re-apply installers, dotfiles.
  uninstall          Remove tracked artifacts; optionally remove packages.
  doctor             Print diagnostics.
  lock <file>        Encrypt (lock) a plaintext secret file into REPO/secrets/.
  dry-run <command>  Show actions without changing the system (install/update).

COMMON ENV VARS (override as needed):
  GPG_ID="your@identity"              GPG identity for secrets.
  GPG_PRIVATE_KEY_FILE="~/.keys/key.asc"
  GPG_PASSPHRASE_FILE="~/.keys/key.pass"
  REPO_URL="https://..."              If set, clone/pull here:
  REPO_DIR="$HOME/.bootstrap/env"
  REPO_BRANCH="main"
  DOTFILES_DIR="dotfiles"             Source of configs inside repo.
  DOTFILES_MAP_FILE="dotfiles/map.txt"  Optional mapping file: "src  dest"
  TOOLS_DIR="tools"                   Per-tool installers: tools/*/install.sh
  SECRETS_DIR="secrets"               Encrypted files end with .gpg
  SECRETS_DST_DIR="$HOME/.secrets"    Decrypt destination
  SYMLINK_MODE="copy"                 "copy" (safe) or "link" (live)
  DRY_RUN=0                           1 to simulate actions
  PURGE_PACKAGES_ON_UNINSTALL=0       Danger: 1 removes installed packages

EXAMPLES:
  GPG_ID="me@example.com" REPO_URL="https://github.com/me/dotfiles.git" \
    bash env-bootstrap.sh install

  GPG_ID="me@example.com" bash env-bootstrap.sh lock ~/.ssh/id_ed25519

  DRY_RUN=1 bash env-bootstrap.sh install

EOF
}

###############################################################################
# ENTRYPOINT
###############################################################################
main() {
  local cmd="${1:-}"
  shift || true

  case "${cmd}" in
    install)
      install_all
      ;;
    update)
      update_all
      ;;
    uninstall)
      uninstall_all
      ;;
    doctor)
      doctor
      ;;
    lock)
      [[ $# -ge 1 ]] || die "lock requires a path to a file"
      ensure_repo
      encrypt_secret_file "$1"
      ;;
    dry-run)
      DRY_RUN=1; export DRY_RUN
      local sub="${1:-install}"; shift || true
      case "${sub}" in
        install) install_all ;;
        update)  update_all ;;
        *) die "dry-run only supports: install | update" ;;
      esac
      ;;
    ""|help|-h|--help)
      usage
      ;;
    *)
      die "Unknown command: ${cmd}"
      ;;
  esac
}

main "$@"
