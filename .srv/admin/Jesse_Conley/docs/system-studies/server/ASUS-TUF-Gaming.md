# ASUS TUF Gaming Production Server - System Reference

## CPU CONFIGURATION

### Optimal Settings
```
Governor: performance
Scaling: disabled
Max frequency: 3.7GHz (boost enabled)
Min frequency: 2.1GHz
```

### Test Commands
```bash
# Check current governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check current frequencies
grep "cpu MHz" /proc/cpuinfo

# Check available governors
cpupower frequency-info --governors

# Verify CPU is not throttled
sudo cpupower frequency-info
```

### Expected Output
```
analyzing CPU 0:
  current policy: frequency should be within 2.10 GHz and 3.70 GHz
  current CPU frequency is 3.70 GHz (asserted by call to hardware)
```

## MEMORY CONFIGURATION

### Optimal Settings
```
Total RAM: 32GB
zram size: 8GB (25% of RAM)
zram algorithm: zstd
vm.swappiness: 10
vm.vfs_cache_pressure: 50
vm.dirty_ratio: 15
vm.dirty_background_ratio: 5
```

### Test Commands
```bash
# Check memory usage
free -h

# Check swap configuration
swapon --show

# Check zram status
cat /proc/swaps

# Check sysctl memory settings
sysctl vm.swappiness
sysctl vm.vfs_cache_pressure
sysctl vm.dirty_ratio
```

### Expected Output
```bash
# free -h should show:
              total        used        free      shared  buff/cache   available
Mem:           31Gi        8.0Gi       20Gi       1.0Gi        3.0Gi        22Gi
Swap:          8.0Gi       0.0Gi       8.0Gi

# vm.swappiness should be: 10
# zram should show compression ratio > 2:1
```

## STORAGE CONFIGURATION

### Optimal XFS Mount Options
```
noatime,largeio,inode64,allocsize=16m,logbsize=256k
```

### Test Commands
```bash
# Check current mount options
mount | grep nvme

# Check XFS filesystem info
sudo xfs_info /

# Check I/O scheduler
cat /sys/block/nvme0n1/queue/scheduler

# Test storage performance
sudo fio --name=test --ioengine=libaio --rw=read --bs=4k --numjobs=1 --size=1G --runtime=10 --filename=/tmp/test
```

### Expected Output
```bash
# Mount should show all optimization flags
# I/O scheduler should be: [none] mq-deadline kyber
# FIO read performance should be > 1000 MiB/s
```

## DATABASE SETTINGS

### PostgreSQL Memory Configuration (32GB RAM)
```
shared_buffers = 8GB
effective_cache_size = 24GB
work_mem = 256MB
maintenance_work_mem = 2GB
wal_buffers = 16MB
max_connections = 200
```

### Test Commands
```bash
# Check PostgreSQL memory settings
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW effective_cache_size;"
sudo -u postgres psql -c "SHOW work_mem;"

# Check database performance
sudo -u postgres psql -c "SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers', 'effective_cache_size', 'work_mem');"
```

### Expected Output
```
shared_buffers: 8GB
effective_cache_size: 24GB  
work_mem: 256MB
```

### Redis Configuration
```
maxmemory 4gb
maxmemory-policy allkeys-lru
tcp-keepalive 300
```

### Test Commands
```bash
# Check Redis memory usage
redis-cli INFO memory | grep used_memory_human

# Check Redis configuration
redis-cli CONFIG GET maxmemory
redis-cli CONFIG GET maxmemory-policy
```

### Expected Output
```
maxmemory: 4294967296 (4GB)
maxmemory-policy: allkeys-lru
used_memory should be under 4GB
```

## NETWORK OPTIMIZATION

### Optimal TCP Settings
```
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_congestion_control = bbr
```

### Test Commands
```bash
# Check TCP settings
sysctl net.core.rmem_max
sysctl net.core.wmem_max
sysctl net.ipv4.tcp_congestion_control

# Test network performance
ss -i | grep bbr
```

### Expected Output
```
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_congestion_control = bbr
```

## CONTAINER RESOURCE LIMITS

### Podman Default Limits
```
Memory: 2GB per container
CPU: 1.0 core per container
Storage: 50GB limit
```

### Test Commands
```bash
# Check running containers resource usage
podman stats --no-stream

# Check container storage usage
podman system df

# Check container memory limits
podman inspect <container> | grep -i memory
```

### Expected Output
```bash
# podman stats should show containers under 2GB each
# Total container memory should be under 16GB
```

## AI/ML OPTIMIZATION

### GPU Settings
```
Power limit: 75W (if supported)
Memory clock: 1500MHz
GPU clock: 1750MHz
```

### Test Commands
```bash
# Check GPU status
nvidia-smi

# Check CUDA version
nvcc --version

# Test GPU memory
nvidia-smi --query-gpu=memory.total,memory.used,memory.free --format=csv
```

### Expected Output
```
GPU Memory: 4096 MiB total
Temperature should be under 80°C
Power draw should be under 75W
```

## SYSTEM MONITORING

### Key Metrics to Watch
```
CPU usage: < 70% average
Memory usage: < 24GB (75% of 32GB)
Storage usage: < 85%
Swap usage: < 1GB
Load average: < 8.0 (number of cores)
```

### Monitoring Commands
```bash
# Quick system overview
htop

# Memory breakdown
cat /proc/meminfo

# I/O statistics
iostat -x 1 3

# Process memory usage
ps aux --sort=-%mem | head -10

# Container resource usage
podman stats --no-stream
```

### Performance Baseline Test
```bash
# CPU stress test (30 seconds)
stress-ng --cpu 8 --timeout 30s --metrics

# Memory test
stress-ng --vm 2 --vm-bytes 4G --timeout 30s

# I/O test  
dd if=/dev/zero of=/tmp/test bs=1M count=1000 conv=fdatasync
rm /tmp/test
```

## TROUBLESHOOTING CHECKS

### When Performance Degrades
```bash
# Check for CPU throttling
dmesg | grep -i "cpu.*throttl"

# Check memory pressure
dmesg | grep -i "killed.*memory"

# Check I/O wait
iostat -x 1 5 | grep -E "(Device|nvme)"

# Check container resource exhaustion
podman system events --since="1h ago"
```

### Critical Thresholds
```
CPU throttling: Should not appear in dmesg
Memory available: Should be > 4GB
I/O await: Should be < 20ms
Container restarts: Should be 0 unexpected restarts
```

## CONFIGURATION FILES LOCATIONS

### System Settings
```
/etc/sysctl.d/99-memory-optimization.conf
/etc/sysctl.d/99-network-optimization.conf
/etc/default/cpufrequtils
```

### Database Settings
```
/var/lib/postgres/data/postgresql.conf
/etc/redis/redis.conf
```

### Container Settings
```
/etc/containers/storage.conf
~/.config/containers/containers.conf
```