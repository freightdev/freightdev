#!/bin/bash
# Setup automatic state synchronization

echo "🔧 Setting up automatic CoDriver state sync..."

# Create systemd user service
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/codriver-state-sync.service <<'EOF'
[Unit]
Description=CoDriver State Sync
After=network.target

[Service]
Type=oneshot
ExecStart=/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo/src/scripts/state-sync.sh "auto_backup" "$(date)"
EOF

cat > ~/.config/systemd/user/codriver-state-sync.timer <<'EOF'
[Unit]
Description=CoDriver State Sync Timer
Requires=codriver-state-sync.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start timer
systemctl --user daemon-reload
systemctl --user enable codriver-state-sync.timer
systemctl --user start codriver-state-sync.timer

echo "✅ Auto-sync enabled!"
echo ""
echo "📊 Status: $(systemctl --user status codriver-state-sync.timer --no-pager | head -5)"
echo ""
echo "💡 Commands:"
echo "   systemctl --user status codriver-state-sync.timer   # Check status"
echo "   systemctl --user stop codriver-state-sync.timer     # Disable auto-sync"
echo "   journalctl --user -u codriver-state-sync.service    # View sync logs"
