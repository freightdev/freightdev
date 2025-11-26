# zBox Interactive CLI Guide

## Overview

The `zbox` command provides a complete interactive CLI for managing your entire infrastructure, users, VMs, and monitoring.

## Quick Start

```bash
# Initialize zBox (first time)
zbox init

# Interactive creation wizard
zbox create -i

# Check system status
zbox status
```

---

## Commands

### User Management

#### Create User (Interactive)
```bash
zbox user create
```

Prompts for:
- Username
- Full name
- Email
- Phone (optional)
- Password
- Automatically generates SSH and GPG keys

#### Login
```bash
zbox user login <username>
```

Creates a session and loads the user's default profile.

#### List Users
```bash
zbox user list
```

---

### Profile Management

#### List Profiles
```bash
zbox profile list
```

#### Switch Profile
```bash
zbox profile switch admin
```

#### Show Current Profile
```bash
zbox profile info
```

---

### Virtual Machine Management

#### Create VM (Interactive)
```bash
zbox vm create -i
```

Or from manifest:
```bash
zbox vm create ~/.zbox/vms/my-vm/manifest.yaml
```

#### List VMs
```bash
zbox vm list
```

#### Control VMs
```bash
zbox vm start my-vm
zbox vm stop my-vm
zbox vm delete my-vm
```

---

### Node Management

#### List Nodes
```bash
zbox node list
```

Shows all available infrastructure nodes with:
- Type (physical, vm, container, cloud)
- Host/IP
- Status (online/offline, SSH accessible)

#### Add Node (Interactive)
```bash
zbox node add
```

Prompts for:
- Node name
- Type
- Hostname/IP
- SSH credentials
- Auto-detects resources (CPU, RAM, disk)

#### Check Node Status
```bash
zbox node status hostbox
```

Shows detailed info:
- Connectivity (ping, SSH)
- Resources (CPU count, memory, disk)
- Load average
- Capabilities (KVM, Docker, etc.)

---

### Resource Monitoring

#### Start Monitor
```bash
zbox monitor start
```

Starts background monitoring of:
- CPU usage
- Memory usage
- Function calls
- Profile sessions

#### Check Status
```bash
zbox monitor status
```

Shows:
- Current CPU/memory/disk usage
- Zsh process count
- Function call statistics
- Top called functions
- Recent activity log

#### Monitor Profiles
```bash
zbox monitor profiles
```

Lists all active profile sessions with PIDs, start times, TTY.

---

### Interactive Creation Wizard

The most powerful feature! Interactive mode guides you through creating any resource:

```bash
zbox create -i
```

Menu options:
1. **User** - Create new zBox user with SSH/GPG keys
2. **Profile** - Create environment profile
3. **VM** - Create virtual machine
4. **Node** - Add infrastructure node
5. **Agent** - Create AI agent environment

Each option walks you through the configuration step by step.

---

## Workflow Examples

### Example 1: First-Time Setup

```bash
# 1. Initialize zBox
zbox init

# Creates first admin user interactively
# Username: admin
# Password: ****
# Generates SSH/GPG keys

# 2. Check status
zbox status

# 3. Add infrastructure nodes
zbox node add
# Node: hostbox
# Host: 192.168.1.100
# Auto-detects: 8 CPUs, 16GB RAM

# 4. Create a VM
zbox create -i
# Select: 3 (VM)
# Follow prompts...
```

### Example 2: Multi-User Environment

```bash
# Admin creates users
zbox user create
# Username: alice
# Email: alice@example.com
# Generates keys for alice

zbox user create
# Username: bob
# ...

# Users login
zbox user login alice
# Loads alice's default profile
# alice can now create VMs, manage resources
```

### Example 3: Monitor Everything

```bash
# Start resource monitoring
zbox monitor start

# In another terminal, watch profiles
pwatch  # Real-time profile monitor

# Check overall status
zbox monitor status
```

---

## User System

### How It Works

1. **User Creation**:
   - Stores user in `~/.zbox/.secret/users/<username>.yaml`
   - Generates SSH key pair (ed25519)
   - Generates GPG key (4096-bit RSA)
   - Password is hashed with SHA-256

2. **Login**:
   - Verifies password hash
   - Creates session ID
   - Loads user's default profile
   - Exports `$ZBOX_USER` and `$ZBOX_USER_EMAIL`

3. **Permissions**:
   - Each user has `admin` flag
   - Users can be restricted to specific profiles/nodes
   - Full permission system in YAML

### User File Format

```yaml
user:
  username: "alice"
  fullname: "Alice Johnson"
  email: "alice@example.com"
  phone: "+1234567890"
  created: "2025-11-22 21:00:00"

auth:
  password_hash: "abc123..."
  ssh_public_key: "ssh-ed25519 AAAA..."
  ssh_private_key_path: "/home/admin/.zbox/.secret/keys/alice_ssh"
  gpg_key_id: "1234ABCD"

permissions:
  admin: false
  profiles: ["workspace", "development"]
  nodes: ["hostbox"]

settings:
  default_profile: "workspace"
  shell: "/bin/zsh"
```

---

## Node System

### How It Works

1. **Node Discovery**:
   - Reads YAML files from `~/.zbox/.secret/nodes/`
   - Each file defines one infrastructure node

2. **Resource Detection**:
   - Auto-detects via SSH:
     - CPU cores (nproc)
     - Memory (free -m)
     - Disk space (df)
     - Capabilities (virsh, docker, etc.)

3. **Status Checking**:
   - Ping test for connectivity
   - SSH test for accessibility
   - Real-time resource queries

### Node File Format

```yaml
node:
  name: "hostbox"
  type: "physical"  # physical, vm, container, cloud

connection:
  host: "192.168.1.100"
  port: 22
  user: "admin"

resources:
  cpu_cores: 8
  memory_mb: 16384
  disk_gb: 500

capabilities:
  kvm: true
  docker: true
  firecracker: false
  nomad: true
```

---

## Resource Monitoring

### Tracked Metrics

- **CPU**: Overall system CPU usage
- **Memory**: Used/total memory percentage
- **Disk**: Root filesystem usage
- **Processes**: Count of zsh processes
- **Function Calls**: Tracks every zBox function called

### Monitor Log

Location: `~/.zbox/.ai/logs/monitoring/resource.log`

Format:
```
2025-11-22 21:00:00 | CPU: 15.2% | MEM: 45.3% | ZSH: 5 | CALLS: 142
```

### Function Call Tracking

Every zBox function call is tracked:
```bash
$ zbox monitor status

Top Functions:
  zbox_vm_list: 15
  zbox_node_status: 8
  zbox_monitor_status: 5
```

---

## Environment Variables

### Set by zBox CLI

- `$ZBOX_USER` - Currently logged-in user
- `$ZBOX_USER_EMAIL` - User's email
- `$ZBOX_SESSION_ID` - Current session ID
- `$ZBOX_CURRENT_PROFILE` - Active profile

### Control Variables

- `$ZBOX_DEBUG` - Enable debug output
- `$ZBOX_FORCE_RELOAD` - Force reload environment

---

## Integration with Existing zBox

The `zbox` CLI integrates with all existing zBox functions:

```bash
# These all work after zbox init:
pmon                   # Profile monitor
vmlist                 # List VMs
zbox_check_infrastructure  # Check infrastructure
trash file.txt         # Trash system
```

---

## Security

### SSH Keys

- Generated for each user
- Stored in `~/.zbox/.secret/keys/`
- Ed25519 algorithm (modern, secure)

### GPG Keys

- 4096-bit RSA keys
- Used for encryption/signing
- Associated with user's email

### Passwords

- SHA-256 hashed
- Stored in user YAML files
- Never stored in plaintext

### Secrets Directory

`~/.zbox/.secret/` contains:
- User credentials
- SSH/GPG keys
- Node passwords (if used)

**Never commit this directory to git!**

---

## Troubleshooting

### "zbox: command not found"

Reload your shell:
```bash
ZBOX_FORCE_RELOAD=1 zsh
```

Or manually add to PATH:
```bash
export PATH="$HOME/.zbox/bin:$PATH"
```

### User creation fails

Check:
- SSH installed: `which ssh-keygen`
- GPG installed: `which gpg`

### Node not accessible

Check:
- Node is reachable: `ping <host>`
- SSH key is set up: `ssh user@host`
- Firewall allows SSH port

### Monitor not starting

Check:
- Logs directory exists: `mkdir -p ~/.zbox/.ai/logs/monitoring`
- Previous monitor stopped: `zbox monitor stop`

---

## Next Steps

1. **Initialize**: `zbox init`
2. **Add nodes**: `zbox node add`
3. **Create VMs**: `zbox create -i`
4. **Monitor**: `zbox monitor start`
5. **Build your infrastructure!**

---

This is YOUR infrastructure platform. Terraform + Ansible + Kubernetes, but YOUR way!

Built by Jesse E.E.W. Conley 🚚💻☕
