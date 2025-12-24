# Lenovo Yoga 9i Development Machine - System Reference

## CPU CONFIGURATION

### Optimal Settings (Intel Core Ultra 7 155H - 22 threads)
```
Governor: powersave (laptop optimized)
Turbo boost: enabled
P-cores: 6 (performance cores)
E-cores: 8 (efficiency cores) 
Hyper-threading: enabled
Base frequency: 1.4GHz
Max boost: 4.8GHz
```

### Test Commands
```bash
# Check CPU topology
lscpu | grep -E "(Architecture|CPU\(s\)|Thread|Core|Socket)"

# Check current frequencies per core
grep "cpu MHz" /proc/cpuinfo

# Check Intel P-state driver
cat /sys/devices/system/cpu/intel_pstate/status

# Check turbo boost status
cat /sys/devices/system/cpu/intel_pstate/no_turbo

# Monitor per-core utilization
htop -t  # tree view shows threads
```

### Expected Output
```
CPU(s): 22
Thread(s) per core: 2 (for P-cores), 1 (for E-cores)  
Core(s) per socket: 14
P-cores running 1.4-4.8GHz
E-cores running 1.0-3.4GHz
intel_pstate: active
no_turbo: 0 (turbo enabled)
```

## MEMORY CONFIGURATION

### Optimal Settings (16GB DDR5)
```
Total RAM: 16GB
zram size: 4GB (25% of RAM)
zram algorithm: zstd
vm.swappiness: 5 (lower for development workstation)
vm.vfs_cache_pressure: 50
vm.dirty_ratio: 10
vm.dirty_background_ratio: 3
```

### Test Commands
```bash
# Check memory speed and type
sudo dmidecode -t memory | grep -E "(Speed|Type:|Size)"

# Check memory usage breakdown
free -h && cat /proc/meminfo | head -20

# Check zram efficiency
cat /sys/block/zram0/mm_stat

# Check memory pressure indicators
cat /proc/pressure/memory
```

### Expected Output
```bash
# Memory should show:
              total        used        free      shared  buff/cache   available
Mem:           15Gi        6.0Gi       7.0Gi       1.0Gi        2.0Gi        8.0Gi
Swap:          4.0Gi       0.0Gi       4.0Gi

# DDR5 speed should be ~4800MHz
# zram compression ratio should be > 3:1
```

## STORAGE CONFIGURATION

### Optimal XFS Mount Options (1TB Samsung PM9C1a)
```
noatime,largeio,inode64,allocsize=16m,logbsize=256k,discard
```

### Test Commands
```bash
# Check NVMe info
sudo nvme list
sudo nvme id-ctrl /dev/nvme0n1

# Check mount options
mount | grep nvme0n1

# Test NVMe performance
sudo fio --name=test --ioengine=libaio --rw=randread --bs=4k --numjobs=4 --size=2G --runtime=30 --filename=/tmp/test
sudo fio --name=test --ioengine=libaio --rw=randwrite --bs=4k --numjobs=4 --size=2G --runtime=30 --filename=/tmp/test
```

### Expected Output
```bash
# NVMe should show PCIe 4.0 x4
# Random read: >300k IOPS
# Random write: >250k IOPS
# Discard support should be enabled
```

## DISTRIBUTED COMPUTING SETUP

### WireGuard Kernel Distribution Network
```
Lenovo IP: 10.0.0.2/24
ASUS IP: 10.0.0.1/24
Network: wg0 interface
```

### Setup Commands
```bash
# Generate WireGuard keys
wg genkey | tee privatekey | wg pubkey > publickey

# Create WireGuard config
sudo tee /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = $(cat privatekey)
ListenPort = 51820

[Peer]
PublicKey = ASUS_PUBLIC_KEY_HERE
Endpoint = ASUS_IP:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25
EOF

# Enable WireGuard
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

### Test Connectivity
```bash
# Test WireGuard connection
ping -c 4 10.0.0.1

# Test bandwidth between systems
iperf3 -s  # on ASUS
iperf3 -c 10.0.0.1 -t 30  # on Lenovo

# Check WireGuard status
sudo wg show
```

## DISTRIBUTED COMPUTE ORCHESTRATION

### SSH Kernel Access Setup
```bash
# Configure passwordless SSH
ssh-keygen -t ed25519 -f ~/.ssh/asus_key
ssh-copy-id -i ~/.ssh/asus_key.pub user@10.0.0.1

# Create SSH config
tee ~/.ssh/config << EOF
Host asus
    HostName 10.0.0.1
    User your_username
    IdentityFile ~/.ssh/asus_key
    Port 22
    Compression yes
    ServerAliveInterval 60
EOF
```

### Distributed Processing Commands
```bash
# Execute command on ASUS from Lenovo
ssh asus 'nproc && free -h'

# Distribute CPU-intensive task
# On Lenovo (22 threads)
stress-ng --cpu 20 --timeout 60s &

# Simultaneously on ASUS (8 threads)  
ssh asus 'stress-ng --cpu 8 --timeout 60s' &

# Monitor both systems
ssh asus 'htop' &
htop
```

### Distributed Compilation
```bash
# Setup distcc for distributed compilation
sudo pacman -S distcc

# Configure distcc hosts
export DISTCC_HOSTS="localhost/22 10.0.0.1/8"

# Use distributed make
make -j30 CC="distcc gcc"  # 22 local + 8 remote threads
```

## SSHFS FILESYSTEM SHARING

### Mount ASUS filesystems on Lenovo
```bash
# Create mount points
mkdir -p ~/mounts/{asus-var,asus-srv,asus-home}

# Mount ASUS directories
sshfs asus:/var ~/mounts/asus-var -o allow_other,default_permissions
sshfs asus:/srv ~/mounts/asus-srv -o allow_other,default_permissions  
sshfs asus:/home/username ~/mounts/asus-home -o allow_other,default_permissions

# Add to fstab for persistence
echo "asus:/var /home/username/mounts/asus-var fuse.sshfs defaults,allow_other,IdentityFile=/home/username/.ssh/asus_key 0 0" | sudo tee -a /etc/fstab
```

### Test Shared Storage
```bash
# Test file operations across systems
echo "test" > ~/mounts/asus-var/test.txt
ssh asus 'cat /var/test.txt'

# Check mount status
mount | grep sshfs
df -h | grep asus
```

## CONTAINER ORCHESTRATION DISTRIBUTION

### Podman Remote Setup
```bash
# Enable Podman API on ASUS
ssh asus 'systemctl --user enable podman.socket'
ssh asus 'systemctl --user start podman.socket'

# Configure remote connection from Lenovo
podman system connection add asus ssh://username@10.0.0.1/run/user/1000/podman/podman.sock

# Test remote container management
podman --remote --connection asus ps
podman --remote --connection asus run -d nginx
```

### Distributed Container Deployment
```bash
# Deploy containers across both systems
# High-memory containers on ASUS (32GB)
podman --remote --connection asus run -d --name postgres-prod -m 8g postgres

# Development containers on Lenovo (16GB)  
podman run -d --name dev-env -m 2g node:alpine

# Check distributed deployment
podman ps  # local containers
podman --remote --connection asus ps  # remote containers
```

## DATABASE DISTRIBUTION

### PostgreSQL Master-Slave Setup
```bash
# Master on ASUS (production)
# Slave on Lenovo (development/backup)

# Configure replication on ASUS master
ssh asus "sudo -u postgres psql -c \"CREATE ROLE replica REPLICATION LOGIN PASSWORD 'replica_password';\""

# Setup replication on Lenovo
sudo systemctl stop postgresql
sudo rm -rf /var/lib/postgres/data/*
sudo -u postgres pg_basebackup -h 10.0.0.1 -D /var/lib/postgres/data -U replica -v -P -W

# Configure recovery on Lenovo
sudo -u postgres tee /var/lib/postgres/data/standby.signal << EOF
# This file enables standby mode
EOF
```

### Test Database Replication
```bash
# Test replication lag
ssh asus "sudo -u postgres psql -c \"SELECT pg_current_wal_lsn();\""
sudo -u postgres psql -c "SELECT pg_last_wal_receive_lsn();"

# Test read operations on slave
sudo -u postgres psql -c "SELECT COUNT(*) FROM your_table;"
```

## DEVELOPMENT ENVIRONMENT OPTIMIZATION

### IDE Configuration for Distributed Development
```bash
# VSCodium remote development
code --install-extension ms-vscode-remote.remote-ssh

# Configure remote development settings
mkdir -p ~/.config/Code/User
tee ~/.config/Code/User/settings.json << EOF
{
    "remote.SSH.defaultExtensions": [
        "rust-lang.rust-analyzer",
        "ms-python.python"
    ],
    "remote.SSH.connectTimeout": 60,
    "remote.SSH.keepAlive": true
}
EOF
```

### Git Distributed Workflow
```bash
# Configure Git for both systems
git config --global user.name "Jesse Conley"
git config --global user.email "jesse.freightdev@gmail.com"

# Setup Git remote on ASUS
ssh asus 'git config --global receive.denyCurrentBranch updateInstead'

# Push/pull between systems
git remote add asus ssh://asus/path/to/repo.git
git push asus main
git pull asus main
```

## AI/ML DISTRIBUTED PROCESSING

### Intel Arc + CUDA Distribution
```bash
# Check Intel Arc capabilities on Lenovo
clinfo | grep -A5 "Device Name"
vainfo  # Intel video acceleration

# Setup OpenVINO on Lenovo
source /opt/intel/openvino_2023/setupvars.sh

# CUDA on ASUS, OpenVINO on Lenovo
# Run different model formats on each system
ssh asus 'python inference_cuda.py --model llama.ggml'  # CUDA
python inference_openvino.py --model llama.xml          # OpenVINO
```

### Model Distribution Strategy
```bash
# Large models on ASUS (4GB VRAM + 32GB RAM)
ssh asus 'python -c "
import torch
model = torch.load(\"large_model.pt\", map_location=\"cuda:0\")
"'

# Smaller models on Lenovo (Intel Arc + 16GB RAM)
python -c "
import torch
model = torch.load('small_model.pt', map_location='cpu')
"
```

## POWER MANAGEMENT

### Laptop-Optimized Settings
```
CPU governor: powersave with turbo
Display: auto-brightness enabled
Wireless: power saving enabled
USB: auto-suspend enabled
```

### Test Commands
```bash
# Check power consumption
sudo powertop --auto-tune
upower -i /org/freedesktop/UPower/devices/BAT0

# Monitor CPU frequency scaling
watch -n 1 'grep "cpu MHz" /proc/cpuinfo'

# Check thermal throttling
dmesg | grep -i thermal
cat /sys/class/thermal/thermal_zone*/temp
```

### Expected Output
```
Battery: >6 hours under normal development load
CPU temp: <80°C under sustained load
Thermal throttling: Should not occur during normal use
```

## NETWORK OPTIMIZATION

### WiFi 6E Configuration
```bash
# Check WiFi capabilities
iwconfig
iw list | grep -A10 "Frequencies"

# Optimize WiFi settings
sudo iw dev wlan0 set power_save off  # for performance
sudo ethtool -s wlan0 speed 1000 duplex full
```

### Network Performance Testing
```bash
# Test WiFi speed
speedtest-cli

# Test internal network (via WireGuard)
iperf3 -c 10.0.0.1 -t 60 -i 5

# Monitor network usage
nethogs
bandwhich
```

## MONITORING COMMANDS

### Dual-System Monitoring
```bash
# Create monitoring script for both systems
tee ~/monitor-both.sh << 'EOF'
#!/bin/bash
echo "=== LENOVO STATUS ==="
echo "CPU: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage "%"}')"
echo "RAM: $(free -m | awk 'NR==2{printf "%.1f%% (%s/%s MB)", $3*100/$2, $3, $2}')"
echo "Temp: $(sensors | grep 'Core 0' | awk '{print $3}')"

echo -e "\n=== ASUS STATUS ==="
ssh asus 'echo "CPU: $(grep '\''cpu '\'' /proc/stat | awk '\''{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage "%"}'\'')"'
ssh asus 'echo "RAM: $(free -m | awk '\''NR==2{printf "%.1f%% (%s/%s MB)", $3*100/$2, $3, $2}'\'')"'
ssh asus 'echo "GPU: $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)°C"'

echo -e "\n=== DISTRIBUTED LOAD ==="
echo "Total Threads: 30 (22 Lenovo + 8 ASUS)"
echo "WireGuard: $(ping -c 1 10.0.0.1 >/dev/null 2>&1 && echo "UP" || echo "DOWN")"
EOF
chmod +x ~/monitor-both.sh
```

### Performance Baseline Tests
```bash
# Distributed CPU test
~/monitor-both.sh
stress-ng --cpu 20 --timeout 30s &  # Lenovo
ssh asus 'stress-ng --cpu 8 --timeout 30s' &  # ASUS
wait
~/monitor-both.sh

# Network throughput test
iperf3 -s &  # Start server on Lenovo
ssh asus 'iperf3 -c 10.0.0.2 -t 30'  # Client on ASUS
```

## TROUBLESHOOTING

### Connection Issues
```bash
# Debug WireGuard
sudo wg show
sudo journalctl -u wg-quick@wg0

# Debug SSH connection
ssh -vvv asus

# Test network connectivity
traceroute 10.0.0.1
mtr 10.0.0.1
```

### Performance Issues
```bash
# Check for thermal throttling
dmesg | grep -i "cpu.*throttl"

# Check for memory pressure
dmesg | grep -i "killed.*memory"

# Check distributed load balance
htop  # on Lenovo
ssh asus 'htop'  # on ASUS
```

## CONFIGURATION FILES

### WireGuard
```
/etc/wireguard/wg0.conf
```

### SSH
```
~/.ssh/config
~/.ssh/asus_key
```

### Development
```
~/.config/Code/User/settings.json
~/.gitconfig
```

### System Optimization
```
/etc/sysctl.d/99-lenovo-optimization.conf
```