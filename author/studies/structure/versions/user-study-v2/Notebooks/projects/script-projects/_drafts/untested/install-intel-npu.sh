#!/usr/bin/env bash
set -euo pipefail

# Vars
INSTALL_DIR="/opt/intel/openvino"
TMP_DIR="/tmp/openvino-npu"
NPU_URL="https://storage.openvinotoolkit.org/repositories/openvino/packages/2025.2/linux/l_openvino_toolkit_runtime_rhel8_2025.2.0.15883.37b361da88_x86_64.tgz"

# Step 1: Prep
echo "[*] Downloading OpenVINO runtime with NPU compiler..."
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"
curl -LO "$NPU_URL"

# Step 2: Extract
echo "[*] Extracting..."
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf *.tgz -C "$INSTALL_DIR" --strip-components=1

# Step 3: Symlink env vars
echo "[*] Creating OpenVINO env script..."
cat << 'EOF' | sudo tee /etc/profile.d/openvino.sh >/dev/null
#!/bin/bash
export OPENVINO_DIR=/opt/intel/openvino
source /opt/intel/openvino/setupvars.sh
EOF
sudo chmod +x /etc/profile.d/openvino.sh

# Step 4: Load now for this shell
source /opt/intel/openvino/setupvars.sh

# Step 5: Confirm tools
echo "[*] Verifying install..."
echo " - bin: $(command -v benchmark_app || echo 'Not found')"
echo " - plugins: $OPENVINO_DIR/runtime/lib/intel64"

# Step 6: Clean up
echo "[*] Cleaning up temp files..."
rm -rf "$TMP_DIR"

echo "[✔] OpenVINO NPU runtime installed to: $INSTALL_DIR"
echo "Restart your shell or run: source /etc/profile.d/openvino.sh"
