#!/bin/bash
# Deploy OpenHWY tools across infrastructure
# Run this from workbox

set -e

echo "🚛 OpenHWY Infrastructure Deployment"
echo ""

# Systems (update with your actual hostnames/IPs)
HEADLESS_BOXES="helpbox hostbox callbox"
CLOUD_BOX="safebox"  # Update with Oracle Cloud IP

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# 1. BUILD ON WORKBOX
# ============================================
echo -e "${BLUE}[WORKBOX]${NC} Building all tools..."

# Neovim (if not already done)
if [ ! -d ~/.config/nvim ]; then
    ./setup_nvim.sh
fi

# Moon Environment
cd ~/moon-env 2>/dev/null || {
    ./setup_moon.sh
    cd ~/moon-env
}
cargo build --release
echo -e "${GREEN}✓${NC} Moon Environment built"

# Marketeer Dashboard
cd ~/marketeer-dashboard 2>/dev/null || {
    ./setup_marketeer.sh
    cd ~/marketeer-dashboard
}
cargo build --release
echo -e "${GREEN}✓${NC} Marketeer Dashboard built"

# Agent Builder
cd ~/agent-builder 2>/dev/null || {
    ./run_agent_builder.sh &
    sleep 2
    pkill agent-builder
    cd ~/agent-builder
}
cargo build --release
echo -e "${GREEN}✓${NC} Agent Builder built"

# Create bin directory
mkdir -p ~/bin

# Copy binaries
cp ~/moon-env/target/release/moon-env ~/bin/
cp ~/marketeer-dashboard/target/release/marketeer-dashboard ~/bin/
cp ~/agent-builder/target/release/agent-builder ~/bin/

echo -e "${GREEN}✓${NC} All tools built on workbox"
echo ""

# ============================================
# 2. DEPLOY TO HEADLESS BOXES
# ============================================
for box in $HEADLESS_BOXES; do
    echo -e "${BLUE}[$box]${NC} Deploying..."
    
    # Test connection
    if ! ssh -o ConnectTimeout=5 admin@$box "echo 'connected'" &>/dev/null; then
        echo -e "${RED}✗${NC} Cannot reach $box, skipping..."
        continue
    fi
    
    # Create directories
    ssh admin@$box "mkdir -p ~/bin ~/agents ~/moon-env"
    
    # Copy moon-env binary
    scp ~/bin/moon-env admin@$box:~/bin/
    
    # Copy configs
    scp ~/marketeer-workbox.toml admin@$box:~/marketeer.toml
    scp ~/ssh_stats.sh admin@$box:~/
    
    # Copy agent configs if they exist
    if [ -d ~/agents ]; then
        scp -r ~/agents/* admin@$box:~/agents/ 2>/dev/null || true
    fi
    
    # Make scripts executable
    ssh admin@$box "chmod +x ~/bin/* ~/ssh_stats.sh"
    
    echo -e "${GREEN}✓${NC} $box deployed"
done

echo ""

# ============================================
# 3. DEPLOY TO CLOUD (SAFEBOX)
# ============================================
echo -e "${BLUE}[safebox]${NC} Deploying to Oracle Cloud..."

if ssh -o ConnectTimeout=10 admin@$CLOUD_BOX "echo 'connected'" &>/dev/null; then
    ssh admin@$CLOUD_BOX "mkdir -p ~/bin ~/agents ~/moon-env"
    scp ~/bin/moon-env admin@$CLOUD_BOX:~/bin/
    scp ~/marketeer-workbox.toml admin@$CLOUD_BOX:~/marketeer.toml
    scp ~/ssh_stats.sh admin@$CLOUD_BOX:~/
    ssh admin@$CLOUD_BOX "chmod +x ~/bin/* ~/ssh_stats.sh"
    echo -e "${GREEN}✓${NC} safebox deployed"
else
    echo -e "${RED}✗${NC} Cannot reach safebox (check Oracle Cloud config)"
fi

echo ""

# ============================================
# 4. SETUP HYPRLAND BINDING
# ============================================
echo -e "${BLUE}[WORKBOX]${NC} Setting up Hyprland binding..."

if [ -f ~/.config/hypr/hyprland.conf ]; then
    if ! grep -q "marketeer" ~/.config/hypr/hyprland.conf; then
        cat >> ~/.config/hypr/hyprland.conf << 'EOF'

# OpenHWY Marketeer Dashboard
bind = SUPER, M, exec, alacritty --class marketeer -e ~/bin/marketeer-dashboard ~/marketeer-workbox.toml
windowrulev2 = float, class:^(marketeer)$
windowrulev2 = size 80% 80%, class:^(marketeer)$
windowrulev2 = center, class:^(marketeer)$
EOF
        echo -e "${GREEN}✓${NC} Hyprland binding added (Super+M)"
        echo "   Run 'hyprctl reload' or restart Hyprland"
    else
        echo -e "${GREEN}✓${NC} Hyprland binding already exists"
    fi
else
    echo -e "${BLUE}ℹ${NC} Hyprland config not found, skipping binding setup"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "On workbox:"
echo "  • Press Super+M to launch Marketeer Dashboard"
echo "  • Run 'agent-builder' to create agents"
echo "  • Run 'moon-env config.toml agent.lua' to test agents locally"
echo ""
echo "On headless boxes (helpbox, hostbox, callbox, safebox):"
echo "  • SSH in: ssh admin@<box>"
echo "  • Run agents: moon-env config.toml agent.lua"
echo "  • View logs: tail -f /var/log/agents/*.log"
echo ""
echo "All systems ready for OpenHWY development!"
