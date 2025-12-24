# Create a directory for our analysis
mkdir -p ~/WORKSPACE/.log/system-audit
cd ~/WORKSPACE/.log/system-audit

# Boot logs and kernel messages
sudo journalctl -b > boot.log
sudo journalctl -b -p err > errors.log
sudo journalctl -b -p warning > warnings.log
sudo dmesg > dmesg.log
sudo dmesg --level=err,warn > dmesg-errors.log

# System information
uname -a > system-info.txt
cat /etc/os-release >> system-info.txt
lscpu >> system-info.txt
free -h >> system-info.txt
df -h >> system-info.txt

# Hardware detection
lspci -vvv > lspci.txt
lsusb -v > lsusb.txt
lsmod > loaded-modules.txt
sudo lshw > hardware-full.txt

# Network status
ip addr > network.txt
ip route >> network.txt
cat /etc/resolv.conf >> network.txt

# Running services
systemctl list-units --type=service --state=running > services-running.txt
systemctl list-units --type=service --state=failed > services-failed.txt
systemctl --failed > systemctl-failed.txt

# Performance metrics
ps aux --sort=-%mem | head -20 > top-memory.txt
ps aux --sort=-%cpu | head -20 > top-cpu.txt

# Disk I/O and mounts
mount > mounts.txt
cat /proc/swaps > swaps.txt
lsblk -f > block-devices.txt

# Check for firmware issues
sudo dmesg | grep -i firmware > firmware-issues.txt
sudo dmesg | grep -i error >> firmware-issues.txt
sudo dmesg | grep -i fail >> firmware-issues.txt

# IIO sensors (for your rotation issue)
ls -la /sys/bus/iio/devices/ > iio-devices.txt
cat /sys/bus/iio/devices/iio:device*/name > iio-names.txt 2>&1

# ACPI info
ls -la /sys/firmware/acpi/tables/ > acpi-tables.txt 2>&1

echo "All logs collected in ~/system-audit/"
ls -lh
