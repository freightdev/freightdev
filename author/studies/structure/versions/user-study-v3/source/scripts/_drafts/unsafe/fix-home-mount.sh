#!/bin/bash
set -e

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Finding processes using /home..."
pids=$(sudo fuser -vm /home 2>/dev/null | awk 'NR>1 {print $2}')

if [ -z "$pids" ]; then
  echo "No processes using /home found."
else
  echo "Killing processes: $pids"
  for pid in $pids; do
    sudo kill -9 "$pid"
  done
fi

echo "Unmounting /home..."
sudo umount /home

echo "Mounting all from fstab..."
sudo mount -a

echo "Checking mounts for /home:"
mount | grep /home || echo "/home is not mounted"
