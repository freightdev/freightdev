#!/bin/bash
# Setup Data Collectors for Trucking Industry and Housing Search
# This script installs and configures automated data collection

set -e

echo "🚀 Setting up AI Data Collectors"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Python dependencies
echo "📦 Checking Python dependencies..."
python3 -m pip install --user feedparser pyyaml requests beautifulsoup4 lxml 2>/dev/null || {
    echo "⚠️  Installing Python dependencies..."
    python3 -m pip install --user feedparser pyyaml requests beautifulsoup4 lxml
}
echo -e "${GREEN}✅ Python dependencies OK${NC}"
echo ""

# Create data directories
echo "📁 Creating data directories..."
mkdir -p /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/data/{trucking,housing,logs}
mkdir -p /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/data/trucking/{$(date +%Y-%m-%d)}
mkdir -p /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/data/housing/{$(date +%Y-%m-%d)}
echo -e "${GREEN}✅ Directories created${NC}"
echo ""

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/scripts/data-collector-orchestrator.py
echo -e "${GREEN}✅ Scripts configured${NC}"
echo ""

# Install systemd services
echo "⚙️  Installing systemd services..."
mkdir -p ~/.config/systemd/user

# Copy service files
cp /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/systemd/trucking-collector.service ~/.config/systemd/user/
cp /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/systemd/trucking-collector.timer ~/.config/systemd/user/
cp /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/systemd/housing-collector.service ~/.config/systemd/user/
cp /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/systemd/housing-collector.timer ~/.config/systemd/user/

# Reload systemd
systemctl --user daemon-reload

echo -e "${GREEN}✅ Systemd services installed${NC}"
echo ""

# Enable services (but don't start yet)
echo "🔄 Enabling data collection timers..."
systemctl --user enable trucking-collector.timer
systemctl --user enable housing-collector.timer
echo -e "${GREEN}✅ Timers enabled${NC}"
echo ""

# Test run (optional)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Would you like to run a test collection now? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🧪 Running test collection for trucking industry..."
    python3 /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/scripts/data-collector-orchestrator.py \
        /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/core/ai-agents/data-collector/configs/trucking-sources.yaml || true
    echo ""
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Data Collectors Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "📋 Next Steps:"
echo ""
echo "1. Configure your location in housing config:"
echo "   nano /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/core/ai-agents/data-collector/configs/housing-sources.yaml"
echo ""
echo "2. Start the collection timers:"
echo "   systemctl --user start trucking-collector.timer"
echo "   systemctl --user start housing-collector.timer"
echo ""
echo "3. Check timer status:"
echo "   systemctl --user list-timers"
echo ""
echo "4. Run manual collection:"
echo "   python3 /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/scripts/data-collector-orchestrator.py \\"
echo "     /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/core/ai-agents/data-collector/configs/trucking-sources.yaml"
echo ""
echo "5. View collected data:"
echo "   ls -lh ~/.ai/data/trucking/"
echo "   ls -lh ~/.ai/data/housing/"
echo ""
echo "6. View logs:"
echo "   tail -f ~/.ai/data/logs/trucking-collector.log"
echo "   tail -f ~/.ai/data/logs/housing-collector.log"
echo ""
echo "📊 Collection Schedule:"
echo "   • Trucking: Daily at 8:00 AM"
echo "   • Housing: Twice daily at 9:00 AM and 6:00 PM"
echo ""
echo "💾 Data Storage:"
echo "   • Markdown: ~/.ai/data/{trucking,housing}/"
echo "   • Database: SurrealDB on helpbox:9000"
echo ""
