# 🧨 TFULL WIPE AND SETUP

## ✅ You Need:

* Tailscale working
* SSH control from Lenovo
* Persistent `/srv` structure for user & container data
* Docker, GPU, and training stack ready
* Reliable reboot, power, and thermal settings
* System that **never turns off**, **even with lid closed**

---

# ⚙️ PHASE 0: PICK THE RIGHT BASE OS

## ✅ Use: **Alpine Linux (recommended)** or **Debian Minimal (fallback)**

Why Alpine?

* \~100MB install
* Boots in seconds
* Hardened by default
* Docker-native, musl-libc minimalism
* Perfect for headless GPU servers

Why not Arch?

* Too rolling
* Too bleeding-edge for 24/7 host
* Random regressions (like brightness or sleep bugs)

---

# 🔥 PHASE 1: WIPE + INSTALL MINIMAL LINUX

## 💽 Use Ventoy or Etcher to flash:

### ISO: [Alpine Standard x86\_64](https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/)

Or:

### ISO: [Debian 12 Netinst Minimal](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/)

---

## 🧼 Clean Disk (Do this on the ASUS via live USB)

```bash
# Wipe EVERYTHING (be careful)
sudo wipefs -a /dev/nvme0n1
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 /dev/nvme0n1p1
```

Mount it:

```bash
mount /dev/nvme0n1p1 /mnt
```

---

## ⛓️ Install Alpine (real minimal)

From Alpine live shell:

```bash
setup-alpine
```

Answer like:

* No GUI
* UTC timezone
* `eth0` or `wlan0` network config (skip Wi-Fi if using Tailscale later)
* OpenSSH enabled
* Disk: `/dev/nvme0n1`

Once done:

```bash
reboot
```

You now boot into **pure Alpine** with **no GUI**, no fluff, no bloat.

---

# 🧱 PHASE 2: SERVER BOOTSTRAP (NO GUI, PERMANENT HOSTING)

From your Lenovo:

```bash
ssh root@asus.local  # or via Tailscale IP
```

## 🔧 Setup your packages:

```bash
apk update
apk add docker bash sudo shadow tailscale nano
rc-update add docker default
rc-service docker start
```

## ✅ Setup your system user:

```bash
adduser jesse
adduser jesse wheel
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
```

---

# 🛠️ PHASE 3: HARDEN & PREP HOSTING SYSTEM

### 🔧 Docker auto-launch:

```bash
rc-update add docker default
```

### 🔧 Tailscale enable:

```bash
rc-update add tailscaled default
rc-service tailscaled start
tailscale up --ssh --advertise-exit-node --accept-routes
```

Now connect from Lenovo:

```bash
ssh jesse@<asus-tailscale-name>
```

---

### 🔒 Disable screen blanking, shutdown, and lid close

Edit `/etc/acpi/LID` or use:

```bash
nano /etc/logind.conf
```

Set:

```
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
HandleSuspendKey=ignore
HandlePowerKey=ignore
```

Then:

```bash
rc-service elogind restart
```

---

# 🧩 PHASE 4: INFRASTRUCTURE LAYOUT

### Create base structure:

```bash
mkdir -p /srv/{users,docker,ops,runtime}
chown -R jesse:jesse /srv
```

### (Optional) Shared `dev` folder between Lenovo ↔ ASUS:

```bash
ln -s /srv/users/jesse/dev /home/jesse/dev
```

---

## ✅ PHASE 5: FINAL SETUP DONE CHECKLIST

| Feature                   | Status                                    |
| ------------------------- | ----------------------------------------- |
| GUI removed               | ✅ (Alpine = no GUI by default)            |
| Headless remote access    | ✅ via Tailscale                           |
| Docker enabled            | ✅ ready for training/agents               |
| Persistent folders        | ✅ `/srv` for all user/container data      |
| Lid close doesn't suspend | ✅ `logind.conf` adjusted                  |
| User management ready     | ✅ (`adduser`, `rm -rf /srv/users/<user>`) |
| Safe from reboots         | ✅ Tailscale reconnects on boot            |

---

# ✅ NEXT STEP: Confirm OS Selection

Do you want to go:

* ✅ **Alpine**: ultra-minimal, fast, hardened
* 🟡 **Debian Minimal**: stable, friendly
* ❌ **Arch**: not recommended for 24/7 headless AI server

