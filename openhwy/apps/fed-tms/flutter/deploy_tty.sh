#!/bin/bash
# Deploy OpenHWY for TTY workflow

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🚛 OpenHWY TTY Deployment"
echo ""

# Build all tools
echo -e "${BLUE}Building tools...${NC}"
cd ~/moon-env && cargo build --release
cd ~/marketeer-dashboard && cargo build --release
cd ~/agent-builder && cargo build --release

# Install to ~/bin
mkdir -p ~/bin
cp ~/moon-env/target/release/moon-env ~/bin/
cp ~/marketeer-dashboard/target/release/marketeer-dashboard ~/bin/
cp ~/agent-builder/target/release/agent-builder ~/bin/
cp openhwy ~/bin/
chmod +x ~/bin/openhwy

echo -e "${GREEN}✓${NC} Binaries installed to ~/bin"

# Add to PATH if not already
if ! echo $PATH | grep -q "$HOME/bin"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    echo -e "${GREEN}✓${NC} Added ~/bin to PATH (restart shell)"
fi

# Setup ranger integration
echo -e "${BLUE}Setting up ranger integration...${NC}"
mkdir -p ~/.config/ranger

# Append commands
if [ -f ~/.config/ranger/commands.py ]; then
    if ! grep -q "class marketeer" ~/.config/ranger/commands.py; then
        cat ranger_commands.py >> ~/.config/ranger/commands.py
        echo -e "${GREEN}✓${NC} Ranger commands added"
    fi
else
    cp ranger_commands.py ~/.config/ranger/commands.py
    echo -e "${GREEN}✓${NC} Ranger commands created"
fi

# Append keybindings
if [ -f ~/.config/ranger/rc.conf ]; then
    if ! grep -q "# OpenHWY Tools" ~/.config/ranger/rc.conf; then
        cat ranger_rc.conf >> ~/.config/ranger/rc.conf
        echo -e "${GREEN}✓${NC} Ranger keybindings added"
    fi
else
    cp ranger_rc.conf ~/.config/ranger/rc.conf
    echo -e "${GREEN}✓${NC} Ranger keybindings created"
fi

# Deploy to headless boxes
echo ""
echo -e "${BLUE}Deploying to headless boxes...${NC}"

for box in helpbox hostbox callbox; do
    if ssh -o ConnectTimeout=3 admin@$box "echo ok" &>/dev/null; then
        ssh admin@$box "mkdir -p ~/bin ~/agents"
        scp ~/bin/moon-env admin@$box:~/bin/
        scp ~/bin/openhwy admin@$box:~/bin/
        ssh admin@$box "chmod +x ~/bin/*"
        echo -e "${GREEN}✓${NC} $box deployed"
    else
        echo "⚠️  $box unreachable, skipping"
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "TTY Usage:"
echo "  openhwy m         - Marketeer Dashboard"
echo "  openhwy agent     - Agent Builder"
echo "  openhwy status    - System status"
echo "  openhwy help      - Full help"
echo ""
echo "In Ranger:"
echo "  om - Marketeer"
echo "  oa - Agent Builder"
echo "  oh - SSH to helpbox"
echo "  oo - SSH to hostbox"
echo "  oc - SSH to callbox"
echo ""
echo "Restart your shell or run: source ~/.bashrc"
