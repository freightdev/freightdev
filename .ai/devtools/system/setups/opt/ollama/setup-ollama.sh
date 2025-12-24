#!/bin/bash
# setup-ollama.sh - Ollama Setup
set -e

#####################################
# OLLAMA SETUP
#####################################
echo "=== Ollama Setup ==="
echo "Installing Ollama LLM Server..."

# Create ollama user
sudo useradd -m -s /bin/bash ollama || echo "User ollama already exists"

# Download and install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Create ollama directories
sudo mkdir -p /home/ollama/.ollama
sudo chown -R ollama:ollama /home/ollama/.ollama

# Copy systemd service file
sudo cp core/services/ollama.service /etc/systemd/system/ollama.service

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama

echo "Waiting for Ollama to start..."
sleep 3

# Check status
sudo systemctl status ollama --no-pager

#####################################
# VERIFICATION
#####################################
echo ""
echo "✓ Ollama setup complete!"
echo "Access at: http://localhost:11434"
echo ""
echo "Pull a model: ollama pull llama2"
echo ""
echo "View logs:"
echo "  sudo journalctl -u ollama -f"