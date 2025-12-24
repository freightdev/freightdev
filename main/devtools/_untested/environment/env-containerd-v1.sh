#!/usr/bin/env bash
#
# containerd-tool.sh — Rootless containerd + nerdctl installer and runtime controller
# Version: 2025-08-12
#
# Requirements:
#  - Linux with cgroups v2, overlayfs, user namespaces enabled
#  - systemd (for user units)
#  - curl, tar, unzip, jq (optional but recommended)
#
# This script will:
#  - Install/update containerd-rootless setup in your $HOME
#  - Download and install nerdctl CLI to ~/.local/bin
#  - Enable and start user-level containerd.service
#  - Provide commands: install, start, stop, restart, status, run, cleanup
#
# Usage examples at bottom.
set -Eeuo pipefail
IFS=$'\n\t'

STATE_DIR="${HOME}/.containerd-tool"
INSTALL_LOG="${STATE_DIR}/install.log"
NERDCTL_BIN="${HOME}/.local/bin/nerdctl"
CONTAINERD_ROOTLESS_SETUP="${STATE_DIR}/containerd-rootless-setuptool.sh"

# Colors for messaging
c_ok="\e[32m"; c_warn="\e[33m"; c_err="\e[31m"; c_end="\e[0m"

log()  { printf "%s %s\n" "$(date -Iseconds)" "$*" | tee -a "${INSTALL_LOG}"; }
info() { printf "${c_ok}[INFO]${c_end} %s\n" "$*" | tee -a "${INSTALL_LOG}"; }
warn() { printf "${c_warn}[WARN]${c_end} %s\n" "$*" | tee -a "${INSTALL_LOG}"; }
err()  { printf "${c_err}[ERROR]${c_end} %s\n" "$*" | tee -a "${INSTALL_LOG}"; }

mkdir -p "${STATE_DIR}" "${HOME}/.local/bin"

check_prereqs() {
  local miss=()
  for cmd in curl tar jq systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || miss+=("$cmd")
  done
  if [[ ${#miss[@]} -gt 0 ]]; then
    err "Missing prerequisites: ${miss[*]}"
    err "Please install these before continuing."
    exit 1
  fi
}

download_nerdctl() {
  if command -v nerdctl >/dev/null 2>&1; then
    info "nerdctl already installed at $(command -v nerdctl)"
    return 0
  fi
  info "Downloading latest nerdctl release tarball..."
  local url base_url="https://github.com/containerd/nerdctl/releases/latest/download"
  local tarball="nerdctl-full-linux-amd64.tar.gz"
  url="${base_url}/${tarball}"
  if curl -fsSL "$url" -o "/tmp/${tarball}"; then
    info "Extracting nerdctl tarball..."
    tar -xzf "/tmp/${tarball}" -C "${HOME}/.local" --strip-components=1
    info "nerdctl installed to ~/.local/bin"
    export PATH="${HOME}/.local/bin:${PATH}"
  else
    err "Failed to download nerdctl from $url"
    exit 2
  fi
}

download_containerd_rootless_setup() {
  if [[ -f "${CONTAINERD_ROOTLESS_SETUP}" ]]; then
    info "containerd-rootless-setuptool.sh already downloaded."
    return 0
  fi
  info "Downloading containerd-rootless-setuptool.sh helper..."
  curl -fsSL https://raw.githubusercontent.com/containerd/nerdctl/main/extras/rootless/containerd-rootless-setuptool.sh -o "${CONTAINERD_ROOTLESS_SETUP}"
  chmod +x "${CONTAINERD_ROOTLESS_SETUP}"
}

install_containerd_rootless() {
  info "Installing containerd rootless environment..."
  "${CONTAINERD_ROOTLESS_SETUP}" install | tee -a "${INSTALL_LOG}"
  info "Enabling and starting systemd user service containerd.service"
  systemctl --user daemon-reload
  systemctl --user enable --now containerd.service
  systemctl --user status containerd.service --no-pager
}

start_containerd() {
  info "Starting containerd rootless service..."
  systemctl --user start containerd.service
}

stop_containerd() {
  info "Stopping containerd rootless service..."
  systemctl --user stop containerd.service
}

restart_containerd() {
  info "Restarting containerd rootless service..."
  systemctl --user restart containerd.service
}

status_containerd() {
  systemctl --user status containerd.service --no-pager
}

run_container() {
  local image="${1:-alpine:latest}"
  shift || true
  local name="containerd-tool-$(date +%s)"
  local workdir="${PWD}"
  local ssh_sock="${SSH_AUTH_SOCK:-}"
  local binds=(--volume "${workdir}:/work:rw")
  local envs=()

  if [[ -n "${ssh_sock}" && -S "${ssh_sock}" ]]; then
    binds+=(--volume "${ssh_sock}:/ssh-agent:ro")
    envs+=(--env SSH_AUTH_SOCK=/ssh-agent)
  fi

  info "Running container '${name}' image '${image}' with workdir '${workdir}'"
  nerdctl run --rm -it --name "${name}" "${binds[@]}" "${envs[@]}" --workdir /work "$@" "${image}"
}

cleanup() {
  info "Cleaning up stopped containers and orphaned resources..."
  nerdctl container prune -f || true
  nerdctl image prune -af || true
  info "Cleanup complete."
}

usage() {
  cat <<EOF
containerd-tool.sh — rootless containerd + nerdctl installer & controller

Commands:
  install          : download and install containerd rootless setup and nerdctl CLI, enable & start service
  start            : start containerd rootless user service
  stop             : stop containerd rootless user service
  restart          : restart containerd rootless user service
  status           : show containerd service status
  run <image> [args...]
                   : run a container with your current dir bind-mounted at /work,
                     forwards SSH_AUTH_SOCK if available,
                     interactive tty by default,
                     pass additional arguments after image name
  cleanup          : prune stopped containers and dangling images

Examples:
  ./containerd-tool.sh install
  ./containerd-tool.sh status
  ./containerd-tool.sh run alpine:latest /bin/sh
  ./containerd-tool.sh cleanup
EOF
}

cmd="${1:-help}"; shift || true
case "$cmd" in
  install) check_prereqs; download_nerdctl; download_containerd_rootless_setup; install_containerd_rootless ;;
  start) start_containerd ;;
  stop) stop_containerd ;;
  restart) restart_containerd ;;
  status) status_containerd ;;
  run) run_container "$@" ;;
  cleanup) cleanup ;;
  help|--help|-h) usage ;;
  *) err "Unknown command: $cmd"; usage; exit 2 ;;
esac
