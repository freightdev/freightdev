#!/bin/bash
# Ollama Cluster Setup Script

set -e

echo "=== Ollama Cluster Mesh Setup ==="
echo

# Get node IPs
read -p "Enter ALL node IPs (space-separated, including this one): " NODE_IPS
read -p "Enter THIS machine's IP: " THIS_IP

# Convert to array
IFS=' ' read -ra NODES <<< "$NODE_IPS"

echo
echo "Cluster nodes: ${NODES[@]}"
echo "This node: $THIS_IP"
echo
read -p "Proceed? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# 1. Configure nftables
echo "=== Configuring nftables ==="
sudo tee /etc/nftables.conf > /dev/null << 'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
        chain input {
                type filter hook input priority filter; policy accept;
                iif lo accept
                ct state established,related accept
                ip saddr 192.168.12.0/24 tcp dport 11434 accept
        }
        chain forward {
                type filter hook forward priority filter; policy accept;
        }
        chain output {
                type filter hook output priority filter; policy accept;
        }
}
EOF

sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables
echo "✓ nftables configured"

# 2. Configure Ollama service
echo "=== Configuring Ollama service ==="
sudo tee /etc/systemd/system/ollama.service > /dev/null << 'EOF'
[Unit]
Description=Ollama LLM Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ollama
WorkingDirectory=/home/ollama
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
echo "✓ Ollama service configured and restarted"

# 3. Create cluster management script
echo "=== Creating cluster management tools ==="
tee ~/ollama-cluster.py > /dev/null << 'PYEOF'
#!/usr/bin/env python3
import requests
import json
import sys
from typing import List, Dict

class OllamaCluster:
    def __init__(self, nodes: List[str]):
        self.nodes = nodes
    
    def list_all_models(self) -> Dict[str, List]:
        inventory = {}
        for node in self.nodes:
            try:
                r = requests.get(f"http://{node}:11434/api/tags", timeout=2)
                inventory[node] = [m['name'] for m in r.json()['models']]
            except:
                inventory[node] = []
        return inventory
    
    def find_model(self, model: str) -> List[str]:
        nodes_with_model = []
        for node in self.nodes:
            try:
                r = requests.get(f"http://{node}:11434/api/tags", timeout=2)
                if any(model in m['name'] for m in r.json()['models']):
                    nodes_with_model.append(node)
            except:
                pass
        return nodes_with_model
    
    def generate(self, node: str, model: str, prompt: str, stream: bool = False):
        url = f"http://{node}:11434/api/generate"
        data = {"model": model, "prompt": prompt, "stream": stream}
        r = requests.post(url, json=data, stream=stream)
        if stream:
            for line in r.iter_lines():
                if line:
                    yield json.loads(line)
        else:
            return r.json()['response']
    
    def health_check(self) -> Dict[str, bool]:
        status = {}
        for node in self.nodes:
            try:
                requests.get(f"http://{node}:11434/api/tags", timeout=1)
                status[node] = True
            except:
                status[node] = False
        return status

if __name__ == "__main__":
    nodes = "$NODE_IPS".split()
    cluster = OllamaCluster(nodes)
    
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "list":
            for node, models in cluster.list_all_models().items():
                print(f"\n=== {node} ===")
                for m in models:
                    print(f"  {m}")
        elif cmd == "health":
            for node, alive in cluster.health_check().items():
                status = "✓" if alive else "✗"
                print(f"{status} {node}")
        elif cmd == "find" and len(sys.argv) > 2:
            model = sys.argv[2]
            nodes = cluster.find_model(model)
            if nodes:
                print(f"Model '{model}' found on: {', '.join(nodes)}")
            else:
                print(f"Model '{model}' not found on any node")
    else:
        print("Usage: ollama-cluster.py [list|health|find MODEL]")
PYEOF

chmod +x ~/ollama-cluster.py
echo "✓ Python cluster manager created"

# 4. Create bash helper functions
echo "=== Creating bash helpers ==="
tee -a ~/.bashrc > /dev/null << BASHEOF

# Ollama Cluster Management
export OLLAMA_NODES="$NODE_IPS"

ollama-cluster-list() {
    ~/ollama-cluster.py list
}

ollama-cluster-health() {
    ~/ollama-cluster.py health
}

ollama-cluster-find() {
    ~/ollama-cluster.py find "\$1"
}

ollama-on() {
    local node=\$1
    shift
    OLLAMA_HOST=http://\$node:11434 ollama "\$@"
}

BASHEOF

echo "✓ Bash helpers added to ~/.bashrc"

# 5. Test cluster
echo
echo "=== Testing Cluster ==="
sleep 2
for node in "${NODES[@]}"; do
    echo -n "Testing $node... "
    if curl -s --connect-timeout 2 http://$node:11434/api/tags > /dev/null 2>&1; then
        echo "✓"
    else
        echo "✗ (unreachable)"
    fi
done

echo
echo "=== Setup Complete ==="
echo
echo "Reload shell to use helpers:"
echo "  source ~/.bashrc"
echo
echo "Commands available:"
echo "  ollama-cluster-health          # Check all nodes"
echo "  ollama-cluster-list            # List all models"
echo "  ollama-cluster-find MODEL      # Find which nodes have MODEL"
echo "  ollama-on IP run MODEL PROMPT  # Run on specific node"
echo
echo "Example:"
echo "  ollama-on 192.168.12.66 run codellama:13b 'hello'"
echo
