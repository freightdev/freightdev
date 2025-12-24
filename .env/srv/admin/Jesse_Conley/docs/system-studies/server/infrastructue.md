# INFRASTRUCTURE: JESSE CONLEY'S COMPLETE SYSTEM ARCHITECTURE

---

## HARDWARE INFRASTRUCTURE

### 🖥️ Production Server (Asus TUF Gaming)
- **CPU**: AMD Ryzen 5 3550H (4 cores / 8 threads, max 2.1 GHz)
- **GPU**: NVIDIA GeForce GTX 1650 Mobile/Max-Q (4GB VRAM, Turing)
- **iGPU**: Radeon Vega Mobile (amdgpu driver)
- **RAM**: 32GB DDR4 with zram compression
- **Storage**: 931GB Crucial P3 (Micron 2550 NVMe, XFS)
  - **Read BW**: 1476 MiB/s  
  - **Write BW**: 1466 MiB/s  
  - **IOPS**: ~2941  
  - **Latency**: R: 6.3 ms / W: 15.4 ms  
  - **Utilization**: 90.80%  
  - **CPU Usage**: ~16.1%  
  - **Queue Depth**: 32 (full)
- **Network**: Wired Cat-6 Ethernet (stable)
- **Config**: Headless Arch Linux (minimal)
- **Role**: AI inference host, production containers, database node

### 💻 Development Machine (Lenovo Yoga 9i)
- **CPU**: Intel Core Ultra 7 155H (Meteor Lake with 22 threads)
- **iGPU/NPU**: Intel Arc Xe-LPG + Intel NPU
- **RAM**: 16GB DDR5 with zram compression
- **Storage**: 1TB Samsung PM9C1a (XFS)
  - **Read BW**: 857 MiB/s  
  - **Write BW**: 855 MiB/s  
  - **IOPS**: ~1712  
  - **Latency**: R: 17.8 ms / W: 19.5 ms  
  - **Utilization**: 92.7%  
  - **Queue Depth**: 32 (full)
- **Network**: WiFi (mobility)
- **Config**: Full Arch Linux + GUI
- **Role**: Development, model testing, remote control

---

## OPERATING SYSTEM & KERNEL

### 🧱 Base System
- **OS**: Arch Linux (rolling, custom mirror)
- **Init**: `systemd`
- **Kernel**: 6.15.9-zen1-1-zen (custom compiled)
- **Package Managers**: `pacman`, `yay` (AUR)

### 🧠 Memory Management
- **ZRAM Tunning**:
```bash
  zram-size = ram * 0.5
  compression-algorithm = zstd
  swap-priority = 100
  fs-type = swap
```
- **Sysctl Tuning**:
```bash
  vm.swappiness = 180
  vm.watermark_boost_factor = 0
  vm.watermark_scale_factor = 125
  vm.page-cluster = 0
```

### 📂 XFS Configuration

```bash
Mount options:
  noatime, largeio, inode64, allocsize=16m
```

Partition layout:

```
# Asus
/dev/nvme0n1p1 → /boot (1G, vfat)
/dev/nvme0n1p2 → /      (30G, xfs)
/dev/nvme0n1p3 → /var   (500G, xfs)
/dev/nvme0n1p4 → /srv   (400G, xfs)

# Lenovo
/dev/nvme0n1p1 → /boot  (1G, vfat)
/dev/nvme0n1p2 → /      (50G, xfs)
/dev/nvme0n1p3 → /var   (150G, xfs)
/dev/nvme0n1p4 → /srv   (150G, xfs)
/dev/nvme0n1p5 → /opt   (100G, xfs)
/dev/nvme0n1p6 → /home  (502G, xfs)
```

---

## CONTAINER INFRASTRUCTURE

### 🐳 Runtime & Orchestration

* **Runtime**: Podman (rootless, daemonless)
* **Orchestration**: `podman-compose`
* **Registry**: Harbor (private + vulnerability scanning)
* **Networking**: CNI, custom bridges

### 📦 Compose File Structure

```bash
├── core-infra.yml      # PostgreSQL, Redis, MinIO
├── auth.yml            # Keycloak, OAuth2-Proxy, Teleport
├── proxy.yml           # Traefik, HAProxy, Cloudflared
├── monitoring.yml      # Prometheus, Grafana, Loki, Jaeger
├── security.yml        # Wazuh, Falco, ClamAV
├── communication.yml   # Asterisk, Jitsi, Matrix
├── dev.yml             # Gitea, Woodpecker CI, Harbor
└── master-compose.yml  # Aggregated stack
```

---

## NETWORKING & SECURITY

### 🌐 Network Stack

* **Ingress**: Cloudflared (Zero Trust Tunnels)
* **Private Mesh**: WireGuard (Asus ↔ Lenovo)
* **Firewall**: nftables (default deny)
* **DNS**: PowerDNS (Authoritative + Recursor)
* **Proxy**: Traefik (auto discovery, TLS)
* **Load Balancer**: HAProxy

### 🛡️ Security Stack

* **WAF**: ModSecurity (OWASP Core Ruleset)
* **SIEM**: Wazuh (central manager + agents)
* **Container Runtime**: Falco
* **Vuln Scanning**: Trivy (CI/CD integrated)
* **Access**: Teleport (SSH, infra sessions)
* **Rate Limiting**: Fail2ban (via Traefik logs)

---

## DATABASE & STORAGE

### 🗄️ Data Stack

* **Database**: PostgreSQL 15 w/ streaming replication
* **Cache**: Redis Cluster (3-node)
* **Object Storage**: MinIO (S3-compatible, distributed)
* **Backups**:

  * Restic (incremental)
  * WAL-E (PostgreSQL)
  * XFS snapshots
  * rsync (flat backups)

### 🧮 Storage Optimizations

* **Filesystem**: XFS (largeio, allocsize=16m)
* **I/O Scheduler**: Deadline
* **Dir Structure**: `/var` for DBs, `/srv` for apps, `/opt` for extras

---

## MONITORING & OBSERVABILITY

### 📈 Metrics & Logs

* **Metrics**: Prometheus + AlertManager
* **Visualization**: Grafana
* **Logging**: Loki + Promtail
* **Tracing**: Jaeger
* **Uptime Checks**: Uptime Kuma
* **Real-Time Tools**: `htop`, `iotop`, `nethogs`, `nmap`

---

## AI / ML INFRASTRUCTURE

### 🧠 Inference Stack

* **LLM Runtime**: llama.cpp + Rust FFI wrapper
* **GPU**: CUDA 12.6 (GTX 1650)
* **NPU/CPU**: OpenVINO (Intel Arc, Yoga 9i)
* **Model Storage**: `~/Workspace/ai/models/`
* **Environment**: Conda + PyTorch + Transformers + Triton

### 🗂️ Workspace Layout

```
~/Workspace/ai/
├── models/         # Llama models, ONNX exports
├── memory/         # AI memory: personal, sessions, knowledge
├── chats/          # Past conversations
├── context/        # Context windows
├── training/       # Fine-tuning data
└── logs/           # System logs
```

---

## DEVELOPMENT ENVIRONMENT

### 🛠️ Tools & Workflow

* **IDE**: VSCodium + Remote-SSH
* **Languages**: Rust, TypeScript, Python, Bash
* **Versioning**: Gitea (self-hosted Git)
* **CI/CD**: Woodpecker CI
* **Pkg Mgrs**: `cargo`, `conda`, `npm`

### 📦 Custom Components

* **Frontend**: 400+ atomic TypeScript components
* **Framework**: `Bookmark` (Next.js alternative)
* **APIs**: Rust + FFI bindings
* **System Architecture**: MARK / BOOK / BET / BEAT (AI OS)

---

## BUSINESS APPLICATIONS

### 🚛 Trucking Stack

#### 1. [FedDispatching.com](https://feddispatching.com) (For-Profit)

* **Agent**: FED (Fleet Eco Director)
* **Purpose**: Dispatcher Training + Platform
* **Funding**: Tools + Courses
* **Profits**: Infra scaling + payroll

#### 2. [Open-HWY.com](https://open-hwy.com) (Nonprofit)

* **Agent**: HWY (Highway Watch Yard)
* **Purpose**: Highway safety + "Trucker Tales"
* **Funding**: SDKs + Rust APIs
* **Profits**: Infra + highway repairs + education

#### 3. [8TeenWheelers.com](https://8teenwheelers.com) (Free Community)

* **Agent**: ELDA (Ethical Logistics Driver Assistant)
* **Purpose**: Driver-led logistics community
* **Funding**: Powered by Open-HWY

---

## DEPLOYMENT & AUTOMATION

### ⚙️ Infra-as-Code

* **Provisioning**: Terraform
* **Configuration**: Ansible
* **Deployment**: podman-compose
* **Backups**: Restic + XFS snapshots

### 🔧 System Optimization

* **CPU**: Performance governor
* **Thermals**: `thermald`
* **Power**: `powertop`
* **Memory**: Custom `sysctl` tuning

---

## CONNECTIVITY & REMOTE ACCESS

### 🌍 Access & Sync

* **Remote Dev**: VSCodium (SSH to Asus)
* **Terminal**: SSH (key-based)
* **File Sync**: SSHFS
* **Tunnel**: WireGuard mesh

---

## BUILDER OF INFRASTRUCTURE

### 👤 Jesse Edward Eugene Wayne Conley

* 📬 [jesse.freightdev@gmail.com](mailto:jesse.freightdev@gmail.com)  
* 🔗 [github.com/freightdev](https://github.com/freightdev)  
* 🤗 [huggingface.co/freightdev](https://huggingface.co/freightdev)  
* 🔌 [x.com/freightdevjesse](https://x.com/freightdevjesse)  
* 💏 [linkedin.com/in/freightdevjesse](https://linkedin.com/in/freightdevjesse) 

---

> **"I don’t build to automate the road. I build so no one gets left behind."**