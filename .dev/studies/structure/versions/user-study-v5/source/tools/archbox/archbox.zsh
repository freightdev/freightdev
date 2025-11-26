#!/usr/bin/env zsh
#! ╔══════════════════════════════╗
#!   archbox (zsh-plugin)- v1.0.0 
#! ╚══════════════════════════════╝
set -euo pipefail

CONTROLLER="archbox"
EDITOR="${EDITOR:-nano}"
USER="${USER:-jesse}"
ARCHBOX="${ARCHBOX:-100.114.22.89}"
ECHO_OPS="${ECHO_OPS:-100.119.145.61}"

REMOTE="$USER@$ARCHBOX"
LOCAL="$USER@$ECHO_OPS"

usage() {
  cat <<EOF
Usage: archbox <command> [args]

Connection:
  tunnel                      Open persistent SSH tunnel to $CONTROLLER
  who                         Show who's logged into $CONTROLLER
  ping                        Ping $CONTROLLER over Tailscale
  edit -f <PATH>              Edit remote file with $EDITOR
  tail -f <PATH>              Tail remote file
  list -d <PATH>              List contents of remote directory

Management:
  disable                     Move $CONTROLLER from active to inactive
  enable                      Move $CONTROLLER from inactive to active
  status                      Show if $CONTROLLER is active/inactive
  verify                      Check if $CONTROLLER is working
  setup                       Setup new task for $CONTROLLER to work on

Sync:
  push [-f|-d] <PATH>         Push local file or directory to $CONTROLLER
  pull [-f|-d] <PATH>         Pull file or directory from $CONTROLLER
  mirror [-f|-d] <PATH>       Mirror local to remote path (pull or push)

System:
  exec "<cmd>"                Run raw shell command on $CONTROLLER
  status                      Show CPU, GPU, RAM, swap, disk, temps
  reboot                      Reboot $CONTROLLER
  shutdown                    Shutdown $CONTROLLER
  update                      Run full system update + package health check
  install <pkg>               Install package on $CONTROLLER
  grep "<query>"              Search logs or files remotely
  logs [sys|kern|boot]        Show last 40 lines of system logs
  hook <target>               Run a registered system hook
  node info                   Show host node summary
  daemon <list|status|mask>   Manage daemons (systemd)
  kernel <info|modules|update> Inspect or manage kernel and modules
  config <edit|view>          View or edit system configuration
  detect                      Run full hardware detect pass
  clock <sync|show>           Sync or show current clock settings
  sensor                      List system sensors (temp, fan, power)
  fan <check|set <speed>>     Check or set fan speed if supported
  power <draw|limit|top>      View or control power usage
  thermal                     Show thermal zones
  stress <cpu|gpu|mem>        Run stress tests
  mask <service>              Mask (disable) noisy or unsafe services
  wifi <status|scan>          Show or scan Wi-Fi status
  io <summary|monitor>        Monitor disk/network I/O in real 
  cpu <check|tune|bleed|boost|lock|watch>    
                              Tune or monitor CPU
  gpu <check|tune|boost|lock|watch>
                              Tune or monitor GPU
  memory <check|bleed|watch>  View or clear memory and swap
  disk <check|trim|watch>     Check or trim disk, show usage
  net <check|speed|watch>     Network interfaces and performance
  health <full|quick>         Run a full or quick health scan
  load                        Show current load and uptime
  powertop                    Launch remote powertop for power analysis
  stats                       Display key system metrics
  lock                        Lock system from remote
  run <job>                   Execute saved remote job
  pin <process|core>          Pin process to core
  bleed <cache|swap|tmp>      Purge memory or disk buffers
  watch <cpu|gpu|temp|net>    Watch live system values
  driver <check|reload|upgrade>
                              Manage or reload NVIDIA/AMD drivers

JupyterLabs:
  jupyterlab start     Start KernelGateway on Lenovo and JupyterLab on ArchBox
  jupyterlab stop      Stop KernelGateway and JupyterLab
  jupyterlab status    Show KernelGateway and JupyterLab status
  jupyterlab logs      Show last 40 lines of logs
  jupyterlab reset     Restart both services

Flags:
  --unsafe           Bypass safety checks (not recommended)
EOF
  exit 1
}

log() { echo "[+] $*"; }

case "${1:-}" in
  tunnel)
    ssh -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=60 "$REMOTE"
    ;;

  who)
    ssh -o StrictHostKeyChecking=accept-new "$REMOTE" who
    ;;

  ping)
    ping -c4 "$REMOTE_HOST"
    ;;

  list)
    shift
    [[ "$1" != "-d" || -z "${2:-}" ]] && usage
    ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "ls -lah '$2'"
    ;;

  edit)
    shift
    [[ "$1" != "-f" || -z "${2:-}" ]] && usage
    ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "$EDITOR '$2'"
    ;;

  tail)
    shift
    [[ "$1" != "-f" || -z "${2:-}" ]] && usage
    ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "tail -f '$2'"
    ;;

  sync)
    shift
    [[ "$1" != "-d" && "$1" != "-f" ]] && usage
    [[ -z "${2:-}" ]] && usage
    SRC="$2"
    [[ ! -e "$SRC" ]] && { echo "❌ Source path not found: $SRC"; exit 1; }
    if [[ -d "$SRC" ]]; then
      rsync -azP --delete "$SRC/" "$REMOTE:$SRC"
      log "Synced directory $SRC → $REMOTE:$SRC/"
    else
      rsync -azP "$SRC" "$REMOTE:$SRC"
      log "Synced file $SRC → $REMOTE:$SRC"
    fi
    ;;

  push)
    shift
    [[ "$1" != "-d" && "$1" != "-f" ]] && usage
    [[ -z "${2:-}" ]] && usage
    SRC="$2"
    [[ ! -e "$SRC" ]] && { echo "❌ Source path not found: $SRC"; exit 1; }
    if [[ -d "$SRC" ]]; then
      rsync -azP "$SRC/" "$REMOTE:$SRC"
      log "Pushed directory $SRC → $REMOTE:$SRC/"
    else
      rsync -azP "$SRC" "$REMOTE:$SRC"
      log "Pushed file $SRC → $REMOTE:$SRC"
    fi
    ;;

  pull)
    shift
    [[ "$1" != "-d" && "$1" != "-f" ]] && usage
    [[ -z "${2:-}" ]] && usage
    SRC="$2"
    ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "[ -e '$SRC' ]" \
      || { echo "❌ Remote path not found: $SRC"; exit 1; }
    if ssh "$REMOTE" "[ -d '$SRC' ]"; then
      rsync -azP "$REMOTE:$SRC/" "$SRC/"
      log "Pulled directory $REMOTE:$SRC/ → $SRC/"
    else
      rsync -azP "$REMOTE:$SRC" "$SRC"
      log "Pulled file $REMOTE:$SRC → $SRC"
    fi
    ;;

  jupyterlab)
    case "${2:-}" in
      start)
        log "Starting KernelGateway on Lenovo..."
        ssh -o StrictHostKeyChecking=accept-new "$LOCAL" /bin/sh <<'EOF'
nohup ~/.local/bin/jupyter-kernelgateway --ip=0.0.0.0 --port=9999 --KernelGatewayApp.allow_origin="*" > ~/.kernelgateway.log 2>&1 &
echo $! > ~/.kernelgateway.pid
EOF

        log "Starting JupyterLab on ArchBox..."
        ssh -o StrictHostKeyChecking=accept-new "$REMOTE" /bin/sh <<'EOF'
nohup ~/.local/bin/jupyter-lab --no-browser --ip=0.0.0.0 --port=8888 --NotebookApp.token="" --NotebookApp.password="" --allow-root > ~/.jupyterlab.log 2>&1 &
EOF

        log "Access JupyterLab at: http://$REMOTE_HOST:8888"
        ;;
      stop)
        log "Stopping KernelGateway on Lenovo..."
        ssh -o StrictHostKeyChecking=accept-new "$LOCAL" /bin/sh <<'EOF'
pkill -f jupyter-kernelgateway || true
[ -f ~/.kernelgateway.pid ] && kill $(cat ~/.kernelgateway.pid) 2>/dev/null || true
rm -f ~/.kernelgateway.pid
EOF

        log "Stopping JupyterLab on ArchBox..."
        ssh -o StrictHostKeyChecking=accept-new "$REMOTE" /bin/sh <<'EOF'
ps -eo pid,cmd | grep "[j]upyter-lab" | while read pid cmd; do
  kill -9 "$pid" 2>/dev/null || true
done
rm -f ~/.jupyterlab.log
EOF

        log "JupyterLab and KernelGateway stopped"
        ;;
      status)
        log "KernelGateway on Lenovo:"
        ssh "$LOCAL" 'pgrep -af jupyter-kernelgateway || echo "Not running"'
        log "JupyterLab on ArchBox:"
        ssh "$REMOTE" 'pgrep -af jupyter-lab || echo "Not running"'
        ;;
      logs)
        log "KernelGateway logs on Lenovo:"
        ssh "$LOCAL" 'tail -n 40 ~/.kernelgateway.log || echo "No log file"'
        log "JupyterLab logs on ArchBox:"
        ssh "$REMOTE" 'tail -n 40 ~/.jupyterlab.log || echo "No log file"'
        ;;
      reset)
        log "Resetting JupyterLab + KernelGateway..."
        ssh "$LOCAL" /bin/sh <<'EOF'
pkill -f jupyter-kernelgateway || true
[ -f ~/.kernelgateway.pid ] && kill $(cat ~/.kernelgateway.pid) 2>/dev/null || true
rm -f ~/.kernelgateway.pid ~/.kernelgateway.log
EOF

        ssh "$REMOTE" /bin/sh <<'EOF'
ps -eo pid,cmd | grep "[j]upyter-lab" | while read pid cmd; do
  kill -9 "$pid" 2>/dev/null || true
done
rm -f ~/.jupyterlab.log
EOF

        log "Starting fresh..."
        "$0" jupyterlab start
        ;;
      *)
        echo "Usage: archbox jupyterlab <start|stop|status|logs|reset>"
        ;;
    esac
    ;;

  exec)
    shift
    [[ -z "${1:-}" ]] && usage
    ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "$*"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage
    ;;
esac
