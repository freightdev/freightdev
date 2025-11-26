# zBox Infrastructure Guide

## Overview

zBox now supports full infrastructure orchestration with:
- **KVM/libvirt** - Full virtual machines
- **Firecracker** - Ultra-fast microVMs
- **Docker** - Container management
- **Nomad** - Orchestration across all resources
- **Profile Sessions** - Track and manage running profiles with PIDs

This is **Terraform + Ansible but YOUR way** - pure manifest-driven infrastructure with zsh + Rust.

---

## Installation

### Quick Install (All Components)

```bash
# Run the installer
zsh ~/.zbox/tools/system/install-infrastructure.zsh
```

This installs:
✅ KVM + libvirt
✅ Firecracker microVMs
✅ Docker
✅ Nomad
✅ ZFS (optional)

**Important**: Log out and back in after installation for group permissions!

### Manual Installation

See individual component installation below.

---

## Admin Profile

### Load Admin Profile

```bash
# Switch to admin profile (full access, everything loaded)
ZBOX_PROFILE=admin zsh

# Or switch while in shell
zbox_switch_profile admin
```

### What Admin Profile Loads

✅ **ALL configs** from `config/defaults/` and `config/settings/`
✅ **ALL functions** from `source/agents/`, `source/helpers/`, `source/suites/`
✅ **ALL tools** from `tools/*/`
✅ **Full system access** - No restrictions
✅ **Profile monitoring** - Track all running profiles
✅ **VM management** - Create, start, stop VMs
✅ **Infrastructure control** - KVM, Firecracker, Docker, Nomad

---

## Profile Session Management

### Track Running Profiles

```bash
# Monitor all active profile sessions
zbox_monitor_profiles
pmon  # alias

# Watch in real-time
zbox_watch_profiles
pwatch  # alias
```

Output:
```
📦 Profile: workspace
   PID:     12345
   Started: 2025-11-22 14:30:00
   TTY:     /dev/pts/1
   Status:  ✅ Running

📦 Profile: admin
   PID:     12346
   Started: 2025-11-22 14:31:00
   TTY:     /dev/pts/2
   Status:  ✅ Running
```

### Control Profiles

```bash
# Get PID of a profile
zbox_profile_pid workspace
ppid workspace  # alias

# Kill a profile gracefully
zbox_kill_profile workspace
pkill workspace  # alias

# Force kill a profile
zbox_kill_profile workspace true

# Kill all profiles
zbox_kill_all_profiles

# Send custom signal
zbox_profile_signal workspace TERM
```

### How It Works

Each profile session is tracked with:
- **PID** - Process ID of the shell
- **Session ID** - Unique timestamp-based ID
- **Metadata** - Start time, user, TTY, manifest
- **Session file** - Stored in `~/.zbox/.ai/logs/profile-sessions/`

Sessions persist across shell reloads and can be monitored/controlled independently.

---

## VM Management

### VM Manifest Schema

See `~/.zbox/profiles/manifest.vm.yaml` for complete schema.

Example VM manifest:

```yaml
vm:
  name: "agent-vm-01"
  type: "microvm"

hypervisor:
  provider: "firecracker"  # or kvm, qemu

resources:
  vcpus: 2
  memory: "512M"

  disks:
    - name: "root"
      size: "10G"
      filesystem: "ext4"  # ext4, lvm2, zfs, btrfs, xfs

network:
  interfaces:
    - name: "eth0"
      ip: "192.168.100.10/24"

  hostname: "agent-vm-01"

zbox:
  mount_zbox: true
  profile: "agent-sandbox"
```

### Create VM

```bash
# Create VM from manifest
zbox_vm_create ~/.zbox/vms/my-vm/manifest.yaml
vmcreate ~/.zbox/vms/my-vm/manifest.yaml  # alias
```

### List VMs

```bash
zbox_vm_list
vmlist  # alias
```

### Control VMs

```bash
# Start VM
zbox_vm_start my-vm
vmstart my-vm  # alias

# Stop VM
zbox_vm_stop my-vm
vmstop my-vm  # alias

# Destroy VM
zbox_vm_destroy my-vm
vmkill my-vm  # alias

# Force destroy
zbox_vm_destroy my-vm true
```

### Filesystem Options

Supported filesystems for VM disks:
- **ext4** - Standard Linux filesystem (recommended for most)
- **lvm2** - Logical Volume Manager (snapshots, resizing)
- **zfs** - Advanced features (compression, deduplication, snapshots)
- **btrfs** - Modern filesystem (snapshots, subvolumes)
- **xfs** - High-performance filesystem

Example in manifest:
```yaml
disks:
  - name: "root"
    size: "20G"
    filesystem: "zfs"  # Uses ZFS!
    mount: "/"
```

---

## Firecracker MicroVMs

Ultra-fast, lightweight VMs with minimal overhead.

### Features
- **Boot time**: <150ms
- **Memory**: Minimal overhead (~5MB)
- **Use case**: Agent sandboxes, ephemeral workloads

### Create Firecracker VM

```yaml
hypervisor:
  provider: "firecracker"

  firecracker:
    kernel: "/opt/firecracker/kernels/vmlinux"
    rootfs: "/var/lib/zbox/vms/my-vm/rootfs.ext4"
    socket: "/run/firecracker-my-vm.socket"
```

### Start Firecracker VM

```bash
zbox_vm_start my-microvm
```

---

## Nomad Orchestration

Orchestrate VMs and containers across your infrastructure.

### Check Nomad Status

```bash
# Check if Nomad is running
nomad status

# zBox-specific check
zbox_check_infrastructure
```

### Deploy Profile to Nomad

```bash
# Deploy all VMs in current profile
zbox_nomad_deploy_profile

# Deploy specific profile
zbox_nomad_deploy_profile admin
ndeploy admin  # alias
```

### Manage Nomad Jobs

```bash
# List zBox-managed jobs
zbox_nomad_list
njobs  # alias

# Run job
zbox_nomad_run ~/.zbox/nomad/jobs/my-vm.nomad
nrun ~/.zbox/nomad/jobs/my-vm.nomad  # alias

# Stop job
zbox_nomad_stop my-vm
nstop my-vm  # alias
```

### Nomad Job Creation

zBox automatically creates Nomad jobs from VM manifests:

```bash
# Create Nomad job from VM manifest
zbox_nomad_create_vm_job ~/.zbox/vms/my-vm/manifest.yaml

# Output: ~/.zbox/nomad/jobs/my-vm.nomad
# Then run: nomad job run ~/.zbox/nomad/jobs/my-vm.nomad
```

---

## Complete Workflow Example

### 1. Install Infrastructure

```bash
# Install everything
zsh ~/.zbox/tools/system/install-infrastructure.zsh

# Log out and back in
exit
```

### 2. Load Admin Profile

```bash
# Start admin profile
ZBOX_PROFILE=admin zsh

# Verify everything
zbox_check_infrastructure
```

Output:
```
✅ libvirt installed
✅ libvirt accessible
✅ Firecracker installed
✅ Docker installed
✅ Docker accessible
✅ Nomad installed
✅ Nomad accessible
```

### 3. Create VM

```bash
# Create VM manifest
cat > ~/.zbox/vms/agent-01/manifest.yaml <<EOF
vm:
  name: "agent-01"
  type: "microvm"

hypervisor:
  provider: "firecracker"

resources:
  vcpus: 2
  memory: "512M"
  disks:
    - name: "root"
      size: "5G"
      filesystem: "ext4"
EOF

# Create the VM
vmcreate ~/.zbox/vms/agent-01/manifest.yaml
```

### 4. Start VM

```bash
vmstart agent-01
```

### 5. Monitor Everything

```bash
# Watch profiles
pwatch

# List VMs
vmlist

# List Nomad jobs
njobs
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     zBox Admin Profile                      │
│              (Full Infrastructure Control)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐ ┌────────▼───────┐ ┌────────▼─────────┐
│ Profile Monitor│ │  VM Management │ │ Nomad Orchestr. │
│  (PID tracking)│ │ (KVM/Firecracker)│ (Job scheduling)│
└───────┬────────┘ └────────┬───────┘ └────────┬─────────┘
        │                   │                   │
┌───────▼──────────────────────────────────────▼─────────┐
│              Infrastructure Layer                       │
│  • KVM/libvirt  • Firecracker  • Docker  • Nomad      │
└─────────────────────────────────────────────────────────┘
```

---

## Files Reference

### Admin Profile
- `~/.zbox/profiles/admin/manifest.yaml` - Admin profile manifest

### Infrastructure Functions
- `~/.zbox/source/helpers/profile-monitor.zsh` - Profile session tracking
- `~/.zbox/source/helpers/vm-manager.zsh` - VM management
- `~/.zbox/source/helpers/nomad-integration.zsh` - Nomad orchestration

### Schemas
- `~/.zbox/profiles/manifest.vm.yaml` - VM manifest schema template

### Tools
- `~/.zbox/tools/system/install-infrastructure.zsh` - Infrastructure installer

### Runtime Directories
- `/var/lib/zbox/` - VM images and rootfs
- `~/.zbox/vms/` - VM manifests and configs
- `~/.zbox/nomad/jobs/` - Generated Nomad jobs
- `~/.zbox/.ai/logs/profile-sessions/` - Profile session tracking
- `~/.zbox/.ai/logs/profile-pids/` - Profile PID files

---

## Next Steps

1. **Install infrastructure**: Run the installer
2. **Load admin profile**: `ZBOX_PROFILE=admin zsh`
3. **Create your first VM**: Use the VM manifest schema
4. **Set up Nomad**: Deploy VMs across your infrastructure
5. **Build agent sandboxes**: Isolated environments for each agent
6. **Orchestrate everything**: Full control over your infrastructure

---

## Roadmap

### Phase 1: Foundation ✅
- [x] Profile session tracking
- [x] Admin profile with full access
- [x] VM manifest schema
- [x] Basic VM management
- [x] Firecracker integration
- [x] Nomad integration

### Phase 2: Advanced Features (In Progress)
- [ ] Automatic VM provisioning from base images
- [ ] VM templates and cloning
- [ ] Network isolation and routing
- [ ] Snapshot management
- [ ] Live migration
- [ ] Multi-node Nomad clusters

### Phase 3: Rust TUI
- [ ] `zboxxy` binary for infrastructure management
- [ ] Real-time monitoring dashboard
- [ ] Multi-pane TUI (VMs, containers, profiles, logs)
- [ ] Interactive VM creation wizard

### Phase 4: Full Automation
- [ ] GitOps integration
- [ ] CI/CD pipelines for infrastructure
- [ ] Auto-scaling based on load
- [ ] Cost optimization
- [ ] Health monitoring and auto-healing

---

**This is Terraform + Ansible + Kubernetes**
**But YOUR way. Your manifests. Your control.**

Built by Jesse E.E.W. Conley 🚚💻☕
