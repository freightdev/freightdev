# Quick Start Guide

Get your AI multi-agent system running in 5 minutes.

## Prerequisites

- ✅ NFS server running on NPU machine (already done)
- ✅ All machines can mount ~/shared/ai-workspace
- ✅ Ollama running on all machines with models pulled
- ✅ Python 3.x installed on all machines

## Installation

### 1. Run Setup on NPU Machine (NFS Server)

```bash
# Download setup script
cd ~
chmod +x setup.sh
./setup.sh
```

This creates:

- Directory structure
- Configuration files
- Convenience scripts

### 2. Copy Python Scripts

```bash
# Copy the three Python files to scripts directory
cp worker.py ~/shared/scripts/
cp client.py ~/shared/scripts/
cp monitor.py ~/shared/scripts/
chmod +x ~/shared/scripts/*.py

# Copy control script to bin
cp ai-control.sh ~/bin/ai-control
chmod +x ~/bin/ai-control
```

### 3. Update Machine Configuration

Edit `~/shared/configs/machines.yaml` and replace hostnames:

```bash
nano ~/shared/configs/machines.yaml
```

Replace:

- `gtx-machine:11434` with actual GTX machine IP/hostname
- `i9-machine:11434` with actual i9 machine IP/hostname
- `smol-machine:11434` with actual Smol machine IP/hostname
- `localhost:11434` is fine for NPU (current machine)

Example:

```yaml
architect-gtx:
  host: 192.168.1.10:11434 # Your GTX machine
  model: qwen2.5:32b-instruct-q4_K_M
  # ...
```

### 4. Mount NFS on Other Machines

On **GTX, i9, and Smol machines**:

```bash
# Install NFS client
sudo apt install nfs-common

# Create mount point
mkdir -p ~/shared/ai-workspace

# Mount (replace npu-machine with actual hostname/IP)
sudo mount -t nfs npu-machine:/home/admin/shared/ai-workspace ~/shared/ai-workspace

# Make permanent
echo "npu-machine:/home/admin/shared/ai-workspace ~/shared/ai-workspace nfs defaults 0 0" | sudo tee -a /etc/fstab

# Test
touch ~/shared/ai-workspace/test.txt
# Verify it shows up on NPU machine
```

### 5. Install Python Dependencies on All Machines

```bash
pip3 install --user pyyaml requests filelock
# Or if that fails:
pip3 install --user --break-system-packages pyyaml requests filelock
```

### 6. Copy Scripts to Other Machines

On **GTX, i9, and Smol machines**:

```bash
# Scripts are already in ~/shared/scripts via NFS mount
# Just need the bin scripts

mkdir -p ~/bin

# Create ai-worker
cat > ~/bin/ai-worker <<'EOF'
#!/bin/bash
AGENT_ID="$1"
if [ -z "$AGENT_ID" ]; then
    echo "Usage: ai-worker <agent_id>"
    exit 1
fi
cd ~/shared/scripts
python3 worker.py "$AGENT_ID"
EOF
chmod +x ~/bin/ai-worker

# Create ai-control
cp ~/shared/scripts/ai-control.sh ~/bin/ai-control
chmod +x ~/bin/ai-control
```

### 7. Start Workers

On each machine:

```bash
# GTX machine
ai-worker architect-gtx

# i9 machine
ai-worker worker-i9

# NPU machine (you're probably here)
ai-worker worker-npu

# Smol machine
ai-worker worker-smol
```

Or use systemd (recommended):

```bash
# On each machine
systemctl --user enable ai-worker@<agent-name>
systemctl --user start ai-worker@<agent-name>

# Example on GTX:
systemctl --user enable ai-worker@architect-gtx
systemctl --user start ai-worker@architect-gtx

# Check status
systemctl --user status ai-worker@architect-gtx
```

### 8. Test System

```bash
# Check all agents are running
ai-control status

# Test Ollama connections
ai-control test

# Start monitoring
ai-monitor
```

## First Use

### Start Chat Client

```bash
ai-chat
```

### Test Communication

In the chat client:

```
Hello everyone!
```

You should see responses from active agents.

### Create Your First Job

```
/job create
```

Follow the prompts to create a job, then assign it:

```
/job assign job-1234567890 worker-i9
```

Watch the workflow channel to see it execute.

## Verification Checklist

✅ **NFS Mount Working**

```bash
# On any machine
touch ~/shared/ai-workspace/test-$(hostname).txt
# Verify visible on all machines
ls ~/shared/ai-workspace/
```

✅ **Agents Running**

```bash
ai-control status
# All agents should show RUNNING
```

✅ **Ollama Accessible**

```bash
ai-control test
# All should show ✓ OK
```

✅ **Heartbeats Active**

```bash
tail ~/shared/ai-workspace/logs/ping.log
# Should see recent pings from all agents
```

✅ **Chat Working**

```bash
ai-chat
# Type a message, agents should respond
```

## Troubleshooting

### Agent Won't Start

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Check if model is pulled
ollama list

# Pull model if missing
ollama pull qwen2.5:32b-instruct-q4_K_M
```

### NFS Mount Issues

```bash
# Check NFS exports on server
sudo exportfs -v

# Check mount on client
mount | grep shared

# Remount
sudo umount ~/shared/ai-workspace
sudo mount -a
```

### Agent Crashes

```bash
# Check logs
ai-control logs architect-gtx

# Or directly
tail -f ~/shared/ai-workspace/logs/system.log
tail -f ~/shared/ai-workspace/logs/error.log
```

### No Responses in Chat

1. Check agents are running: `ai-control status`
2. Check system logs: `tail ~/shared/ai-workspace/logs/system.log`
3. Verify channel permissions in `~/shared/configs/channels.yaml`
4. Test Ollama: `ai-control test`

## Daily Usage

### Morning Startup

```bash
# Check system health
ai-control status
ai-control test

# Start monitoring in tmux/screen
tmux new -s monitor
ai-monitor
# Ctrl+B, D to detach

# Start chat
ai-chat
```

### Create and Assign Work

```bash
# In ai-chat
/channel admin
@architect-gtx I need to build a user authentication system

# After discussion
/job create
# ... fill in details

/job assign job-XXX worker-i9
/channel workflow
# Watch it work
```

### End of Day

```bash
# Check what was completed
/job list

# Clean up
ai-control clean

# Backup
ai-control backup
```

## Next Steps

1. **Read the Full README**: `~/shared/README.md`
2. **Customize Agents**: Edit `~/shared/configs/machines.yaml`
3. **Add Channels**: Edit `~/shared/configs/channels.yaml`
4. **Create Job Templates**: Add to `~/shared/ai-workspace/jobs/templates/`
5. **Integrate with Tools**: Modify `worker.py` for git, CI/CD, etc.

## Quick Reference

**Commands:**

- `ai-chat` - Interactive chat with agents
- `ai-monitor` - Real-time system monitor
- `ai-control status` - Check agent status
- `ai-control test` - Test connections
- `ai-control logs <agent>` - View agent logs
- `ai-control clean` - Clean old logs/jobs
- `ai-control backup` - Backup workspace

**Channels:**

- `general` - Casual chat, questions
- `admin` - You + architect for planning
- `workflow` - Workers coordinating on jobs

**Chat Commands:**

- `/channel <name>` - Switch channel
- `/job create` - Create job
- `/job list` - List jobs
- `/job assign <id> <agent>` - Assign job
- `/status` - Agent status
- `/help` - Show help
- `/quit` - Exit

**File Locations:**

- Config: `~/shared/configs/`
- Scripts: `~/shared/scripts/`
- Workspace: `~/shared/ai-workspace/`
- Logs: `~/shared/ai-workspace/logs/`
- Jobs: `~/shared/ai-workspace/jobs/`
- Chats: `~/shared/ai-workspace/chats/`

## Support

If something isn't working:

1. Check logs: `~/shared/ai-workspace/logs/`
2. Run diagnostics: `ai-control test`
3. Verify NFS: `df -h | grep shared`
4. Check Ollama: `curl http://host:11434/api/tags`
5. Read README: `~/shared/README.md`

## That's It!

You now have a fully functional multi-agent AI development system. Start with simple tasks in the general channel, then move to structured job-based workflows.

Happy building! 🚀
