#!/usr/bin/env zsh
# zBox — Enterprise Bootstrap + Namespace System (Pure ZSH)
# Drop somewhere on PATH, e.g. ~/.zbox/zbin/zbox and chmod +x

# ---------- strict zsh ----------
emulate -L zsh
setopt NO_GLOB_SUBST NO_GLOB_ASSIGN
setopt ERR_EXIT ERR_RETURN
setopt WARN_CREATE_GLOBAL
set -o nounset

# ---------- logging ----------
_log_timestamp() { builtin printf '%(%Y-%m-%d %H:%M:%S)T' -1 2>/dev/null || date '+%Y-%m-%d %H:%M:%S'; }
log_i() { print -r -- "[$(_log_timestamp)] [INFO] $*"; }
log_w() { print -r -- "[$(_log_timestamp)] [WARN] $*" >&2; }
log_e() { print -r -- "[$(_log_timestamp)] [ERROR] $*" >&2; }
log_d() { [[ -n "${ZBOX_DEBUG:-}" ]] && print -r -- "[$(_log_timestamp)] [DEBUG] $*" >&2; }

# ---------- defaults / namespace ----------
ZBOX_ROOT="${ZBOX_ROOT:-$HOME/.zbox}"
ZBIN_ROOT="${ZBIN_ROOT:-$ZBOX_ROOT/zbin}"
ZLIB_ROOT="${ZLIB_ROOT:-$ZBOX_ROOT/zlib}"
ZENV_ROOT="${ZENV_ROOT:-$ZBOX_ROOT/zenv}"

# header routes (regex -> dir)
typeset -A HEADER_ROUTES
HEADER_ROUTES=(
  'ZBox[[:space:]]+Configurations'   "$ZENV_ROOT/configs"
  'ZBox[[:space:]]+Library'          "$ZLIB_ROOT"
  'ZBox[[:space:]]+Binary'           "$ZBIN_ROOT"
  'ZBox[[:space:]]+Proxy'            "$ZENV_ROOT/proxy"
  'ZBox[[:space:]]+Network'          "$ZENV_ROOT/network"
  'ZBox[[:space:]]+Security'         "$ZENV_ROOT/security"
  'ZBox[[:space:]]+Enterprise'       "$ZENV_ROOT/enterprise"
)

# ---------- utils ----------
_ensure_dir() {
  local d
  for d in "$@"; do
    [[ -z "$d" ]] && continue
    [[ -d "$d" ]] || mkdir -p "$d" 2>/dev/null || { log_e "mkdir failed: $d"; return 1; }
  done
}

# safer PATH remove
_path_del() {
  local rm="$1"
  PATH="${PATH//:$rm/}"
  PATH="${PATH//$rm:/}"
  [[ "$PATH" == "$rm" ]] && PATH=""
  PATH="${PATH/#$rm/}"
}

# ---------- OS / package manager detection ----------
_detect_os_pm() {
  local os="unknown" pm="unknown"
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release 2>/dev/null || true
    os="${NAME:-unknown}"
  else
    os="$(uname -s)"
  fi
  case "$os" in
    *Arch*|*Manjaro*|*EndeavourOS*) pm="pacman" ;;
    *Debian*|*Ubuntu*|*Mint*|*Pop*) pm="apt" ;;
    *Alpine*) pm="apk" ;;
    *Fedora*|*Red\ Hat*|*CentOS*|*Rocky*|*Alma*) pm="$(command -v dnf >/dev/null 2>&1 && echo dnf || echo yum)" ;;
    *) pm="unknown" ;;
  esac
  print -r -- "$pm"
}

_require_sudo_notice() {
  if ! sudo -n true 2>/dev/null; then
    log_w "Root privileges required to install packages; sudo may prompt."
  fi
}

# ---------- package bootstrap ----------
# Baseline tools across distros (mapped names where they differ)
_bootstrap_packages() {
  local FORCE_YES="${FORCE_YES:-false}"
  local INTERACTIVE="${INTERACTIVE:-false}"

  local pm; pm="$(_detect_os_pm)"
  if [[ "$pm" == "unknown" ]]; then
    log_e "Unsupported/unknown distro. Aborting package bootstrap."
    return 1
  fi
  log_i "Using package manager: $pm"
  _require_sudo_notice

  # Common logical set; map names per manager
  local pkgs=()
  case "$pm" in
    apt)
      pkgs=( ca-certificates coreutils grep findutils sed gawk procps util-linux curl wget git jq netcat-openbsd openssh-client gnupg tar xz-utils )
      log_i "Updating apt indexes..."
      sudo apt update || log_w "apt update failed; continuing"
      log_i "Installing baseline packages..."
      sudo apt install -y "${pkgs[@]}" || log_w "Some packages may have failed on apt"
      ;;
    pacman)
      pkgs=( ca-certificates coreutils grep findutils sed gawk procps-ng util-linux curl wget git jq openbsd-netcat openssh gnupg tar xz )
      sudo pacman -Sy --noconfirm || log_w "pacman -Sy failed; continuing"
      sudo pacman -S --needed --noconfirm "${pkgs[@]}" || log_w "Some packages may have failed on pacman"
      ;;
    apk)
      pkgs=( ca-certificates coreutils grep findutils sed gawk procps util-linux curl wget git jq netcat-openbsd openssh-client gnupg tar xz )
      sudo apk update || log_w "apk update failed; continuing"
      sudo apk add --no-cache "${pkgs[@]}" || log_w "Some packages may have failed on apk"
      ;;
    dnf|yum)
      pkgs=( ca-certificates coreutils grep findutils sed gawk procps-ng util-linux curl wget git jq nmap-ncat openssh-clients gnupg2 tar xz )
      if [[ "$pm" == dnf ]]; then
        sudo dnf makecache -y || true
        sudo dnf install -y "${pkgs[@]}" || log_w "Some packages may have failed on dnf"
      else
        sudo yum makecache -y || true
        sudo yum install -y "${pkgs[@]}" || log_w "Some packages may have failed on yum"
      fi
      ;;
  esac

  log_i "Baseline packages installation step finished."
}

# ---------- enterprise namespace init ----------
_init_namespace() {
  log_i "Initializing Z-System namespace at $ZBOX_ROOT"
  _ensure_dir "$ZBOX_ROOT" "$ZBIN_ROOT" "$ZLIB_ROOT" "$ZENV_ROOT" \
             "$ZENV_ROOT/configs" "$ZENV_ROOT/proxy" "$ZENV_ROOT/network" \
             "$ZENV_ROOT/security" "$ZENV_ROOT/enterprise"
  print -r -- "ZBOX_NAMESPACE=active" >| "$ZBOX_ROOT/.zbox_active" 2>/dev/null || true
  print -r -- "# ZBox Enterprise Environment" >| "$ZENV_ROOT/.zenv" 2>/dev/null || true
  print -r -- "# ZBox Binary Space" >| "$ZBIN_ROOT/.zbin" 2>/dev/null || true
  print -r -- "# ZBox Library Collection" >| "$ZLIB_ROOT/.zlib" 2>/dev/null || true
  log_i "Namespace directories created."
}

# ---------- header router ----------
_route_by_header() {
  local file="$1"
  [[ -f "$file" ]] || { log_e "File not found: $file"; return 1; }

  # find first `#?` header line within first 15 lines
  local header_line
  header_line="$(head -15 -- "$file" 2>/dev/null | grep -E '^[[:space:]]*#\?' | head -1 || true)"
  if [[ -z "$header_line" ]]; then
    log_w "No header found in $(basename "$file"); routing to configs/"
    _ensure_dir "$ZENV_ROOT/configs"; cp -f -- "$file" "$ZENV_ROOT/configs/$(basename "$file")"
    return 0
  fi

  # normalize header content (strip '#?', trim)
  local header_type
  header_type="$(print -r -- "$header_line" | sed -E 's/^[[:space:]]*#\?[[:space:]]*//' )"
  log_d "Detected header: $header_type"

  local pattern target_dir
  for pattern target_dir in ${(@kv)HEADER_ROUTES}; do
    if print -r -- "$header_type" | grep -Eq "$pattern"; then
      _ensure_dir "$target_dir"
      cp -f -- "$file" "$target_dir/$(basename "$file")"
      log_i "Routed $(basename "$file") -> $target_dir"
      return 0
    fi
  done

  log_w "Unknown header type; routing to configs/"
  _ensure_dir "$ZENV_ROOT/configs"; cp -f -- "$file" "$ZENV_ROOT/configs/$(basename "$file")"
}

# ---------- namespace activation ----------
_namespace() {
  local mode="${1:-on}"
  case "$mode" in
    on)
      log_i "Activating Z-Namespace"
      export ZBOX_ACTIVE=1
      [[ ":$PATH:" == *":$ZBIN_ROOT:"* ]] || PATH="$ZBIN_ROOT:$PATH"
      # load all zsh/sh configs
      local f
      for f in "$ZENV_ROOT"/configs/*.zsh(N) "$ZENV_ROOT"/configs/*.sh(N); do
        [[ -f "$f" ]] && source "$f" 2>/dev/null || true
      done
      log_i "Z-Namespace ACTIVE"
      ;;
    off)
      log_i "Deactivating Z-Namespace"
      unset ZBOX_ACTIVE || true
      _path_del "$ZBIN_ROOT"
      log_i "Z-Namespace INACTIVE"
      ;;
    *)
      log_e "Usage: zbox namespace [on|off]"
      return 1
      ;;
  esac
}

# ---------- enterprise config templates ----------
_enterprise_config() {
  local type="${1:-}"
  case "$type" in
    proxy)
      cat > "$ZENV_ROOT/enterprise/proxy_config.zsh" <<'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Proxy Configuration
export HTTP_PROXY="${HTTP_PROXY:-http://enterprise-proxy:8080}"
export HTTPS_PROXY="${HTTPS_PROXY:-https://enterprise-proxy:8443}"
export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,*.internal.corp}"
export PROXY_AUTH_METHOD="${PROXY_AUTH_METHOD:-NTLM}"
export PROXY_TIMEOUT="${PROXY_TIMEOUT:-30}"
EOF
      log_i "Enterprise proxy config created."
      ;;
    network)
      cat > "$ZENV_ROOT/enterprise/network_config.zsh" <<'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Network Configuration
export NETWORK_INTERFACE="${NETWORK_INTERFACE:-eth0}"
export DNS_PRIMARY="${DNS_PRIMARY:-8.8.8.8}"
export DNS_SECONDARY="${DNS_SECONDARY:-8.8.4.4}"
export NETWORK_TIMEOUT="${NETWORK_TIMEOUT:-10}"
export MAX_CONNECTIONS="${MAX_CONNECTIONS:-1000}"
export KEEPALIVE_TIMEOUT="${KEEPALIVE_TIMEOUT:-60}"
EOF
      log_i "Enterprise network config created."
      ;;
    security)
      cat > "$ZENV_ROOT/enterprise/security_config.zsh" <<'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Security Configuration
export TLS_MIN_VERSION="${TLS_MIN_VERSION:-1.2}"
export CIPHER_SUITE="${CIPHER_SUITE:-ECDHE-RSA-AES256-GCM-SHA384}"
export CERT_VALIDATION="${CERT_VALIDATION:-strict}"
export SESSION_TIMEOUT="${SESSION_TIMEOUT:-3600}"
export MAX_LOGIN_ATTEMPTS="${MAX_LOGIN_ATTEMPTS:-3}"
export AUDIT_LOGGING="${AUDIT_LOGGING:-enabled}"
EOF
      log_i "Enterprise security config created."
      ;;
    routing)
      cat > "$ZENV_ROOT/enterprise/routing_config.zsh" <<'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Routing Configuration
export DEFAULT_GATEWAY="${DEFAULT_GATEWAY:-192.168.1.1}"
export ROUTING_TABLE="${ROUTING_TABLE:-main}"
export LOAD_BALANCER="${LOAD_BALANCER:-round-robin}"
export FAILOVER_TIMEOUT="${FAILOVER_TIMEOUT:-5}"
export HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-30}"
export ROUTE_METRIC="${ROUTE_METRIC:-100}"
EOF
      log_i "Enterprise routing config created."
      ;;
    *)
      log_i "Available enterprise configs: proxy | network | security | routing"
      return 1
      ;;
  esac
}

# ---------- essential libs ----------
_create_libs() {
  log_i "Creating essential ZBox libraries in $ZLIB_ROOT"
  _ensure_dir "$ZLIB_ROOT"

  cat > "$ZLIB_ROOT/logging.zsh" <<'EOF'
#!/usr/bin/env zsh
#? ZBox Library - Logging
zlog()        { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
zlog_error()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
zlog_debug()  { [[ -n "$ZBOX_DEBUG" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*"; }
EOF

  cat > "$ZLIB_ROOT/network.zsh" <<'EOF'
#!/usr/bin/env zsh
#? ZBox Library - Network
zping() { ping -c 1 -W 1 "$1" &>/dev/null && echo "✅ $1" || echo "❌ $1"; }
zport() { nc -zv "$1" "$2" 2>&1 | grep -q "succeeded" && echo "✅ $1:$2" || echo "❌ $1:$2"; }
zcheck_proxy() { curl -x "${HTTP_PROXY:-}" -I http://example.com &>/dev/null && echo "✅ Proxy OK" || echo "❌ Proxy failed"; }
EOF

  cat > "$ZLIB_ROOT/files.zsh" <<'EOF'
#!/usr/bin/env zsh
#? ZBox Library - Files
zbackup() {
  local file="$1"
  [[ -f "$file" ]] || { echo "File not found: $file" >&2; return 1; }
  local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
  cp -- "$file" "$backup" && echo "✅ Backed up: $backup"
}
zclean() {
  local confirm="${1:-ask}"
  local list; list=$(find . \( -name "*.tmp" -o -name "*.log" -o -name "*.bak" \) -print | head -100)
  [[ -z "$list" ]] && { echo "Nothing to clean."; return 0; }
  echo "$list"
  if [[ "$confirm" == "force" ]]; then
    echo "$list" | xargs -r rm -f
  else
    read -r "ans?Delete these files? (y/N): "
    [[ "$ans" =~ ^[Yy]$ ]] && echo "$list" | xargs -r rm -f
  fi
}
EOF

  log_i "Essential libraries created."
}

# ---------- info ----------
_info() {
  local cfg_count lib_count
  cfg_count=$(ls "$ZENV_ROOT"/configs/*(N) 2>/dev/null | wc -l | tr -d ' ')
  lib_count=$(ls "$ZLIB_ROOT"/*.zsh(N) 2>/dev/null | wc -l | tr -d ' ')
  print -r -- "╔════════════════════════════════════╗"
  print -r -- "║        ZBox Enterprise System      ║"
  print -r -- "╠════════════════════════════════════╣"
  print -r -- "║ Z-Namespace: $([[ -n "${ZBOX_ACTIVE:-}" ]] && echo '🟢 ACTIVE' || echo '⚪ INACTIVE')"
  print -r -- "║ Root Path:   $ZBOX_ROOT"
  print -r -- "║ Configs:     ${cfg_count:-0} files"
  print -r -- "║ Libraries:   ${lib_count:-0} files"
  print -r -- "╚════════════════════════════════════╝"
}

# ---------- combined workflows ----------
_cmd_bootstrap() {
  # flags respected via env or CLI parser below
  _bootstrap_packages
  _init_namespace
  _create_libs
  log_i "Bootstrap complete."
}

_cmd_init() {
  _init_namespace
  _create_libs
  log_i "Init complete."
}

_cmd_route() {
  shift 0 # no-op; keep position consistent if used standalone
  if [[ $# -eq 0 ]]; then
    log_e "Usage: zbox route <file ...>"
    return 1
  fi
  local f
  for f in "$@"; do
    _route_by_header "$f" || true
  done
}

_cmd_namespace() {
  local mode="${1:-on}"
  _namespace "$mode"
}

_cmd_enterprise() {
  local which="${1:-}"
  _enterprise_config "$which"
}

_cmd_libs() {
  _create_libs
}

_show_help() {
  cat <<'EOF'
zBox — Enterprise Bootstrap + Namespace

USAGE:
  zbox [--force|-f] [--interactive|-i] <command> [args...]

COMMANDS:
  bootstrap           Install baseline packages + init namespace + libs
  init                Init namespace + libs (no package install)
  route <files...>    Route files into namespace by "#?" header
  namespace on|off    Activate / deactivate Z-namespace
  enterprise <type>   Create enterprise config: proxy|network|security|routing
  libs                Recreate essential libraries
  info                Show status

FLAGS:
  -f, --force         Assume yes/non-interactive where prompts exist
  -i, --interactive   Prefer interactive prompts if applicable
  -h, --help          Show this help

ENV:
  ZBOX_ROOT, ZBIN_ROOT, ZLIB_ROOT, ZENV_ROOT, ZBOX_DEBUG
EOF
}

# ---------- CLI ----------
main() {
  # defaults
  FORCE_YES=false
  INTERACTIVE=false

  # parse global flags
  local argv=()
  while (( $# )); do
    case "$1" in
      -f|--force) FORCE_YES=true; shift ;;
      -i|--interactive) INTERACTIVE=true; shift ;;
      -h|--help) _show_help; return 0 ;;
      --) shift; break ;;
      -*) log_e "Unknown option: $1"; _show_help; return 1 ;;
      *) argv+=("$1"); shift ;;
    esac
  done
  set -- "${argv[@]}" "$@"
  export FORCE_YES INTERACTIVE

  local cmd="${1:-info}"; shift || true
  case "$cmd" in
    bootstrap) _cmd_bootstrap "$@" ;;
    init) _cmd_init "$@" ;;
    route) _cmd_route "$@" ;;
    namespace) _cmd_namespace "${1:-on}" ;;
    enterprise) _cmd_enterprise "${1:-}" ;;
    libs) _cmd_libs ;;
    info) _info ;;
    *) log_e "Unknown command: $cmd"; _show_help; return 1 ;;
  esac
}

# run if invoked directly
if [[ "${(%):-%N}" == "$0" || "${BASH_SOURCE[0]-}" == "$0" ]]; then
  main "$@"
fi
