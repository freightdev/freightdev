#!/bin/bash

TARGET="/home"

echo "Finding processes using $TARGET ..."
mapfile -t pids < <(sudo lsof +D "$TARGET" -t | sort -u)

if [ ${#pids[@]} -eq 0 ]; then
  echo "No processes found using $TARGET."
else
  echo "Processes using $TARGET:"
  for pid in "${pids[@]}"; do
    proc_info=$(ps -p "$pid" -o pid,user,%cpu,%mem,cmd --no-headers)
    echo "$proc_info"
  done

  echo
  for pid in "${pids[@]}"; do
    proc_info=$(ps -p "$pid" -o pid,user,cmd --no-headers)
    read -p "Kill process $proc_info ? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      echo "Killing PID $pid"
      sudo kill -9 "$pid"
    else
      echo "Skipping PID $pid"
    fi
  done
fi

echo
echo "Attempting to unmount $TARGET ..."
if sudo umount "$TARGET"; then
  echo "$TARGET successfully unmounted."
else
  echo "Failed to unmount $TARGET. Trying lazy unmount (-l)..."
  sudo umount -l "$TARGET" && echo "Lazy unmount successful." || echo "Lazy unmount failed."
fi
