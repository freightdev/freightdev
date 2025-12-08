#!/bin/bash
# Deploy OpenHWY for TTY + tmux workflow

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🚛 OpenHWY TTY + tmux Deployment"
echo ""

# ============================================
# 1. Build all tools
# ============================================
echo -e "${BLUE}[1/5]${NC} Building tools..."

cd ~/moon-env && cargo build --release
cd ~/marketeer-dashboard && cargo build --release
cd ~/agent-builder && cargo build --release

echo -e "${GREEN}✓${NC} All tools built"

# ============================================
# 2. Install binaries
# ============================================
echo -e "${BLUE}[2/5]${NC} Installing binaries..."

mkdir -p ~/bin
cp ~/moon-env/target/release/moon-env ~/bin/
cp ~/marketeer-dashboard/target/release/marketeer-dashboard ~/bin/
cp ~/agent-builder/target/release/agent-builder ~/bin/
cp openhwy ~/bin/
cp openhwy-workspace ~/bin/
chmod +x ~/bin/*

echo -e "${GREEN}✓${NC} Binaries installed to ~/bin"

# Add to PATH
if ! echo $PATH | grep -q "$HOME/bin"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    echo -e "${GREEN}✓${NC} Added ~/bin to PATH"
fi

# ============================================
# 3. Setup tmux integration
# ============================================
echo -e "${BLUE}[3/5]${NC} Setting up tmux integration..."

if [ -f ~/.tmux.conf ]; then
    # Backup existing config
    cp ~/.tmux.conf ~/.tmux.conf.backup
    echo -e "${YELLOW}ℹ${NC} Backed up existing ~/.tmux.conf"
fi

# Append OpenHWY config
if ! grep -q "# OpenHWY tmux configuration" ~/.tmux.conf 2>/dev/null; then
    cat tmux.conf >> ~/.tmux.conf
    echo -e "${GREEN}✓${NC} tmux configuration added"
else
    echo -e "${GREEN}✓${NC} tmux configuration already exists"
fi

# Reload tmux if running
if tmux info &>/dev/null; then
    tmux source-file ~/.tmux.conf
    echo -e "${GREEN}✓${NC} tmux config reloaded"
fi

# ============================================
# 4. Setup ranger integration
# ============================================
echo -e "${BLUE}[4/5]${NC} Setting up ranger integration..."

mkdir -p ~/.config/ranger

# Commands
if [ -f ~/.config/ranger/commands.py ]; then
    if ! grep -q "class marketeer" ~/.config/ranger/commands.py; then
        cat ranger_commands.py >> ~/.config/ranger/commands.py
        echo -e "${GREEN}✓${NC} Ranger commands added"
    fi
else
    cp ranger_commands.py ~/.config/ranger/commands.py
    echo -e "${GREEN}✓${NC} Ranger commands created"
fi

# Keybindings
if [ -f ~/.config/ranger/rc.conf ]; then
    if ! grep -q "# OpenHWY Tools" ~/.config/ranger/rc.conf; then
        cat ranger_rc.conf >> ~/.config/ranger/rc.conf
        echo -e "${GREEN}✓${NC} Ranger keybindings added"
    fi
else
    cp ranger_rc.conf ~/.config/ranger/rc.conf
    echo -e "${GREEN}✓${NC} Ranger keybindings created"
fi

# ============================================
# 5. Deploy to headless boxes
# ============================================
echo -e "${BLUE}[5/5]${NC} Deploying to headless boxes..."
echo ""

for box in helpbox hostbox callbox; do
    echo -n "  $box... "
    if ssh -o ConnectTimeout=3 admin@$box "echo ok" &>/dev/null; then
        ssh admin@$box "mkdir -p ~/bin ~/agents ~/moon-env"
        scp ~/bin/moon-env admin@$box:~/bin/ &>/dev/null
        scp ~/bin/openhwy admin@$box:~/bin/ &>/dev/null
        scp ~/marketeer-workbox.toml admin@$box:~/ &>/dev/null
        ssh admin@$box "chmod +x ~/bin/*" &>/dev/null
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ unreachable${NC}"
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚛 OpenHWY Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "TTY Workflow:"
echo "  ${BLUE}openhwy m${NC}         - Marketeer Dashboard"
echo "  ${BLUE}openhwy agent${NC}     - Agent Builder"
echo "  ${BLUE}openhwy status${NC}    - System status"
echo "  ${BLUE}openhwy-workspace${NC} - Full workspace"
echo ""
echo "Tmux Keybindings (in tmux, press prefix then):"
echo "  ${BLUE}M${NC} - Marketeer (split bottom)"
echo "  ${BLUE}A${NC} - Agent Builder (new window)"
echo "  ${BLUE}S${NC} - Status popup"
echo "  ${BLUE}h${NC} - SSH helpbox"
echo "  ${BLUE}H${NC} - SSH hostbox"
echo "  ${BLUE}C${NC} - SSH callbox"
echo "  ${BLUE}O${NC} - Full workspace setup"
echo ""
echo "Ranger Keybindings (in ranger, press):"
echo "  ${BLUE}om${NC} - Marketeer"
echo "  ${BLUE}oa${NC} - Agent Builder"
echo "  ${BLUE}oh/oo/oc${NC} - SSH to boxes"
echo ""
echo "Next steps:"
echo "  1. ${YELLOW}source ~/.bashrc${NC} (or restart shell)"
echo "  2. ${YELLOW}openhwy-workspace${NC} (launch full environment)"
echo "  3. Start building! 🚀"
