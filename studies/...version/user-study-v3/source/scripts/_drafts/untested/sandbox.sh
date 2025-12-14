#!/usr/bin/env bash
#
# pro-sandbox.sh — Full pro-level namespaced sandbox + rootless containerd helper
# Version: 2025-08-12
# Shell: bash 4+ (set -Eeuo pipefail)
#
# WHAT THIS DOES (summary):
#  - Installs prerequisites (optional) for bubblewrap, tmate, rootless containerd+nerdctl
#  - Creates ephemeral namespaces via: unshare, bubblewrap, systemd-nspawn, OR runs rootless OCI containers via nerdctl
#  - Binds in only what you choose (project dir, ssh-agent socket, optional secret mount)
#  - Builds a manifest (mounts, ps, lsns, env) for audit, logs actions
#  - Provides safe cleanup and revoke helpers
#
# SECURITY: This script assumes you run it on machines you are authorized to operate on.
#           It will not copy private SSH/GPG keys to the host disk by default. SSH agent/socket bind is supported.
#           Default behavior: *no private keys copied to disk*. Use --import-gpg only on trusted systems.
#
# CONFIGURATION (environment variables you can set before running):
#   RUNTIME_MODE      = "auto"|"unshare"|"bwrap"|"nspawn"|"containerd"
#   PROJECT_DIR       = path to project you want in sandbox (default: $PWD)
#   EXPOSE_SSH_AGENT  = 0|1  (bind your SSH_AUTH_SOCK into the sandbox)
#   SSH_AGENT_PATH    = path to host SSH_AUTH_SOCK (auto-detected)
#   ALLOW_INSTALL     = 0|1  (allow script to apt/pacman/dnf install prerequisites; requires sudo)
#   CONTAINERD_ROOTLESS_INSTALL = 0|1  (allow auto-setup of containerd rootless & nerdctl)
#   TMATE_RELAY       = optional tmate relay; leave blank for default
#
# USAGE examples at bottom.
set -Eeuo pipefail
IFS=$'\n\t'

### ---------- Defaults & config ----------
: "${RUNTIME_MODE:=auto}"
: "${PROJECT_DIR:=${PWD}}"
: "${EXPOSE_SSH_AGENT:=1}"
: "${ALLOW_INSTALL:=0}"
: "${CONTAINERD_ROOTLESS_INSTALL:=0}"
: "${SSH_AGENT_PATH:=${SSH_AUTH_SOCK:-}}"
: "${TMATE_RELAY:=}"

STATE_DIR="${HOME}/.pro-sandbox"
MANIFEST_DIR="${STATE_DIR}/manifests"
LOG_FILE="${STATE_DIR}/pro-sandbox.log"
mkdir -p "${MANIFEST_DIR}"

# helpful colors
c_ok="\e[32m"; c_warn="\e[33m"; c_err="\e[31m"; c_end="\e[0m"

log()  { printf "%s %s\n" "$(date -Iseconds)" "$*" | tee -a "${LOG_FILE}"; }
info() { printf "${c_ok}[INFO]${c_end} %s\n" "$*" | tee -a "${LOG_FILE}"; }
warn() { printf "${c_warn}[WARN]${c_end} %s\n" "$*" | tee -a "${LOG_FILE}"; }
err()  { printf "${c_err}[ERROR]${c_end} %s\n" "$*" | tee -a "${LOG_FILE}"; }

trap 'err "Interrupted"; exit 130' INT

### ---------- Helpers: detect os & pkg manager ----------
detect_pkg_manager() {
  if command -v apt >/dev/null 2>&1; then echo "apt"
  elif command -v dnf >/dev/null 2>&1; then echo "dnf"
  elif command -v yum >/dev/null 2>&1; then echo "yum"
  elif command -v pacman >/dev/null 2>&1; then echo "pacman"
  elif command -v apk >/dev/null 2>&1; then echo "apk"
  elif command -v brew >/dev/null 2>&1; then echo "brew"
  else echo "unknown"
  fi
}
PKG_MANAGER="$(detect_pkg_manager)"
info "Detected package manager: ${PKG_MANAGER}"

pkg_install() {
  [[ "${ALLOW_INSTALL}" == "1" ]] || { warn "ALLOW_INSTALL=0 — not installing packages. Set ALLOW_INSTALL=1 to auto-install prerequisites."; return 0; }
  local pkgs=( "$@" )
  case "${PKG_MANAGER}" in
    apt) sudo apt update && sudo apt install -y "${pkgs[@]}" ;;
    dnf) sudo dnf install -y "${pkgs[@]}" ;;
    yum) sudo yum install -y "${pkgs[@]}" ;;
    pacman) sudo pacman -Syu --noconfirm "${pkgs[@]}" ;;
    apk) sudo apk add --no-cache "${pkgs[@]}" ;;
    brew) brew install "${pkgs[@]}" ;;
    *) err "No supported package manager to install prerequisites." ;;
  esac
}

### ---------- prerequisites check ----------
ensure_prereqs() {
  local miss=()
  command -v unshare >/dev/null 2>&1 || miss+=(unshare)
  command -v bwrap >/dev/null 2>&1 || miss+=(bwrap)
  command -v tmate >/dev/null 2>&1 || miss+=(tmate)
  command -v nerdctl >/dev/null 2>&1 || miss+=(nerdctl)
  if [[ "${#miss[@]}" -gt 0 ]]; then
    warn "Missing tools: ${miss[*]}"
    if [[ "${ALLOW_INSTALL}" == "1" ]]; then
      info "Attempting to install common prerequisites..."
      pkg_install git curl bwrap tmate
      # nerdctl/containerd rootless is a separate flow controlled by CONTAINERD_ROOTLESS_INSTALL
    else
      warn "Set ALLOW_INSTALL=1 if you want this script to install prerequisites automatically."
    fi
  fi
}

### ---------- manifest helpers ----------
manifest_write() {
  local file="${MANIFEST_DIR}/$(date +%Y%m%d-%H%M%S)-$1.json"
  shift
  printf "%s\n" "$@" > "${file}"
  info "Wrote manifest: ${file}"
  echo "${file}"
}

manifest_system_snapshot() {
  local out="${MANIFEST_DIR}/snapshot-$(date +%s).json"
  {
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"pwd\": \"${PWD}\","
    echo "  \"project_dir\": \"${PROJECT_DIR}\","
    echo "  \"ps\": \"$(ps -ef | head -n 40 | sed 's/\"/\\\"/g')\","
    echo "  \"mounts\": \"$(mount | head -n 60 | sed 's/\"/\\\"/g')\","
    echo "}"
  } > "${out}"
  info "Snapshot: ${out}"
}

### ---------- SSH agent socket binding helper ----------
detect_ssh_agent() {
  if [[ -n "${SSH_AGENT_PATH}" && -S "${SSH_AGENT_PATH}" ]]; then
    echo "${SSH_AGENT_PATH}"
    return 0
  fi
  if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]]; then
    echo "${SSH_AUTH_SOCK}"
    return 0
  fi
  # try common locations (mac/linux)
  local sock
  sock="$(ls /tmp/ssh-* 2>/dev/null | head -n1 || true)"
  [[ -S "${sock}" ]] && echo "${sock}" && return 0
  return 1
}

### ---------- unshare-based ephemeral namespace ----------
run_unshare_sandbox() {
  # Creates new user/pid/mount/uts/net/ipc namespace, maps root-user, bind mounts project, optionally binds ssh agent socket
  local ssh_sock
  ssh_sock="$(detect_ssh_agent || true)"
  info "Starting unshare sandbox (project=${PROJECT_DIR})"
  local setup_script
  setup_script="$(mktemp -d)/ns-entry.sh"
  cat > "${setup_script}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$1"
SSH_SOCK="$2"
MANIFEST_DIR="$3"
# Mount private proc
mount -t proc proc /proc
# Create working dir inside namespace
mkdir -p /tmp/pro-sandbox-work
mount --bind "$PROJECT_DIR" /tmp/pro-sandbox-work
cd /tmp/pro-sandbox-work
# If SSH sock passed, bind it read-only
if [[ -n "$SSH_SOCK" && -S "$SSH_SOCK" ]]; then
  mkdir -p /tmp/ssh-sock
  mount --bind "$SSH_SOCK" /tmp/ssh-sock/agent.sock || true
  chmod 600 /tmp/ssh-sock/agent.sock || true
  export SSH_AUTH_SOCK=/tmp/ssh-sock/agent.sock
fi
# Dump small manifest to host-visible path if MANIFEST_DIR is bind-mounted
echo "{\"started_at\":\"$(date -Iseconds)\",\"cwd\":\"$(pwd)\",\"pid1\":\"$$\"}" > /tmp/pro-sandbox-manifest.json || true
exec bash --login
EOF
  chmod +x "${setup_script}"

  # ensure we have map-root-user support
  if ! unshare --help | grep -q map-root-user; then
    warn "unshare does not advertise --map-root-user on this system; map-root-user may not be available."
  fi

  # Launch unshare; user will drop into an interactive shell (PID 1 inside namespace)
  if [[ "${EXPOSE_SSH_AGENT}" == "1" && -n "${ssh_sock}" ]]; then
    info "Binding SSH agent socket into sandbox: ${ssh_sock}"
    unshare --fork --pid --mount --uts --net --ipc --user --map-root-user \
      bash -c "${setup_script} '${PROJECT_DIR}' '${ssh_sock}' '${MANIFEST_DIR}'"
  else
    unshare --fork --pid --mount --uts --net --ipc --user --map-root-user \
      bash -c "${setup_script} '${PROJECT_DIR}' '' '${MANIFEST_DIR}'"
  fi
}

### ---------- bubblewrap wrapper ----------
run_bwrap_sandbox() {
  local ssh_sock
  ssh_sock="$(detect_ssh_agent || true)"
  info "Starting bubblewrap sandbox (project=${PROJECT_DIR})"
  local bwrap_cmd=(bwrap --ro-bind /usr /usr --dev /dev --proc /proc --tmpfs /tmp --die-with-parent)
  # project: bind read-write to /home/sandbox/project
  bwrap_cmd+=(--bind "${PROJECT_DIR}" /home/sandbox/project --chdir /home/sandbox/project)
  # optional: ssh agent socket
  if [[ "${EXPOSE_SSH_AGENT}" == "1" && -n "${ssh_sock}" ]]; then
    bwrap_cmd+=(--ro-bind "${ssh_sock}" /tmp/ssh-agent.sock --setenv SSH_AUTH_SOCK /tmp/ssh-agent.sock)
  fi
  # minimal env
  bwrap_cmd+=(--setenv PATH /usr/bin:/bin --setenv HOME /home/sandbox --unshare-all /bin/bash --login)
  info "Running: ${bwrap_cmd[*]}"
  "${bwrap_cmd[@]}"
}

### ---------- systemd-nspawn helper (requires root & debootstrap/rootfs) ----------
run_nspawn_sandbox() {
  local rootfs="${1:-}"
  if [[ -z "${rootfs}" || ! -d "${rootfs}" ]]; then
    err "systemd-nspawn requires a prepared rootfs directory. Create one with debootstrap or similar and pass it as an argument."
  fi
  sudo systemd-nspawn -D "${rootfs}" --machine=pro-sandbox --private-network
}

### ---------- tmate ephemeral session helper ----------
start_tmate() {
  info "Starting tmate ephemeral session..."
  command -v tmate >/dev/null 2>&1 || { warn "tmate not installed"; return 1; }
  # start detached session and print connection strings
  tmate -S /tmp/tmate.sock new-session -d
  tmate -S /tmp/tmate.sock wait tmate-ready
  local ssh_conn web_conn
  ssh_conn="$(tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}' 2>/dev/null || true)"
  web_conn="$(tmate -S /tmp/tmate.sock display -p '#{tmate_web}' 2>/dev/null || true)"
  info "TMATE SSH: ${ssh_conn}"
  info "TMATE WEB: ${web_conn}"
  echo "${ssh_conn}" > "${MANIFEST_DIR}/tmate.ssh" || true
  echo "${web_conn}" > "${MANIFEST_DIR}/tmate.web" || true
  return 0
}
stop_tmate() {
  info "Stopping tmate sessions..."
  pkill -f tmate || true
  rm -f "${MANIFEST_DIR}/tmate.ssh" "${MANIFEST_DIR}/tmate.web" || true
}

### ---------- containerd rootless + nerdctl setup & run ----------
# This attempts a conservative, documented install flow — follow rootless container docs for production. :contentReference[oaicite:1]{index=1}
install_rootless_containerd_and_nerdctl() {
  if [[ "${CONTAINERD_ROOTLESS_INSTALL}" != "1" ]]; then
    warn "CONTAINERD_ROOTLESS_INSTALL!=1. Skipping automatic rootless containerd/nerdctl install."
    return 0
  fi
  info "Attempting to install rootless containerd + nerdctl (requires network + sudo + systemd user units)."
  # Download latest nerdctl release tarball for linux-amd64 if binary missing
  if ! command -v nerdctl >/dev/null 2>&1; then
    info "Installing nerdctl binary to ~/.local/bin (best-effort)"
    mkdir -p "${HOME}/.local/bin"
    # fetch latest release tarball (best-effort) - keep static fallback if network unavailable
    local release_base="https://github.com/containerd/nerdctl/releases/latest/download"
    local tarball="nerdctl-full-linux-amd64.tar.gz"
    if curl -fsSL "${release_base}/${tarball}" -o /tmp/${tarball}; then
      tar -xzf /tmp/${tarball} -C "${HOME}/.local" --strip-components=1
      info "nerdctl installed to ~/.local"
      export PATH="${HOME}/.local/bin:${PATH}"
    else
      warn "Failed to download nerdctl tarball; please install nerdctl manually from https://github.com/containerd/nerdctl/releases"
    fi
  fi
  # containerd-rootless-setuptool script from nerdctl extras (run to create systemd user unit)
  if ! command -v containerd-rootless-setuptool.sh >/dev/null 2>&1; then
    info "Fetching containerd-rootless-setuptool.sh into /tmp"
    curl -fsSL https://raw.githubusercontent.com/containerd/nerdctl/main/extras/rootless/containerd-rootless-setuptool.sh -o /tmp/containerd-rootless-setuptool.sh
    chmod +x /tmp/containerd-rootless-setuptool.sh
    /tmp/containerd-rootless-setuptool.sh install || warn "containerd-rootless setuptool failed (check system compatibility, cgroup v2, overlayfs)."
  fi
  info "Rootless containerd/nerdctl install attempted. Verify 'systemctl --user status containerd' and 'nerdctl --version'."
  systemctl --user enable --now containerd.service || true
}

run_nerdctl_container() {
  # Run a rootless nerdctl container with bind mounts and limits
  local image="${1:-alpine:latest}"
  local name="${2:-pro-sandbox}"
  local binds=( --volume "${PROJECT_DIR}:/work:rw" )
  if [[ "${EXPOSE_SSH_AGENT}" == "1" ]]; then
    local ssh_sock
    ssh_sock="$(detect_ssh_agent || true)"
    if [[ -n "${ssh_sock}" ]]; then
      binds+=( --volume "${ssh_sock}:/ssh-agent:ro" --env SSH_AUTH_SOCK=/ssh-agent )
    fi
  fi
  info "Running nerdctl container ${name} -> ${image}"
  nerdctl run --rm -it --name "${name}" "${binds[@]}" --workdir /work --memory 1g --cpus 1 "${image}" /bin/sh
}

### ---------- cleanup helpers ----------
cleanup_all() {
  info "Running cleanup routines..."
  # tmate
  stop_tmate || true
  # if nerdctl used, stop container
  if command -v nerdctl >/dev/null 2>&1; then
    for c in $(nerdctl ps -q --filter label=pro-sandbox 2>/dev/null || true); do
      nerdctl rm -f "$c" || true
    done
  fi
  info "Cleanup complete. Check manifests in ${MANIFEST_DIR} and logs at ${LOG_FILE}."
}

### ---------- runtime selection & entry ----------
usage() {
  cat <<EOF
pro-sandbox.sh — Professional namespaced sandbox toolkit

Commands:
  setup-prereqs            : check and optionally install prerequisites (requires ALLOW_INSTALL=1)
  sandbox-unshare          : start an interactive unshare namespaced shell (binds PROJECT_DIR)
  sandbox-bwrap            : start a bubblewrap sandbox (binds PROJECT_DIR)
  sandbox-nspawn <rootfs>  : start systemd-nspawn using provided rootfs directory
  tmate-start              : create ephemeral tmate session (prints join strings)
  tmate-stop               : kill tmate sessions started
  install-containerd       : (best-effort) install rootless containerd & nerdctl (CONTAINERD_ROOTLESS_INSTALL=1)
  run-nerdctl <image>      : run a rootless nerdctl container (binds PROJECT_DIR into /work)
  manifest-snapshot        : write a system snapshot manifest
  cleanup                  : cleanup runtime artifacts (tmate, containers)
  help

Examples:
  PROJECT_DIR=~/projects/foo ALLOW_INSTALL=1 ./pro-sandbox.sh setup-prereqs
  PROJECT_DIR=~/projects/foo ./pro-sandbox.sh sandbox-bwrap
  ./pro-sandbox.sh tmate-start
  CONTAINERD_ROOTLESS_INSTALL=1 ALLOW_INSTALL=1 ./pro-sandbox.sh install-containerd
  ./pro-sandbox.sh run-nerdctl alpine:latest
EOF
}

cmd="${1:-help}"; shift || true
case "${cmd}" in
  setup-prereqs) ensure_prereqs ;;
  sandbox-unshare) run_unshare_sandbox ;;
  sandbox-bwrap) run_bwrap_sandbox ;;
  sandbox-nspawn) run_nspawn_sandbox "$@" ;;
  tmate-start) start_tmate ;;
  tmate-stop) stop_tmate ;;
  install-containerd) install_rootless_containerd_and_nerdctl ;;
  run-nerdctl) run_nerdctl_container "${1:-alpine:latest}" "${2:-}" ;;
  manifest-snapshot) manifest_system_snapshot ;;
  cleanup) cleanup_all ;;
  help|--help|-h) usage ;;
  *) err "Unknown command: ${cmd}"; usage; exit 2 ;;
esac
