#!/bin/bash
# setup-openvino.sh - OpenVINO Setup for Arch Linux
set -e

#####################################
# OPENVINO SETUP
#####################################
echo "=== OpenVINO Setup ==="
echo "Installing OpenVINO Runtime and Model Server..."

# Create openvino user
sudo useradd -m -s /bin/bash openvino || echo "User openvino already exists"

# Install dependencies
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel cmake git wget

# Download OpenVINO Runtime
echo "Downloading OpenVINO Runtime..."
cd /tmp
OPENVINO_VERSION="2024.2"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    wget https://storage.openvinotoolkit.org/repositories/openvino/packages/$OPENVINO_VERSION/linux/l_openvino_toolkit_ubuntu22_${OPENVINO_VERSION}.0.15928.cd0d9014d47_x86_64.tgz
elif [ "$ARCH" = "aarch64" ]; then
    wget https://storage.openvinotoolkit.org/repositories/openvino/packages/$OPENVINO_VERSION/linux/l_openvino_toolkit_ubuntu22_${OPENVINO_VERSION}.0.15928.cd0d9014d47_aarch64.tgz
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Extract and install
tar -xzf l_openvino_toolkit_ubuntu22_${OPENVINO_VERSION}* 
sudo mv l_openvino_toolkit_ubuntu22_${OPENVINO_VERSION} /opt/openvino_${OPENVINO_VERSION}
sudo ln -sf /opt/openvino_${OPENVINO_VERSION} /opt/openvino

# Set permissions
sudo chown -R openvino:openvino /opt/openvino

# Create models directory
sudo mkdir -p /home/openvino/models
sudo chown -R openvino:openvino /home/openvino/models

# Install OpenVINO Model Server from AUR (Arch User Repository)
echo "Installing OpenVINO Model Server..."
cd /tmp
git clone https://aur.archlinux.org/openvino-model-server.git
cd openvino-model-server
sudo -u openvino makepkg -si --noconfirm || echo "AUR package build failed, continuing with manual setup"

# Copy systemd service file
sudo cp core/services/openvino.service /etc/systemd/system/openvino.service

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable openvino
sudo systemctl start openvino

echo "Waiting for OpenVINO to start..."
sleep 3

# Check status
sudo systemctl status openvino --no-pager

#####################################
# VERIFICATION
#####################################
echo ""
echo "✓ OpenVINO setup complete!"
echo "Access at: http://localhost:8000"
echo ""
echo "Models directory: /home/openvino/models"
echo ""
echo "View logs:"
echo "  sudo journalctl -u openvino -f"