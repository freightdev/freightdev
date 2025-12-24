#!/bin/bash

# Variables
SSH_SOURCE="$HOME/.ssh/ssh_config.d"
SSH_CONFIG="generate_hosts.conf"
CONFIG_FILE="$HOME/.ssh/config"
ID_FILE="$HOME/.ssh/id_ed25519"
ID_ONLY="yes"

HOSTS=(
    "github:github.com:git"
    "safebox:xxx.xxx.xx.x:admin"
    "callbox:192.168.1.170:admin"
    "hostbox:192.168.1.70:admin"
    "helpbox:192.168.1.40:admin"
    "workbox:192.168.1.23:admin"
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
