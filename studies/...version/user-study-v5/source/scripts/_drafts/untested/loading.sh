# ================================
# Helpers
# ================================

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Loading spinner helper
loading_start() {
  local msg="$1"
  local pid
  log "$msg..."
  (
    local spin='-\|/'
    local i=0
    while true; do
      i=$(( (i+1) %4 ))
      printf "\r[%s] %s" "${spin:$i:1}" "$msg"
      sleep 0.1
    done
  ) &
  LOADING_PID=$!
  disown
}

loading_stop() {
  if [[ -n "$LOADING_PID" ]]; then
    kill "$LOADING_PID" >/dev/null 2>&1
    unset LOADING_PID
    printf "\r[✔] Done!        \n"
  fi
}
