# NUKA SUITE (drop into ~/.zshrc)
docker_nuke() {
    echo "==============================================="
    echo "🚨  DOCKER NUKER — YOU ARE ABOUT TO DELETE EVERYTHING"
    echo "==============================================="
    echo
    echo "The following directories will be removed:"
    echo "  /var/lib/docker"
    echo "  /var/lib/containerd"
    echo "  /etc/docker"
    echo "  /run/docker"
    echo "  /run/containerd"
    echo
    read -p "Type 'NUKE' to confirm: " confirm
    if [ "$confirm" != "NUKE" ]; then
        echo "Aborted."
        return 1
    fi

    echo "[+] Stopping Docker and containerd..."
    sudo systemctl stop docker.socket docker.service containerd 2>/dev/null

    echo "[+] Removing all Docker data..."
    sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /run/docker /run/containerd

    echo "[+] Cleaning temp data..."
    sudo rm -rf /tmp/docker* /tmp/containerd*

    echo "[+] Restarting Docker fresh..."
    sudo systemctl start docker

    echo
    echo "✅ Docker has been completely nuked and restarted fresh."
    echo "Use 'docker info' to verify."
}

# confirmation helper
_nuka_confirm() {
  if [[ -n "$NUKA_FORCE" ]]; then return 0; fi
  printf "%s [type 'YES' to confirm]: " "$1"
  read -r reply
  [[ "$reply" = "YES" ]]
}


# ---- nuka container ----
nuka_container() {
  local FORCE=0
  [[ "$1" = "--yes" || "$1" = "-y" ]] && FORCE=1

  echo "=== nuka: container cleanup ==="
  if ! command -v docker >/dev/null && ! command -v podman >/dev/null; then
    echo "No docker or podman found."; return 0
  fi

  for tool in docker podman; do
    command -v $tool >/dev/null || continue
    echo "Found $tool, showing resources..."
    $tool ps -a
    $tool images
    $tool volume ls
    echo

    if (( FORCE )) || _nuka_confirm "Remove ALL $tool containers, images, volumes, networks?"; then
      $tool ps -aq | xargs -r $tool rm -f
      $tool images -aq | xargs -r $tool rmi -f
      $tool volume ls -q | xargs -r $tool volume rm -f
      $tool system prune -a -f --volumes
    else
      echo "(dry-run) skipped $tool cleanup."
    fi
  done
}

# ---- nuka project ----
nuka_project() {
  local FORCE=0 TARGET="."
  [[ "$1" = "--yes" || "$1" = "-y" ]] && FORCE=1

  local abs_target
  abs_target=$(cd -- "$TARGET" && pwd)

  echo "=== nuka: project cleanup ==="
  echo "Target: $abs_target"

  local -a dirs=(
    node_modules .next .turbo dist build out coverage
    __pycache__ .pytest_cache .mypy_cache .venv venv
    target .parcel-cache .cache .gradle
  )
  local -a files=(
    .DS_Store npm-debug.log* yarn-error.log* pnpm-debug.log*
    coverage*.lcov
  )

  echo "Will remove dirs: ${dirs[*]}"
  echo "Will remove files: ${files[*]}"
  echo

  if (( FORCE )) || _nuka_confirm "Delete project caches in $abs_target?"; then
    for d in "${dirs[@]}"; do
      find "$abs_target" -type d -name "$d" -prune -exec rm -rf {} +
    done
    for f in "${files[@]}"; do
      find "$abs_target" -type f -name "$f" -delete
    done
    echo "Project nuked."
  else
    echo "(dry-run) skipped project cleanup."
  fi
}

# ---- nuka workspace (container + project) ----
nuka_workspace() {
  echo "=== nuka: workspace cleanup ==="
  nuka_container "$@"
  nuka_project "$@"
}

# ---- nuka trash (system junk) ----
nuka_trash() {
  local FORCE=0
  [[ "$1" = "--yes" || "$1" = "-y" ]] && FORCE=1

  local -a paths=(
    "$HOME/.Trash/*"
    "$HOME/.local/share/Trash/*"
    /tmp/*
    /var/tmp/*
    "$HOME/Library/Caches/*"
  )

  echo "=== nuka: trash cleanup ==="
  for p in "${paths[@]}"; do
    echo "Candidate: $p"
  done

  if (( FORCE )) || _nuka_confirm "Remove OS junk & temp files?"; then
    for p in "${paths[@]}"; do
      rm -rf $p 2>/dev/null
    done
    echo "Trash nuked."
  else
    echo "(dry-run) skipped trash cleanup."
  fi
}

# ---- nuka list ----
nuka_list() {
  echo "Available nuka commands:"
  echo "  nuka container   - nuke docker/podman"
  echo "  nuka project     - nuke project caches"
  echo "  nuka workspace   - nuke both containers & project"
  echo "  nuka trash       - nuke OS temp & junk"
  echo "  nuka list        - show commands"
}

# ---- dispatcher ----
nuka() {
  local cmd="$1"; shift || true
  case "$cmd" in
    container) nuka_container "$@" ;;
    project)   nuka_project "$@" ;;
    workspace) nuka_workspace "$@" ;;
    trash)     nuka_trash "$@" ;;
    list|"")   nuka_list ;;
    *) echo "Unknown nuka command: $cmd"; nuka_list ;;
  esac
}
