#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="/srv/docker"
NETWORK_NAME="cf-secure-net"
CLOUDFLARED_NAME="cloudflared"
NGINX_NAME="nginx-secure"

echo "[+] Creating isolated Podman network: $NETWORK_NAME"
podman network exists "$NETWORK_NAME" || podman network create "$NETWORK_NAME"

echo "[+] Starting containers..."
podman-compose -f "$STACK_DIR/stack.yml" up -d

echo "[+] Waiting for containers to initialize..."
sleep 5

echo "[+] Getting container IPs..."
CF_IP=$(podman inspect -f '{{.NetworkSettings.Networks.'$NETWORK_NAME'.IPAddress}}' "$CLOUDFLARED_NAME")
NGINX_IP=$(podman inspect -f '{{.NetworkSettings.Networks.'$NETWORK_NAME'.IPAddress}}' "$NGINX_NAME")

if [[ -z "$CF_IP" || -z "$NGINX_IP" ]]; then
    echo "[!] Could not determine container IPs."
    exit 1
fi

echo "    Cloudflared IP: $CF_IP"
echo "    Nginx IP:       $NGINX_IP"

echo "[+] Applying iptables firewall rules..."
iptables -F
iptables -A FORWARD -d "$NGINX_IP" -s "$CF_IP" -j ACCEPT
iptables -A FORWARD -d "$NGINX_IP" -j DROP

echo "[+] Updating Nginx access control..."
NGINX_CONF="$STACK_DIR/nginx/conf/default.conf"
sed -i "/allow /c\    allow $CF_IP;" "$NGINX_CONF"
podman exec "$NGINX_NAME" nginx -s reload

echo "[+] Secure stack deployed successfully!"
