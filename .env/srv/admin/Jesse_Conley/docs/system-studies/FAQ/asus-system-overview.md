# 🧠 SYSTEM OVERVIEW (ASUS: `trainr-asus`)

| Component               | Value                               |
| ----------------------- | ----------------------------------- |
| **Model**               | TUF Gaming FX505DT                  |
| **BIOS Version**        | FX505DT.316 (Jan 2021)              |
| **CPU**                 | AMD Ryzen 5 3550H (4C/8T, Zen+)     |
| **GPU (dGPU)**          | NVIDIA GTX 1650 Mobile (4GB VRAM)   |
| **iGPU**                | AMD Radeon Vega 8                   |
| **RAM**                 | 32GB (29 GiB usable)                |
| **Swap (ZRAM)**         | 14.7 GiB with zstd compression      |
| **Kernel**              | 6.15.2-arch1-1 (rolling Arch)       |
| **Storage**             | 1TB NVMe SSD (Crucial CT1000P3SSD8) |
| **Storage Layout**      |                                     |
| • `/boot`    → 1GB      |                                     |
| • `/`        → 50GB     |                                     |
| • `/var`     → 100GB    |                                     |
| • `/home`    → 200GB    |                                     |
| • `/data`    → 580GB    |                                     |
| **ZRAM active?**        | ✅ Yes (swap in `/dev/zram0`)        |
| **PowerMgmt override?** | ❌ No lid behavior set yet           |
| **Tailscale?**          | ❌ Not running                       |
| **Docker?**             | ✅ Present (but unused)              |

---

## 🔧 HARDWARE READINESS

### ✅ CPU:

* ✅ SMT enabled (8 threads)
* ✅ Boost enabled
* ✅ AMD-V virtualization supported (for KVM, VMs, nested)
* ❗ Max frequency locked at **2.1GHz** — can be unlocked via CPU governor tuning later

### ✅ GPU:

* NVIDIA GTX 1650 Mobile (Turing)
* 4GB VRAM
* Fully detected via `nvidia-smi`
* Kernel modules: `nvidia_drm`, `nvidia_modeset`, `nvidia_uvm`
* **CUDA 12.9** ready for training
* Performance state: **P8 (idle)** — ready to scale up

### ✅ RAM:

* 32GB recognized
* ZRAM compression active on 14.7 GiB
* No issues; but `dmidecode` not installed so exact slot speed/timings not shown

### ✅ Disk:

* 1TB Crucial NVMe
* Partitioned and mounted cleanly
* **No I/O speed test** ran (because `/usr/bin/time` was missing)

---

## 🔥 NEXT STEPS

### ✅ 1. Install missing dependencies (for next-level analysis if needed)

```bash
sudo pacman -S dmidecode lsusb time hdparm --noconfirm
```

---

### ✅ 2. BIOS RECOMMENDATIONS:

* Reboot and **disable Secure Boot, Fast Boot, Quiet Boot**
* Enable **SVM (virtualization)** if not already
* Set boot mode to **UEFI only**

Let me know if you want to write a BIOS checklist to match your server strategy.

---

## 🛠️ DECISION POINT: WIPE + INSTALL

You're confirmed ready. Now pick:

| Option             | OS Base             | Pros                                | Ideal For                    |
| ------------------ | ------------------- | ----------------------------------- | ---------------------------- |
| **Alpine**         | `alpine-standard`   | ⚡ Ultra fast, no bloat, hardened    | Pure Docker host, agents, AI |
| **Debian Netinst** | `debian-12-netinst` | ✅ Stable, predictable               | General-purpose, systemd     |
| **Arch Reinstall** | (current)           | ⚠ Too unstable for long-run servers | Dev environments only        |

> 💬 **Your call:** Alpine is lean, perfect for headless server.
> Debian is stable, easier for package control.

---

### 🧰 Once chosen, I’ll give you:

* Flash steps (Ventoy or dd)
* Partition wipe command
* Install walk-through
* Post-install bootstrap for:

  * `tailscale`
  * `docker`
  * `gpu training`
  * `zram + cpu governor tuning`
  * `/srv` orchestration layout
  * remote-only access from Lenovo
