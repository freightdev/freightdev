#!/bin/bash
# fix-keyboard.sh
# Automatically reset stuck keys and reload keyboard driver

set -euo pipefail

echo "🔧 Fixing keyboard issues..."

# 1. Identify keyboard device (eventX)
KBD_DEV=$(grep -E "Handlers|EV=" /proc/bus/input/devices | \
           grep -B1 "kbd" | grep -Eo "event[0-9]+" | head -n1)

if [[ -z "$KBD_DEV" ]]; then
    echo "❌ No keyboard device found."
    exit 1
fi

DEV_PATH="/dev/input/$KBD_DEV"
echo "✅ Detected keyboard at $DEV_PATH"

# 2. Flush any stuck keys using 'kbd' tools if available
if command -v kbd_mode &>/dev/null; then
    echo "⏳ Resetting keyboard mode..."
    sudo kbd_mode -a
fi

# 3. If 'evtest' is installed, clear stuck events
if command -v evtest &>/dev/null; then
    echo "⏳ Sending key release events..."
    sudo evtest --grab "$DEV_PATH" &
    EV_PID=$!
    sleep 0.5
    kill "$EV_PID" 2>/dev/null || true
fi

# 4. Reload keyboard driver
if lsmod | grep -q "atkbd"; then
    echo "⏳ Reloading atkbd driver..."
    sudo modprobe -r atkbd && sudo modprobe atkbd
else
    echo "ℹ️ atkbd module not found; skipping reload"
fi

echo "🎉 Keyboard fix complete."
