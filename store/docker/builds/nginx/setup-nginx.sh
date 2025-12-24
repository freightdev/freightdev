#!/bin/bash

set -e

# Check if core directory exists
if [ ! -d core ]; then
    echo "Error: core directory not found!"
    exit 1
fi

#####################################
# NGINX SETUP
#####################################
echo "=== Nginx Setup ==="
echo "Installing Nginx Reverse Proxy..."

# Load environment variables
if [ -f .env.local ]; then
    export $(cat .env.local | xargs)
else
    echo "Error: .env.local not found!"
    exit 1
fi

# Install dependencies
sudo apt update
sudo apt install -y nginx gettext

# Create nginx directories if needed
sudo mkdir -p /etc/nginx/sites

# Copy Nginx Configurations
cp core/configs/nginx.conf /etc/nginx/nginx.conf

# Process templates
SITES=(
    "workbox:conf.tpl"
    "helpbox:conf.tpl"
    "helpbox:conf.tpl"
    "safebox:conf.tpl"
)

for site in "${SITES[@]}"; do
    IFS=':' read -r name format <<< "$site"
    if [ -f "core/templates/$name.$format" ]; then
        envsubst < "core/templates/$name.$format" | sudo tee /etc/nginx/sites/$name.conf > /dev/null
        echo "✓ Processed $name.$format"
    else
        echo "⚠ Warning: core/templates/$name.$format not found, skipping"
    fi
done

#########################################
# SYSTEMD SETUP
#########################################
echo "=== Systemd Service Setup ==="

# Copy systemd service files
sudo cp /home/host/src/containers/callbox/core/services/nginx.service /etc/systemd/system/nginx.service

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable nginx
sudo systemctl start nginx

# Check status
sudo systemctl status nginx --no-pager

#####################################
# VERIFICATION
#####################################
echo ""
echo "✓ Nginx setup complete!"
echo "Verify config with: sudo nginx -t"
echo ""
echo "View logs:"
echo "  sudo journalctl -u nginx -f"
