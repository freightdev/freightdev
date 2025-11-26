#!/bin/bash
set -euo pipefail

# n8n Production Setup Script for Debian
# Run as root or with sudo

# Configuration
N8N_USER="n8n"
N8N_HOME="/var/lib/n8n"
N8N_LOG_DIR="/var/log/n8n"
N8N_PORT="5678"
N8N_HOST="0.0.0.0"
WEBHOOK_URL="https://yourdomain.com"  # CHANGE THIS
NODE_VERSION="20"  # LTS version

echo "========================================="
echo "n8n Production Setup Script"
echo "========================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo" 
   exit 1
fi

# Install Node.js if not present
echo "[*] Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "[*] Installing Node.js ${NODE_VERSION}..."
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt-get install -y nodejs
else
    echo "[*] Node.js already installed: $(node --version)"
fi

# Verify npm is available
if ! command -v npm &> /dev/null; then
    echo "[!] npm not found, installing..."
    apt-get install -y npm
fi

# Create n8n system user
echo "[*] Creating n8n system user..."
if ! id "$N8N_USER" &>/dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin --comment "n8n automation user" "$N8N_USER"
    echo "[*] User $N8N_USER created"
else
    echo "[*] User $N8N_USER already exists"
fi

# Create directories
echo "[*] Creating directory structure..."
mkdir -p "$N8N_HOME"
mkdir -p "$N8N_LOG_DIR"
chown -R "$N8N_USER":"$N8N_USER" "$N8N_HOME"
chown -R "$N8N_USER":"$N8N_USER" "$N8N_LOG_DIR"
chmod 750 "$N8N_HOME"
chmod 750 "$N8N_LOG_DIR"

# Install n8n globally
echo "[*] Installing n8n..."
npm install -g n8n

# Get the actual n8n binary path
N8N_BIN=$(which n8n)
if [ -z "$N8N_BIN" ]; then
    echo "[!] Error: n8n binary not found after installation"
    exit 1
fi
echo "[*] n8n installed at: $N8N_BIN"

# Generate encryption key
echo "[*] Generating encryption key..."
ENCRYPTION_KEY=$(openssl rand -base64 32)

# Create environment file
echo "[*] Creating environment file..."
cat > /etc/n8n.env << EOF
# n8n Environment Configuration
# Generated on $(date)

# Basic Configuration
N8N_HOST=${N8N_HOST}
N8N_PORT=${N8N_PORT}
N8N_PROTOCOL=http
WEBHOOK_URL=${WEBHOOK_URL}

# User Data Directory
N8N_USER_FOLDER=${N8N_HOME}

# Database (SQLite)
DB_TYPE=sqlite

# Security
N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}

# Basic Auth (uncomment and set to enable)
#N8N_BASIC_AUTH_ACTIVE=true
#N8N_BASIC_AUTH_USER=admin
#N8N_BASIC_AUTH_PASSWORD=changeme

# Execution Data Pruning
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168

# Timezone
GENERIC_TIMEZONE=America/New_York

# Logs
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file
N8N_LOG_FILE_LOCATION=${N8N_LOG_DIR}/n8n.log

# Disable telemetry
N8N_DIAGNOSTICS_ENABLED=false

# Editor URL (for webhooks to work properly)
WEBHOOK_TUNNEL_URL=${WEBHOOK_URL}
EOF

chmod 600 /etc/n8n.env
echo "[*] Environment file created at /etc/n8n.env"
echo "[!] IMPORTANT: Your encryption key is: ${ENCRYPTION_KEY}"
echo "[!] Save this key somewhere safe! You'll need it if you migrate."

# Create systemd service
echo "[*] Creating systemd service..."
cat > /etc/systemd/system/n8n.service << EOF
[Unit]
Description=n8n - Workflow Automation Tool
After=network.target

[Service]
Type=simple
User=n8n
Group=n8n
EnvironmentFile=/etc/n8n.env
ExecStart=${N8N_BIN} start
Restart=always
RestartSec=10
StandardOutput=append:/var/log/n8n/stdout.log
StandardError=append:/var/log/n8n/stderr.log

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/n8n /var/log/n8n
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF

# Create logrotate configuration
echo "[*] Setting up log rotation..."
cat > /etc/logrotate.d/n8n << EOF
${N8N_LOG_DIR}/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ${N8N_USER} ${N8N_USER}
    sharedscripts
    postrotate
        systemctl reload n8n > /dev/null 2>&1 || true
    endscript
}
EOF

# Reload systemd
echo "[*] Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start service
echo "[*] Enabling n8n service..."
systemctl enable n8n

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Configuration:"
echo "  - User: $N8N_USER"
echo "  - Home: $N8N_HOME"
echo "  - Logs: $N8N_LOG_DIR"
echo "  - Port: $N8N_PORT"
echo "  - Config: /etc/n8n.env"
echo ""
echo "Next steps:"
echo "  1. Edit /etc/n8n.env to configure your WEBHOOK_URL and other settings"
echo "  2. Start n8n: systemctl start n8n"
echo "  3. Check status: systemctl status n8n"
echo "  4. View logs: journalctl -u n8n -f"
echo "  5. Access n8n at: http://$(hostname -I | awk '{print $1}'):${N8N_PORT}"
echo ""
echo "IMPORTANT: Save your encryption key somewhere safe!"
echo "Encryption Key: ${ENCRYPTION_KEY}"
echo ""
echo "To enable basic auth, edit /etc/n8n.env and uncomment the auth lines"
echo ""
