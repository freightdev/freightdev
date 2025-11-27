# 🔨 McBypass Mode: Arch Linux Public Wi-Fi Proxy + Tor Bypass Setup

> This guide documents how to bypass restrictive or hijacked Wi-Fi networks (like McDonald's) that block HTTPS/TLS traffic or hijack DNS, using `cloudflared`, `Tor`, and `proxychains`.

---

## ✅ Goal

Enable AUR package installations and full HTTPS functionality (e.g., GitHub, yay, curl) when behind a captive portal or DNS-hijacking network, **without authenticating** to the Wi-Fi or using their DNS.

---

## ⚖️ Prerequisites

* Arch Linux or compatible distro
* A working terminal
* `yay` or other AUR helper
* `cloudflared`, `proxychains`, `tor`, `dig`, and `torsocks` installed

```bash
sudo pacman -S cloudflared proxychains-ng tor bind
```

---

## ⚙️ Step-by-Step Setup

### 1. Start DNS-over-HTTPS locally with Cloudflare

```bash
cloudflared proxy-dns --port 5053
```

This launches a DNS-over-HTTPS resolver on `127.0.0.1:5053` using Cloudflare.

---

### 2. Set system DNS to localhost DoH resolver

```bash
sudo resolvectl dns wlan0 127.0.0.1
sudo resolvectl domain wlan0 '~.'
```

> Replace `wlan0` with your active network interface (`ip a` or `nmcli device status` to check).

---

### 3. Validate DNS is working

```bash
dig @127.0.0.1 github.com
```

Should return real IPs (not hijacked).

---

## 👅 Route traffic through Tor (Optional but powerful)

### 4. Enable Tor system daemon

```bash
sudo systemctl enable --now tor
```

---

### 5. Configure `/etc/proxychains.conf`

Set to strict Tor SOCKS proxy:

```ini
strict_chain
proxy_dns
remote_dns_subnet 224

[ProxyList]
socks4 127.0.0.1 9050
```

---

### 6. Run AUR installs through proxy

```bash
proxychains yay -S <aur-package>
```

If that fails, clone manually:

```bash
torsocks git clone https://aur.archlinux.org/vscodium-bin.git
cd vscodium-bin
makepkg -si
```

---

## 🔐 Example Manual Hosts Override (Optional)

You can also hardcode known IPs to bypass DNS hijack for specific domains:

```bash
sudo nano /etc/hosts
```

```hosts
104.20.1.252  nodejs.org
```

---

## 🚀 Success

Once set up:

* `yay`, `git`, `curl`, and all HTTPS traffic works.
* DNS lookups are fully encrypted and DoH-protected.
* Tor optionally routes traffic, hiding origin from public Wi-Fi.

---

## ✨ Notes

* You can use `tailscale`, `warp-cli`, or `sshuttle` as alternatives.
* You can configure `cloudflared` to run as a persistent systemd service if needed.

---

Built for mobility. Tested at McDonald's. No more captive portals.

---
