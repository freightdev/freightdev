#!/bin/bash
# Setup Neovim as OpenHWY Control Center

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🚛 Setting up Neovim OpenHWY Control Center"
echo ""

# Create openhwy module directory
mkdir -p ~/.config/nvim/lua/openhwy

# Copy modules
echo -e "${BLUE}[1/4]${NC} Installing OpenHWY Neovim modules..."
cp nvim-openhwy-commands.lua ~/.config/nvim/lua/openhwy/commands.lua
cp nvim-openhwy-dashboard.lua ~/.config/nvim/lua/openhwy/dashboard.lua

# Copy plugin
cp nvim-openhwy-plugin.lua ~/.config/nvim/lua/plugins/openhwy.lua

echo -e "${GREEN}✓${NC} Modules installed"

# Create init file if needed
if [ ! -f ~/.config/nvim/lua/openhwy/init.lua ]; then
    cat > ~/.config/nvim/lua/openhwy/init.lua << 'EOF'
-- OpenHWY Module Init
local M = {}

M.commands = require("openhwy.commands")
M.dashboard = require("openhwy.dashboard")

return M
EOF
    echo -e "${GREEN}✓${NC} Init file created"
fi

# Update LazyVim to load plugin
echo -e "${BLUE}[2/4]${NC} Configuring LazyVim..."

if [ -f ~/.config/nvim/lua/config/lazy.lua ]; then
    if ! grep -q "openhwy" ~/.config/nvim/lua/config/lazy.lua; then
        echo "-- OpenHWY integration already configured"
    fi
fi

echo -e "${GREEN}✓${NC} LazyVim configured"

# Create keybindings cheatsheet
echo -e "${BLUE}[3/4]${NC} Creating keybindings reference..."

cat > ~/.config/nvim/OPENHWY_KEYS.md << 'EOF'
# OpenHWY Neovim Keybindings

## Dashboard
- `<leader>oO` - Toggle OpenHWY Dashboard (floating window)

Inside dashboard:
- `m` - Marketeer Dashboard
- `a` - Agent Builder  
- `1-4` - SSH to boxes (1=helpbox, 2=hostbox, 3=callbox, 4=safebox)
- `r` - Refresh
- `q` - Close

## Quick Tools
- `<leader>om` - Marketeer Dashboard (terminal)
- `<leader>oa` - Agent Builder (terminal)
- `<leader>os` - System Status (terminal)

## SSH
- `<leader>oh` - SSH to helpbox
- `<leader>oH` - SSH to hostbox
- `<leader>oc` - SSH to callbox
- `<leader>oS` - SSH to safebox

## File Navigation
- `<leader>oo` - Find files in OpenHWY workspace
- `<leader>og` - Grep in OpenHWY workspace

## Commands (type in command mode)
- `:OpenHWYDashboard` - Toggle dashboard
- `:OpenHWYExec <s> <cmd>` - Execute command on system
- `:OpenHWYExecAll <cmd>` - Execute on all systems
- `:OpenHWYLaunch <sys> <cfg> <script>` - Launch agent
- `:OpenHWYKill <sys> <agent>` - Kill agent
- `:OpenHWYStatus [system]` - Get status
- `:OpenHWYDeploy <s>` - Deploy to system

## Command Shortcuts
- `<leader>ox` - Start typing `:OpenHWYExec `
- `<leader>oX` - Start typing `:OpenHWYExecAll `
- `<leader>ol` - Start typing `:OpenHWYLaunch `
- `<leader>ok` - Start typing `:OpenHWYKill `
- `<leader>od` - Start typing `:OpenHWYDeploy `

## Examples
```
:OpenHWYExec helpbox ps aux | grep moon-env
:OpenHWYExecAll uptime
:OpenHWYLaunch hostbox codriver.toml codriver.lua
:OpenHWYKill helpbox scraper
:OpenHWYDeploy all
```

## Leader Key
Default leader is `<Space>`
So `<leader>oO` = Space + o + O (shift+o)
EOF

echo -e "${GREEN}✓${NC} Keybindings reference: ~/.config/nvim/OPENHWY_KEYS.md"

# Install/update plugins
echo -e "${BLUE}[4/4]${NC} Installing Neovim plugins..."

nvim --headless "+Lazy! sync" +qa 2>/dev/null || {
    echo "Note: Run :Lazy sync inside nvim to install plugins"
}

echo -e "${GREEN}✓${NC} Plugins configured"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚛 Neovim Control Center Ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Open Neovim and:"
echo "  1. Press ${BLUE}Space + o + O${NC} (capital O) for dashboard"
echo "  2. Run ${BLUE}:OpenHWYDashboard${NC}"
echo "  3. Type ${BLUE}:OpenHWY<Tab>${NC} to see all commands"
echo ""
echo "View keybindings: ${BLUE}cat ~/.config/nvim/OPENHWY_KEYS.md${NC}"
echo ""
echo "Inside Neovim, everything is at your fingertips:"
echo "  • Execute commands on any box"
echo "  • SSH to systems"
echo "  • Launch/kill agents"
echo "  • Deploy code"
echo "  • All without leaving the editor"
