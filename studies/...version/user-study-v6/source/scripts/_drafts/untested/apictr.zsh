#!/usr/bin/env zsh
# ===============================
# API Controller (Zsh)
# ===============================

set -euo pipefail

# -------- CONFIGURATION --------
CONFIG_DIR="$HOME/.config/apictr"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOG_DIR="$HOME/.local/share/apictr/logs"
PID_FILE="$HOME/.local/share/apictr/listener.pid"
API_KEY_FILE_DEFAULT="$HOME/.keys/apictr.key"

autoload -Uz colors && colors

info() { print -P "%F{green}ℹ️ %f$*"; }
warn() { print -P "%F{yellow}⚠️ %f$*"; }
err()  { print -P "%F{red}❌ %f$*" >&2; }

load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
  else
    LISTENER_PORT=8081
    REVERSE_MODE=false
    DEFAULT_BACKEND_URL="http://127.0.0.1:8000/api"
    API_KEY_FILE="$API_KEY_FILE_DEFAULT"
    AUTH_HEADER="Authorization: Bearer {key}"
    LOG_DIR="$HOME/.local/share/apictr/logs"
    TIMEOUT=30
    BANNED_WORDS=("badword1" "malware" "exclude_this")
    ACCEPTED_FORMATS=("json" "yaml" "md")
    REVERSE_ENDPOINTS=()
    MAX_LOG_SIZE_MB=10
  fi
}

setup() {
  mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$HOME/.keys"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<EOF
# apictr configuration
LISTENER_PORT=8081
REVERSE_MODE=false

DEFAULT_BACKEND_URL="http://127.0.0.1:8000/api"
API_KEY_FILE="\$HOME/.keys/apictr.key"
AUTH_HEADER="Authorization: Bearer {key}"

LOG_DIR="\$HOME/.local/share/apictr/logs"
TIMEOUT=30

BANNED_WORDS=("badword1" "malware" "exclude_this")
ACCEPTED_FORMATS=("json" "yaml" "md")
REVERSE_ENDPOINTS=()
MAX_LOG_SIZE_MB=10
EOF
    info "Created default config at $CONFIG_FILE"
  else
    warn "Config already exists at $CONFIG_FILE"
  fi

  if [[ ! -f "$API_KEY_FILE_DEFAULT" ]]; then
    echo "# Put your API key here" > "$API_KEY_FILE_DEFAULT"
    chmod 600 "$API_KEY_FILE_DEFAULT"
    info "Created empty API key file at $API_KEY_FILE_DEFAULT"
  fi
}

edit_config() {
  ${EDITOR:-nano} "$CONFIG_FILE"
}

show_config() {
  cat "$CONFIG_FILE"
}

rotate_logs() {
  for f in "$LOG_DIR"/*.log; do
    [[ -f "$f" ]] || continue
    local size_mb=$(( $(stat -c%s "$f") / 1024 / 1024 ))
    if (( size_mb >= MAX_LOG_SIZE_MB )); then
      mv "$f" "${f}.$(date +%Y%m%d%H%M%S).bak"
      info "Rotated log $f"
    fi
  done
}

hydrate_input() {
  local input="$1"
  for w in "${BANNED_WORDS[@]}"; do
    input="${input//${w}/}"
  done
  echo "$input"
}

# --- Helper to parse HTTP headers ---
parse_headers() {
  local fd=$1
  declare -A headers
  while read -r line <&$fd; do
    [[ "$line" == $'\r' || "$line" == "" ]] && break
    if [[ "$line" =~ ^([^:]+):[[:space:]]*(.*)$ ]]; then
      local key="${match[1],,}" # lowercase key
      local val="${match[2]}"
      headers[$key]="$val"
    fi
  done
  # Return associative array keys and values separated by newlines
  for k in ${(k)headers}; do
    echo "$k: ${headers[$k]}"
  done
}

# --- Listener implementation with netcat ---

start_listener() {
  if [[ -f "$PID_FILE" ]]; then
    local pid=$(<"$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      err "Listener already running (PID $pid)"
      return 1
    else
      rm -f "$PID_FILE"
    fi
  fi

  info "Starting listener on port $LISTENER_PORT (reverse=$REVERSE_MODE)..."

  # We need a loop that listens continuously and handles one connection at a time
  # Because netcat does not support multi-threaded or multiple connections natively

  (
    while true; do
      # Using ncat if available, fallback to nc -l -p
      local nc_bin="nc"
      if command -v ncat >/dev/null 2>&1; then
        nc_bin="ncat"
      fi

      # Listen for single connection and process request
      # Using a file descriptor workaround to parse HTTP headers and body

      # Create a temporary fifo for communication with nc
      local fifo_in fifo_out
      fifo_in=$(mktemp -u)
      fifo_out=$(mktemp -u)
      mkfifo "$fifo_in" "$fifo_out"

      # Accept connection: output response to fifo_out, input request from fifo_in
      # The command below waits for connection, then pipes input to fifo_in, and response from fifo_out to client
      # Run in background so we can process request

      $nc_bin -l -p "$LISTENER_PORT" <"$fifo_out" >"$fifo_in" &

      local nc_pid=$!

      # Read request line and headers from fifo_in
      exec 3<>"$fifo_in"
      exec 4<>"$fifo_out"

      # Read request line
      IFS=$'\r\n' read -r request_line <&3 || {
        err "Failed to read request line"
        kill "$nc_pid" 2>/dev/null
        rm -f "$fifo_in" "$fifo_out"
        continue
      }
      # Basic parse request line: e.g. POST /api HTTP/1.1
      local method path protocol
      read -r method path protocol <<<"$request_line"

      # Read headers
      local content_length=0 content_type=""
      while read -r header_line <&3; do
        [[ "$header_line" == $'\r' || -z "$header_line" ]] && break
        if [[ "$header_line" =~ ^Content-Length:[[:space:]]*([0-9]+) ]]; then
          content_length="${match[1]}"
        elif [[ "$header_line" =~ ^Content-Type:[[:space:]]*(.*)$ ]]; then
          content_type="${match[1]}"
        fi
      done

      # Read body according to Content-Length
      local body=""
      if (( content_length > 0 )); then
        read -r -N "$content_length" body <&3 || {
          err "Failed to read request body"
          kill "$nc_pid" 2>/dev/null
          rm -f "$fifo_in" "$fifo_out"
          continue
        }
      fi

      # Cleanup fifo, close fds and kill nc early
      exec 3>&-
      exec 4>&-
      kill "$nc_pid" 2>/dev/null
      rm -f "$fifo_in" "$fifo_out"

      # Log inbound request
      mkdir -p "$LOG_DIR"
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $method $path Content-Type:$content_type Length:$content_length" >> "$LOG_DIR/inbound.log"
      echo "$body" >> "$LOG_DIR/inbound.log"

      # Hydrate input
      local hydrated
      hydrated=$(hydrate_input "$body")

      # If reverse mode, push hydrated to reverse endpoints
      if [[ "$REVERSE_MODE" == true && ${#REVERSE_ENDPOINTS[@]} -gt 0 ]]; then
        for url in "${REVERSE_ENDPOINTS[@]}"; do
          # Use curl to POST hydrated content
          curl -sS -X POST "$url" -H "Content-Type: $content_type" -d "$hydrated" --max-time "$TIMEOUT" >> "$LOG_DIR/outbound.log" 2>&1 || {
            warn "Failed to push to $url"
          }
        done
      fi

      # Compose HTTP response JSON with simple echo
      local response='{"status":"ok","message":"Request received and processed"}'
      local resp_len=${#response}

      # Send HTTP response to client with status 200 and JSON body
      # Using file descriptor 4 (fifo_out)
      {
        print -n "HTTP/1.1 200 OK\r"
        print -n "Content-Type: application/json\r"
        print -n "Content-Length: $resp_len\r"
        print -n "Connection: close\r"
        print -n "\r"
        print -n "$response"
      } > "$fifo_out"
    done
  ) &
  echo $! > "$PID_FILE"
  info "Listener started with PID $(<"$PID_FILE")"
}

stop_listener() {
  if [[ ! -f "$PID_FILE" ]]; then
    err "Listener is not running"
    return 1
  fi
  local pid=$(<"$PID_FILE")
  kill "$pid" 2>/dev/null && rm -f "$PID_FILE"
  info "Listener stopped"
}

status_listener() {
  if [[ -f "$PID_FILE" && kill -0 $(<"$PID_FILE") 2>/dev/null ]]; then
    info "Listener running (PID $(<"$PID_FILE"))"
  else
    info "Listener is NOT running"
  fi
}

send_prompt() {
  load_config
  if [[ ! -f "$API_KEY_FILE" ]]; then
    err "API key file missing"
    return 1
  fi
  local API_KEY
  API_KEY=$(<"$API_KEY_FILE")
  local prompt
  prompt=$(hydrate_input "$*")
  local header="${AUTH_HEADER//\{key\}/$API_KEY}"

  info "Sending prompt to $DEFAULT_BACKEND_URL..."

  local resp
  resp=$(curl -sS --max-time "$TIMEOUT" -X POST "$DEFAULT_BACKEND_URL" \
    -H "Content-Type: application/json" \
    -H "$header" \
    -d "{\"prompt\": \"$prompt\"}")

  echo "$resp"
}

show_logs() {
  local filter="${1:-all}"
  local tailcount="${2:-50}"
  case "$filter" in
    inbound)
      tail -n "$tailcount" "$LOG_DIR/inbound.log" 2>/dev/null || echo "No inbound logs"
      ;;
    outbound)
      tail -n "$tailcount" "$LOG_DIR/outbound.log" 2>/dev/null || echo "No outbound logs"
      ;;
    all)
      tail -n "$tailcount" "$LOG_DIR/"*.log 2>/dev/null || echo "No logs"
      ;;
    *)
      err "Unknown log filter $filter"
      ;;
  esac
}

usage() {
  print -P "%F{cyan}Usage:%f apictr <setup|config|start|stop|status|send|logs|hydrate>"
  print -P "Commands:"
  print -P "  setup                 Initialize config and key files"
  print -P "  config <edit|show|reset>  Manage config"
  print -P "  start                 Start API listener"
  print -P "  stop                  Stop listener"
  print -P "  status                Check listener status"
  print -P "  send <prompt>         Send prompt outbound"
  print -P "  logs [filter] [tail]  Show logs (filter: inbound, outbound, all)"
  print -P "  hydrate <input>       Filter/hydrate input"
}

# -------- MAIN --------
case "${1:-}" in
  setup)
    setup
    ;;
  config)
    case "${2:-}" in
      edit)
        edit_config
        ;;
      show)
        show_config
        ;;
      reset)
        rm -f "$CONFIG_FILE" "$API_KEY_FILE_DEFAULT"
        setup
        ;;
      *)
        usage
        ;;
    esac
    ;;
  start)
    load_config
    start_listener
    ;;
  stop)
    stop_listener
    ;;
  status)
    status_listener
    ;;
  send)
    shift
    send_prompt "$*"
    ;;
  logs)
    shift
    show_logs "$@"
    ;;
  hydrate)
    shift
    hydrate_input "$*"
    ;;
  *)
    usage
    ;;
esac
