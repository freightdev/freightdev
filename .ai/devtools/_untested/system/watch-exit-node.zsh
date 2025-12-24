#!/usr/bin/env zsh
# watch-exit-node.zsh

EXIT_NODE_NAME="archbox"
CHECK_IP="100.114.22.89"
PING_COUNT=2
SLEEP_SECONDS=10

last_state="unknown"

log() {
    print "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

while true; do
    if ping -c "$PING_COUNT" -W 1 "$CHECK_IP" &>/dev/null; then
        if [[ "$last_state" != "exit" ]]; then
            log "ASUS is online — switching to exit node $EXIT_NODE_NAME"
            sudo tailscale up --exit-node="$EXIT_NODE_NAME" \
                            --exit-node-allow-lan-access \
                            --accept-dns=false
            last_state="exit"
        fi
    else
        if [[ "$last_state" != "local" ]]; then
            log "ASUS is offline — falling back to local internet"
            sudo tailscale up --exit-node= \
                              --exit-node-allow-lan-access \
                              --accept-dns=false
            last_state="local"
        fi
    fi
    sleep "$SLEEP_SECONDS"
done
