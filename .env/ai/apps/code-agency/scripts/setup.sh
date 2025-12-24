#!/bin/bash
set -e

echo "==================================="
echo "AI Multi-Agent Workspace Setup"
echo "==================================="

SHARED_ROOT="$HOME/shared"

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$SHARED_ROOT/configs"
mkdir -p "$SHARED_ROOT/scripts"
mkdir -p "$SHARED_ROOT/ai-workspace/logs"
mkdir -p "$SHARED_ROOT/ai-workspace/chats"
mkdir -p "$SHARED_ROOT/ai-workspace/jobs/queue"
mkdir -p "$SHARED_ROOT/ai-workspace/jobs/active"
mkdir -p "$SHARED_ROOT/ai-workspace/jobs/completed"

# Create machines.yaml
echo "Creating machines.yaml..."
cat > "$SHARED_ROOT/configs/machines.yaml" <<'EOF'
agents:
  architect-gtx:
    host: gtx-machine:11434
    model: qwen2.5:32b-instruct-q4_K_M
    role: architect
    capabilities:
      - reasoning
      - architecture
      - planning
      - code_review
    permissions:
      - admin
      - general
      - workflow
    
  worker-i9:
    host: i9-machine:11434
    model: qwen2.5-coder:14b-instruct-q5_K_M
    role: developer
    capabilities:
      - code_generation
      - refactoring
      - implementation
      - testing
    permissions:
      - general
      - workflow
    
  worker-npu:
    host: localhost:11434
    model: qwen2.5-coder:7b-instruct-q4_K_M
    role: developer
    capabilities:
      - quick_tasks
      - testing
      - documentation
    permissions:
      - general
      - workflow
    
  worker-smol:
    host: smol-machine:11434
    model: qwen2.5-coder:1.5b-instruct-q4_K_M
    role: utility
    capabilities:
      - parsing
      - monitoring
      - simple_transforms
    permissions:
      - general
EOF

echo "machines.yaml created successfully"

# Create channels.yaml
echo "Creating channels.yaml..."
cat > "$SHARED_ROOT/configs/channels.yaml" <<'EOF'
channels:
  general:
    description: "Casual conversation, brainstorming, questions"
    members:
      - all
    typing_indicators: true
    
  admin:
    description: "Task assignment, system coordination, high-level decisions"
    members:
      - user
      - architect-gtx
    notifications: true
    priority: high
    
  workflow:
    description: "Workers coordinating on active jobs and implementations"
    members:
      - architect-gtx
      - worker-i9
      - worker-npu
      - worker-smol
    job_references: true
    typing_indicators: true
EOF

echo "channels.yaml created successfully"

# Initialize chat files
echo "Initializing chat channels..."
cat > "$SHARED_ROOT/ai-workspace/chats/general.md" <<'EOF'
# General Chat

Welcome to the general channel! This is for casual conversation and brainstorming.

EOF

cat > "$SHARED_ROOT/ai-workspace/chats/admin.md" <<'EOF'
# Admin Channel

This channel is for task assignment and high-level coordination between user and architect.

EOF

cat > "$SHARED_ROOT/ai-workspace/chats/workflow.md" <<'EOF'
# Workflow Channel

Workers coordinate here on active jobs and implementation details.

EOF

# Install Python dependencies
echo "Installing Python dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install --user pyyaml requests filelock 2>/dev/null || pip3 install --user --break-system-packages pyyaml requests filelock
else
    echo "Warning: pip3 not found, you may need to install dependencies manually:"
    echo "  pip3 install pyyaml requests filelock"
fi

# Create convenience scripts
echo "Creating convenience scripts..."

# Install worker script
cat > "$HOME/bin/ai-worker" <<'EOF'
#!/bin/bash
AGENT_ID="$1"
if [ -z "$AGENT_ID" ]; then
    echo "Usage: ai-worker <agent_id>"
    echo "Available agents:"
    grep -E "^  [a-z]" ~/shared/configs/machines.yaml | sed 's/:$//' | sed 's/^  /  - /'
    exit 1
fi
cd ~/shared/scripts
python3 worker.py "$AGENT_ID"
EOF
chmod +x "$HOME/bin/ai-worker"

# Install client script
cat > "$HOME/bin/ai-chat" <<'EOF'
#!/bin/bash
cd ~/shared/scripts
python3 client.py
EOF
chmod +x "$HOME/bin/ai-chat"

# Install monitor script
cat > "$HOME/bin/ai-monitor" <<'EOF'
#!/bin/bash
cd ~/shared/scripts
python3 monitor.py
EOF
chmod +x "$HOME/bin/ai-monitor"

# Create systemd service template
echo "Creating systemd service template..."
mkdir -p "$HOME/.config/systemd/user"

cat > "$HOME/.config/systemd/user/ai-worker@.service" <<EOF
[Unit]
Description=AI Worker Agent - %i
After=network.target

[Service]
Type=simple
WorkingDirectory=$HOME/shared/scripts
ExecStart=$HOME/bin/ai-worker %i
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

echo ""
echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Copy Python scripts to ~/shared/scripts/:"
echo "   - worker.py"
echo "   - client.py" 
echo "   - monitor.py"
echo ""
echo "2. Update ~/shared/configs/machines.yaml with correct hostnames"
echo ""
echo "3. On each machine, start the worker:"
echo "   GTX:  ai-worker architect-gtx"
echo "   i9:   ai-worker worker-i9"
echo "   NPU:  ai-worker worker-npu"
echo "   Smol: ai-worker worker-smol"
echo ""
echo "4. Or enable as systemd services:"
echo "   systemctl --user enable ai-worker@architect-gtx"
echo "   systemctl --user start ai-worker@architect-gtx"
echo ""
echo "5. Start chatting:"
echo "   ai-chat"
echo ""
echo "6. Monitor system:"
echo "   ai-monitor"
echo ""