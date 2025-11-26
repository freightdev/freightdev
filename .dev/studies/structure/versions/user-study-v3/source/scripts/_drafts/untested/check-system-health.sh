#!/bin/bash

echo "=== SYSTEM HEALTH CHECK ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo

echo "=== Disk Usage (Top 15 by size) ==="
sudo du -xh / | sort -rh | head -15
echo

echo "=== Disk Free Space ==="
df -hT
echo

echo "=== Memory Usage ==="
free -h
echo

echo "=== Running Processes (Top 15 by memory) ==="
ps aux --sort=-%mem | head -15
echo

echo "=== Users with Login Shells ==="
awk -F: '/\/bin\/bash|\/bin\/sh|\/bin\/zsh|\/bin\/fish/ {print $1}' /etc/passwd
echo

echo "=== Last Logins ==="
lastlog | head -15
echo

echo "=== Open Network Connections ==="
ss -tunap | head -20
echo

echo "=== Listening Ports ==="
ss -tuln
echo

echo "=== Sudo Usage Log (last 15 entries) ==="
sudo journalctl _COMM=sudo -n 15 --no-pager
echo

echo "=== Failed SSH Login Attempts ==="
sudo journalctl -u sshd --since "1 day ago" | grep "Failed password" | tail -15
echo

echo "=== Kernel Messages with Priority ERR or Higher ==="
sudo journalctl -p err..emerg -b --no-pager
echo

echo "=== Scheduled Cron Jobs for All Users ==="
for user in $(cut -f1 -d: /etc/passwd); do
    echo "Cron jobs for user: $user"
    sudo crontab -l -u $user 2>/dev/null || echo "  None or no access"
done
echo

echo "=== Installed Packages (Top 20 by size) ==="
if command -v pacman >/dev/null 2>&1; then
    pacman -Qi | awk '/^Name/{name=$3}/^Installed Size/{print name, $4 $5}' | sort -k2 -rh | head -20
elif command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -rh | head -20
else
    echo "Package manager not recognized."
fi
echo

echo "=== Check for Suspicious SetUID Binaries ==="
find / -perm -4000 -type f -exec ls -ld {} \; 2>/dev/null
echo

echo "=== Check for World-Writable Files (excluding /proc, /sys) ==="
find / -path /proc -prune -o -path /sys -prune -o -type f -perm -0002 -ls 2>/dev/null
echo

echo "=== Check for Large Log Files (>100MB) ==="
find /var/log -type f -size +100M -exec ls -lh {} \;
echo

echo "=== End of System Health Check ==="
