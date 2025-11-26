#!/bin/bash

# Variables
SSH_SOURCE="$HOME/.ssh/ssh_config.d"
SSH_CONFIG="generate_hosts.conf"
CONFIG_FILE="$HOME/.ssh/config"
ID_FILE="$HOME/.ssh/id_ed25519"
ID_ONLY="yes"

HOSTS=(
    "github:github.com:git"
    "safebox:xxx.xxx.xx.x:jesse"   # OracleCloud(soon)
    "callbox:192.168.12.9:jesse"
    "hostbox:192.168.12.106:jesse"
    "helpbox:192.168.12.67:jesse"
    "workbox:192.168.12.135:jesse"
)

# Create directory exists
mkdir -p "$SSH_SOURCE"

# Script Logic
for host in "${HOSTS[@]}"; do
    IFS=':' read -r name ip user <<< "$host"

   cat << EOF
Host $name
    Hostname $ip
    User $user
    IdentityFile $ID_FILE
    IdentitiesOnly $ID_ONLY

EOF
done > "$SSH_SOURCE/$SSH_CONFIG"

# Set Permissions
sudo chmod 600 "$SSH_SOURCE/$SSH_CONFIG"

# Create config file
cat > "$CONFIG_FILE" << EOF
# This file includes all config files in ~ssh_config.d~

# Main source 
Include $SSH_SOURCE/*

EOF

# Summary
echo "Generated SSH config at $SSH_SOURCE/$SSH_CONFIG"
echo "Hosts processed: ${#HOSTS[@]}"
