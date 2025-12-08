#!/bin/bash
# Marketeer Quick Launch
# Run from any of your 5 boxes

echo "🚛 Launching Marketeer Dashboard..."

# Check if we're on one of the systems
HOSTNAME=$(hostname)

case $HOSTNAME in
    workbox|helpbox|hostbox|callbox)
        echo "Running on $HOSTNAME (local)"
        ;;
    *)
        echo "Running on unknown system: $HOSTNAME"
        ;;
esac

# Make sure config exists
if [ ! -f ~/marketeer.toml ]; then
    echo "⚠️  Config not found, copying default..."
    cp marketeer.toml ~/marketeer.toml
fi

# Make stats collector executable
chmod +x ssh_stats.sh

# Launch dashboard
cd marketeer-dashboard
./target/release/marketeer-dashboard ~/marketeer.toml

# Alternative: Run in tmux pane
# tmux split-window -h "./target/release/marketeer-dashboard ~/marketeer.toml"
