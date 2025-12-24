### 🚀 Decision and Reasoning

You should use **Alpine Linux** (bare-metal, hardened), paired with **Podman** (daemon-less, rootless containers by default).

**Why Alpine + Podman**:

* ✅ **Alpine**:

  * Smallest possible attack surface (around 100MB).
  * Security-focused: musl-libc, hardened kernel defaults.
  * Perfect for headless, long-running AI workloads, APIs, hosting, and training.

* ✅ **Podman**:

  * Completely **rootless** and **daemonless** by default.
  * Containers run as non-root users with zero escalation.
  * No Docker daemon vulnerability issues.

* ❌ Docker:

  * Runs a root daemon by default (`dockerd`), requires careful hardening.
  * More suited for development, less for hardened production.

---

### 🛠️ Step-by-step Action Plan (Crystal Clear):

### 1️⃣ **Get your USB ready (wipe & re-flash Alpine)**

**Download** (on Lenovo):

* Alpine Linux ISO (Standard):
  [https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86\_64/alpine-standard-latest-x86\_64.iso](https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-standard-latest-x86_64.iso)

**Flash** to USB (Lenovo terminal):

```bash
sudo wipefs -a /dev/sdX
sudo dd if=alpine-standard-latest-x86_64.iso of=/dev/sdX bs=4M status=progress && sync
```

> Replace `/dev/sdX` with your USB device name (`lsblk` to verify).

---

### 2️⃣ **Fully Wipe ASUS (Bare-Metal reset)**

Boot ASUS from USB (hit F2/F9/ESC on boot):

Then run these commands from Alpine live USB environment:

```bash
# verify the disk name again to be safe
lsblk

# zero out disk (replace nvme0n1 with correct disk!)
wipefs -a /dev/nvme0n1
sgdisk --zap-all /dev/nvme0n1
```

---

### 3️⃣ **Alpine Minimal Install (Headless)**

Still from Alpine USB live environment:

```bash
setup-alpine
```

* Keyboard/Locale → default (US)
* Hostname → `trainr-asus`
* Network → `eth0` for wired or set up `wlan0` wifi
* Password → secure root password (you’ll use this for initial setup only)
* SSH server → **yes**
* Disk install → Choose `sys` (full disk install, simple and secure), select `/dev/nvme0n1`

Once finished:

```bash
poweroff
```

Remove USB. Now ASUS is Alpine, minimal, secure, and ready.

---

### 4️⃣ **ASUS Post-Install Bootstrap (From Lenovo)**

Boot ASUS fresh (Ethernet connected recommended):

SSH into ASUS from Lenovo terminal:

```bash
ssh root@<ASUS-IP-address>
```

### Hardened Base Setup (copy/paste):

```bash
# update package index
apk update && apk upgrade

# Add essential packages
apk add bash sudo shadow podman tailscale nano

# Create your secure user (replace jesse with your username)
adduser jesse
adduser jesse wheel
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel

# Disable root SSH login immediately
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
rc-service sshd restart
```

Log out (`exit`) and SSH back in as your new user:

```bash
ssh jesse@<ASUS-IP-address>
```

---

### 5️⃣ **Tailscale Setup (Remote secure access)**

Run as your user:

```bash
sudo rc-update add tailscaled
sudo rc-service tailscaled start
sudo tailscale up --ssh --accept-routes --advertise-exit-node
```

Now connect from Lenovo via Tailscale:

```bash
ssh jesse@trainr-asus  # via tailscale magic dns
```

---

### 6️⃣ **Persistent Infra Setup (`/srv` structure)**

```bash
sudo mkdir -p /srv/{users,containers,ops,runtime,tmp,logs}
sudo chown -R jesse:jesse /srv
```

---

### 7️⃣ **Podman: No-Daemon Containerization (Fully Rootless)**

Initialize as your user (`jesse`):

```bash
podman info
```

Create example container (no root, no daemon):

```bash
podman run -dt --name test-container alpine sleep infinity
podman ps
```

Verify no root-daemon runs containers.

---

### 8️⃣ **System Optimization (ZRAM & CPU Governor)**

**ZRAM (in-memory compressed swap)**:

```bash
sudo apk add zram-init
sudo rc-update add zram-init default
sudo rc-service zram-init start
```

Verify ZRAM:

```bash
zramctl
```

**CPU Governor: Max Performance Tuning**:

```bash
sudo apk add cpufreqd
sudo rc-update add cpufreqd
echo 'GOVERNOR="performance"' | sudo tee /etc/conf.d/cpufreqd
sudo rc-service cpufreqd start
```

Check governor:

```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

---

### 9️⃣ **Prevent Suspend on Lid Close (Always-On server mode)**

Edit logind config:

```bash
sudo nano /etc/elogind/logind.conf
```

Set:

```
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
HandleSuspendKey=ignore
HandlePowerKey=ignore
```

Restart elogind:

```bash
sudo rc-service elogind restart
```

---

### 🔟 **Full BIOS Recommendations (Manual Reboot & Adjust BIOS)**

On manual reboot (once done above):

* **Disable Secure Boot**
* **Enable AMD-V virtualization (SVM)**
* **Set Boot mode → UEFI Only**
* **Disable Fast Boot**
* **Disable Quiet Boot**
* **Ensure BIOS firmware up-to-date** (yours is 2021, fine)

---

## ✅ **Final state (exactly what you need):**

* **Alpine Linux** (ultra minimal, hardened)
* **Podman** (daemonless rootless containers)
* **Tailscale remote access** from Lenovo securely
* **Persistent infra** `/srv` structure
* **Always-on, lid-closed server**
* **ZRAM optimized** (max RAM perf)
* **CPU governor → performance** (full compute available)
* **GPU NVIDIA + CUDA ready** (drivers can be added later easily)

This gives you a fully ready, headless, secure AI/hosting/training node managed from Lenovo.

---

### 🔥 **CONFIRMATION**:

Your next move:

1. **Download & flash Alpine to USB**
2. **Perform above steps exactly**
3. **After Alpine is booted, run provided scripts above**
