#!/bin/bash
#
# Post-Installation Cluster Services Configuration
# Run this after initial Alpine installation and reboot
#

set -e

# ==============================================
# CONFIGURATION
# ==============================================

NODE_NAME=$(hostname)
CLUSTER_NAME="my-cluster"
DATACENTER="dc1"
BOOTSTRAP_EXPECT=3  # Number of servers in cluster

# Networking
CLUSTER_NETWORK="10.0.1.0/24"
NODE_IP=$(ip -4 addr show $(ip route | grep default | awk '{print $5}') | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Consul configuration
CONSUL_DATA_DIR="/opt/consul"
CONSUL_CONFIG_DIR="/etc/consul.d"

# Nomad configuration
NOMAD_DATA_DIR="/opt/nomad"
NOMAD_CONFIG_DIR="/etc/nomad.d"

# Vault configuration
VAULT_DATA_DIR="/opt/vault"
VAULT_CONFIG_DIR="/etc/vault.d"

# ==============================================
# HELPER FUNCTIONS
# ==============================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "ERROR: $*" >&2
    exit 1
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
    fi
}

create_service_user() {
    local username=$1
    log "Creating service user: $username"
    adduser -D -s /sbin/nologin -H "$username" 2>/dev/null || true
}

# ==============================================
# CONSUL SETUP
# ==============================================

setup_consul() {
    log "Setting up Consul..."
    
    create_service_user consul
    
    mkdir -p "$CONSUL_DATA_DIR" "$CONSUL_CONFIG_DIR"
    chown -R consul:consul "$CONSUL_DATA_DIR" "$CONSUL_CONFIG_DIR"
    
    # Generate encryption key (run once on first node, share with others)
    if [ ! -f "$CONSUL_CONFIG_DIR/encryption.key" ]; then
        consul keygen > "$CONSUL_CONFIG_DIR/encryption.key"
        CONSUL_ENCRYPT_KEY=$(cat "$CONSUL_CONFIG_DIR/encryption.key")
    else
        CONSUL_ENCRYPT_KEY=$(cat "$CONSUL_CONFIG_DIR/encryption.key")
    fi
    
    cat > "$CONSUL_CONFIG_DIR/consul.hcl" << EOF
datacenter = "$DATACENTER"
node_name = "$NODE_NAME"
data_dir = "$CONSUL_DATA_DIR"
encrypt = "$CONSUL_ENCRYPT_KEY"

server = true
bootstrap_expect = $BOOTSTRAP_EXPECT

bind_addr = "$NODE_IP"
client_addr = "0.0.0.0"

ui_config {
  enabled = true
}

retry_join = [
  # Add other server IPs here
  # "10.0.1.11",
  # "10.0.1.12",
]

performance {
  raft_multiplier = 1
}
EOF

    # Create OpenRC service
    cat > /etc/init.d/consul << 'EOFSERVICE'
#!/sbin/openrc-run

name="consul"
description="Consul Service Discovery and Configuration"
command="/usr/bin/consul"
command_args="agent -config-dir=/etc/consul.d"
command_user="consul:consul"
command_background=true
pidfile="/run/consul.pid"
output_log="/var/log/consul.log"
error_log="/var/log/consul.err"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --owner consul:consul --mode 0755 /run/consul
}
EOFSERVICE

    chmod +x /etc/init.d/consul
    rc-update add consul default
    
    log "Consul configured. Start with: rc-service consul start"
}

# ==============================================
# NOMAD SETUP
# ==============================================

setup_nomad() {
    log "Setting up Nomad..."
    
    create_service_user nomad
    
    mkdir -p "$NOMAD_DATA_DIR" "$NOMAD_CONFIG_DIR"
    chown -R nomad:nomad "$NOMAD_DATA_DIR" "$NOMAD_CONFIG_DIR"
    
    cat > "$NOMAD_CONFIG_DIR/nomad.hcl" << EOF
datacenter = "$DATACENTER"
name = "$NODE_NAME"
data_dir = "$NOMAD_DATA_DIR"

bind_addr = "$NODE_IP"

server {
  enabled = true
  bootstrap_expect = $BOOTSTRAP_EXPECT
  
  server_join {
    retry_join = [
      # Add other server IPs
      # "10.0.1.11",
      # "10.0.1.12",
    ]
  }
}

client {
  enabled = true
  
  network_interface = "$(ip route | grep default | awk '{print $5}')"
  
  # Enable raw_exec driver (use with caution)
  options = {
    "driver.raw_exec.enable" = "1"
  }
}

consul {
  address = "127.0.0.1:8500"
  auto_advertise = true
  server_service_name = "nomad"
  client_service_name = "nomad-client"
}

plugin "docker" {
  config {
    allow_privileged = false
  }
}
EOF

    # Create OpenRC service
    cat > /etc/init.d/nomad << 'EOFSERVICE'
#!/sbin/openrc-run

name="nomad"
description="Nomad Workload Orchestrator"
command="/usr/bin/nomad"
command_args="agent -config=/etc/nomad.d"
command_user="nomad:nomad"
command_background=true
pidfile="/run/nomad.pid"
output_log="/var/log/nomad.log"
error_log="/var/log/nomad.err"

depend() {
    need net consul
    after firewall
}

start_pre() {
    checkpath --directory --owner nomad:nomad --mode 0755 /run/nomad
}
EOFSERVICE

    chmod +x /etc/init.d/nomad
    rc-update add nomad default
    
    log "Nomad configured. Start with: rc-service nomad start"
}

# ==============================================
# VAULT SETUP
# ==============================================

setup_vault() {
    log "Setting up Vault..."
    
    create_service_user vault
    
    mkdir -p "$VAULT_DATA_DIR" "$VAULT_CONFIG_DIR"
    chown -R vault:vault "$VAULT_DATA_DIR" "$VAULT_CONFIG_DIR"
    
    cat > "$VAULT_CONFIG_DIR/vault.hcl" << EOF
ui = true

storage "consul" {
  address = "127.0.0.1:8500"
  path = "vault/"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

api_addr = "http://$NODE_IP:8200"
cluster_addr = "https://$NODE_IP:8201"
EOF

    # Create OpenRC service
    cat > /etc/init.d/vault << 'EOFSERVICE'
#!/sbin/openrc-run

name="vault"
description="Vault Secrets Management"
command="/usr/bin/vault"
command_args="server -config=/etc/vault.d/vault.hcl"
command_user="vault:vault"
command_background=true
pidfile="/run/vault.pid"
output_log="/var/log/vault.log"
error_log="/var/log/vault.err"

depend() {
    need net consul
    after firewall
}

start_pre() {
    checkpath --directory --owner vault:vault --mode 0755 /run/vault
}
EOFSERVICE

    chmod +x /etc/init.d/vault
    rc-update add vault default
    
    log "Vault configured. Start with: rc-service vault start"
    log "After starting, initialize with: vault operator init"
}

# ==============================================
# TRAEFIK SETUP
# ==============================================

setup_traefik() {
    log "Setting up Traefik..."
    
    create_service_user traefik
    
    mkdir -p /etc/traefik /var/log/traefik
    chown -R traefik:traefik /etc/traefik /var/log/traefik
    
    cat > /etc/traefik/traefik.yml << EOF
global:
  checkNewVersion: true
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  consulCatalog:
    endpoint:
      address: "127.0.0.1:8500"
    exposedByDefault: false

log:
  level: INFO
  filePath: "/var/log/traefik/traefik.log"

accessLog:
  filePath: "/var/log/traefik/access.log"
EOF

    # Create OpenRC service
    cat > /etc/init.d/traefik << 'EOFSERVICE'
#!/sbin/openrc-run

name="traefik"
description="Traefik Reverse Proxy"
command="/usr/bin/traefik"
command_args="--configFile=/etc/traefik/traefik.yml"
command_user="traefik:traefik"
command_background=true
pidfile="/run/traefik.pid"
output_log="/var/log/traefik/traefik.log"
error_log="/var/log/traefik/traefik.err"

depend() {
    need net consul
    after firewall
}
EOFSERVICE

    chmod +x /etc/init.d/traefik
    rc-update add traefik default
    
    log "Traefik configured. Start with: rc-service traefik start"
}

# ==============================================
# DATABASE SERVICES
# ==============================================

setup_dragonflydb() {
    log "Setting up DragonflyDB..."
    
    create_service_user dragonfly
    
    mkdir -p /var/lib/dragonfly /etc/dragonfly
    chown -R dragonfly:dragonfly /var/lib/dragonfly
    
    cat > /etc/init.d/dragonfly << 'EOFSERVICE'
#!/sbin/openrc-run

name="dragonfly"
description="DragonflyDB In-Memory Database"
command="/usr/local/bin/dragonfly"
command_args="--logtostderr --dir=/var/lib/dragonfly"
command_user="dragonfly:dragonfly"
command_background=true
pidfile="/run/dragonfly.pid"

depend() {
    need net
}
EOFSERVICE

    chmod +x /etc/init.d/dragonfly
    
    log "DragonflyDB configured. Enable with: rc-update add dragonfly default"
}

setup_surrealdb() {
    log "Setting up SurrealDB..."
    
    create_service_user surreal
    
    mkdir -p /var/lib/surreal
    chown -R surreal:surreal /var/lib/surreal
    
    cat > /etc/init.d/surreal << 'EOFSERVICE'
#!/sbin/openrc-run

name="surreal"
description="SurrealDB Multi-Model Database"
command="/usr/local/bin/surreal"
command_args="start --bind 0.0.0.0:8000 --log info file:/var/lib/surreal/data.db"
command_user="surreal:surreal"
command_background=true
pidfile="/run/surreal.pid"

depend() {
    need net
}
EOFSERVICE

    chmod +x /etc/init.d/surreal
    
    log "SurrealDB configured. Enable with: rc-update add surreal default"
}

setup_qdrant() {
    log "Setting up Qdrant..."
    
    create_service_user qdrant
    
    mkdir -p /var/lib/qdrant
    chown -R qdrant:qdrant /var/lib/qdrant
    
    cat > /etc/init.d/qdrant << 'EOFSERVICE'
#!/sbin/openrc-run

name="qdrant"
description="Qdrant Vector Database"
command="/usr/local/bin/qdrant"
command_user="qdrant:qdrant"
command_background=true
pidfile="/run/qdrant.pid"

depend() {
    need net
}

start_pre() {
    export QDRANT__STORAGE__STORAGE_PATH=/var/lib/qdrant
}
EOFSERVICE

    chmod +x /etc/init.d/qdrant
    
    log "Qdrant configured. Enable with: rc-update add qdrant default"
}

# ==============================================
# FIREWALL SETUP
# ==============================================

setup_firewall() {
    log "Setting up firewall rules..."
    
    apk add --no-cache iptables ip6tables iptables-openrc
    
    # Save these rules to /etc/iptables/rules-save
    cat > /etc/iptables/rules-save << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback
-A INPUT -i lo -j ACCEPT

# Allow established connections
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Allow SSH
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow Consul
-A INPUT -p tcp --dport 8300:8302 -j ACCEPT
-A INPUT -p udp --dport 8301:8302 -j ACCEPT
-A INPUT -p tcp --dport 8500 -j ACCEPT
-A INPUT -p tcp --dport 8600 -j ACCEPT
-A INPUT -p udp --dport 8600 -j ACCEPT

# Allow Nomad
-A INPUT -p tcp --dport 4646:4648 -j ACCEPT

# Allow Vault
-A INPUT -p tcp --dport 8200:8201 -j ACCEPT

# Allow Traefik
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -p tcp --dport 8080 -j ACCEPT

# Allow ICMP
-A INPUT -p icmp -j ACCEPT

COMMIT
EOF

    rc-update add iptables default
    rc-service iptables start
    
    log "Firewall configured"
}

# ==============================================
# MONITORING SETUP
# ==============================================

setup_monitoring() {
    log "Setting up monitoring..."
    
    apk add --no-cache prometheus prometheus-node-exporter grafana
    
    rc-update add prometheus default
    rc-update add prometheus-node-exporter default
    
    log "Monitoring tools installed. Configure Prometheus at /etc/prometheus/"
}

# ==============================================
# USER SCHEMA SYSTEM
# ==============================================

setup_schema_system() {
    log "Creating schema-based user profile system..."
    
    mkdir -p /etc/cluster/{schemas,manifests,snapshots/metadata}
    
    # Create base user schema
    cat > /etc/cluster/schemas/user-base.yaml << 'EOF'
apiVersion: v1
kind: UserProfile
metadata:
  version: "1.0"
spec:
  filesystem:
    subvolume: true
    snapshot_interval: "6h"
    quota: "50G"
    compress: "zstd:3"
  services:
    allowed: []
    resources:
      cpu_quota: "2.0"
      memory_limit: "4G"
  network:
    namespace: true
    firewall_profile: "default"
  btrfs:
    snapshots:
      enabled: true
      retention: "7d"
EOF

    # Create user management script
    cat > /usr/local/bin/cluster-user << 'EOFUSER'
#!/bin/bash
# Cluster user management with btrfs subvolumes

ACTION=$1
USERNAME=$2

case "$ACTION" in
    create)
        echo "Creating cluster user: $USERNAME"
        
        # Create system user
        adduser -D "$USERNAME"
        
        # Create btrfs subvolume for user home
        btrfs subvolume create "/home/$USERNAME"
        chown "$USERNAME:$USERNAME" "/home/$USERNAME"
        
        # Apply quota
        btrfs qgroup limit 50G "/home/$USERNAME"
        
        # Create user manifest
        cat > "/etc/cluster/manifests/user-${USERNAME}.yaml" << EOF
apiVersion: v1
kind: UserProfile
metadata:
  name: $USERNAME
  created: $(date -Iseconds)
spec:
  home: /home/$USERNAME
  subvolume: /home/$USERNAME
  services: []
EOF
        
        # Create initial snapshot
        btrfs subvolume snapshot -r "/home/$USERNAME" \
            "/.snapshots/home-${USERNAME}-$(date +%Y%m%d-%H%M%S)"
        
        echo "User $USERNAME created with btrfs subvolume"
        ;;
        
    snapshot)
        echo "Creating snapshot for user: $USERNAME"
        btrfs subvolume snapshot -r "/home/$USERNAME" \
            "/.snapshots/home-${USERNAME}-$(date +%Y%m%d-%H%M%S)"
        ;;
        
    rollback)
        SNAPSHOT=$3
        echo "Rolling back $USERNAME to snapshot $SNAPSHOT"
        mv "/home/$USERNAME" "/home/${USERNAME}.old"
        btrfs subvolume snapshot "$SNAPSHOT" "/home/$USERNAME"
        chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
        ;;
        
    *)
        echo "Usage: $0 {create|snapshot|rollback} username [snapshot]"
        exit 1
        ;;
esac
EOFUSER

    chmod +x /usr/local/bin/cluster-user
    
    log "Schema system created. Use 'cluster-user' command to manage users"
}

# ==============================================
# MAIN SETUP FLOW
# ==============================================

main() {
    log "Cluster Services Configuration"
    log "=============================="
    
    check_root
    
    log "Node: $NODE_NAME"
    log "IP: $NODE_IP"
    log ""
    
    read -p "Configure Consul? (y/n): " do_consul
    [ "$do_consul" = "y" ] && setup_consul
    
    read -p "Configure Nomad? (y/n): " do_nomad
    [ "$do_nomad" = "y" ] && setup_nomad
    
    read -p "Configure Vault? (y/n): " do_vault
    [ "$do_vault" = "y" ] && setup_vault
    
    read -p "Configure Traefik? (y/n): " do_traefik
    [ "$do_traefik" = "y" ] && setup_traefik
    
    read -p "Configure database services? (y/n): " do_dbs
    if [ "$do_dbs" = "y" ]; then
        setup_dragonflydb
        setup_surrealdb
        setup_qdrant
    fi
    
    read -p "Configure firewall? (y/n): " do_fw
    [ "$do_fw" = "y" ] && setup_firewall
    
    read -p "Setup monitoring? (y/n): " do_mon
    [ "$do_mon" = "y" ] && setup_monitoring
    
    read -p "Setup schema-based user system? (y/n): " do_schema
    [ "$do_schema" = "y" ] && setup_schema_system
    
    log ""
    log "Configuration complete!"
    log ""
    log "Next steps:"
    log "1. Review configs in /etc/consul.d, /etc/nomad.d, /etc/vault.d"
    log "2. Update retry_join IPs for cluster nodes"
    log "3. Start services: rc-service consul start && rc-service nomad start"
    log "4. Initialize Vault: vault operator init"
    log "5. Access UIs:"
    log "   - Consul: http://$NODE_IP:8500"
    log "   - Nomad: http://$NODE_IP:4646"
    log "   - Vault: http://$NODE_IP:8200"
    log "   - Traefik: http://$NODE_IP:8080"
}

main "$@"