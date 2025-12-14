#!/bin/zsh
# Location: ~/bin/trainr

TRAINR_TS="jesse@100.72.189.67"
TRAINR_DIR="/home/jesse/dev/"
LOCAL_DIR="$HOME/dev/"
EDITOR="${EDITOR:-nano}"

usage() {
  cat <<EOF
Usage: trainr <command> [args]

Core:
  tunnel             Open persistent SSH session (Tailscale)
  edit <file>        Edit file remotely with nano
  tail <file>        Tail a remote file
  ping               Ping the TRAINR node
  list               List remote files
  who                See who's logged into TRAINR

Management:
  disable            Move TRAINR from active to inactive
  enable             Move TRAINR from inactive to active
  status             Show if TRAINR is active/inactive
  verify             Check if TRAINR is working
  setup              Setup new task for TRAINR to work on

Sync:
  mirror <in|out>    in = local → remote, out = remote → local
  push <file(s)>     Push specific file/folder to TRAINR
  pull <file(s)>     Pull specific file/folder from TRAINR

Remote Execution:
  exec <cmd>         Execute command on TRAINR
  help               Show this help message

Flags:
  --unsafe           Bypass safety checks (not recommended)
EOF
  exit 1
}

case "$1" in
  tunnel)
    ssh -o ServerAliveInterval=60 "$TRAINR_TS"
    ;;

  ping)
    ping -c 4 "${TRAINR_TS#*@}"
    ;;

  who)
    ssh "$TRAINR_TS" "who"
    ;;

  list)
    ssh "$TRAINR_TS" "ls -lah $TRAINR_DIR"
    ;;

  tail)
    [[ -z "$2" ]] && { echo "Missing remote file path."; exit 1; }
    ssh "$TRAINR_TS" "tail -f $2"
    ;;

  edit)
    [[ -z "$2" ]] && { echo "Missing remote file path."; exit 1; }
    ssh "$TRAINR_TS" "$EDITOR $2"
    ;;

  mirror)
    [[ "$2" == "in" ]] && rsync -azP --delete "$LOCAL_DIR" "$TRAINR_TS:$TRAINR_DIR" && exit 0
    [[ "$2" == "out" ]] && rsync -azP --delete "$TRAINR_TS:$TRAINR_DIR" "$LOCAL_DIR" && exit 0
    echo "Usage: trainr mirror <in|out>" && exit 1
    ;;

  push)
    shift
    rsync -azP "$@" "$TRAINR_TS:$TRAINR_DIR"
    ;;

  pull)
    shift
    rsync -azP "$TRAINR_TS:$1" .
    ;;

  exec)
    shift
    ssh "$TRAINR_TS" "$@"
    ;;

  disable)
    echo "(stub) Marking TRAINR inactive..."
    ;;

  enable)
    echo "(stub) Marking TRAINR active..."
    ;;

  status)
    echo "(stub) Checking TRAINR status..."
    ;;

  verify)
    echo "Verifying TRAINR connectivity..."
    ssh -q "$TRAINR_TS" exit && echo "✅ TRAINR is reachable." || echo "❌ TRAINR unreachable."
    ;;

  setup)
    echo "(stub) Preparing TRAINR task environment..."
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    usage
    ;;
esac