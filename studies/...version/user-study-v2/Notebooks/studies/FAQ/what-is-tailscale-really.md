🧠 WHAT IS TAILSCALE REALLY?

    Tailscale is a zero-config VPN that builds a secure mesh network between your devices using WireGuard under the hood.

You get:

    hostname.local access between machines (like asus.tail5.ts.net)

    Real static IPs (100.x.x.x) for every device

    Secure firewall traversal — no need to open ports

    Full SSH, file sync, devbox workflows — from anywhere

🔗 CORE CONCEPTS (NO BLOAT)
🔐 1. Authentication

    First time: tailscale up

    Login through GitHub/GitLab/Google (browser-based)

    Associates that machine with your identity/network

🧭 2. Routing

    Every device gets:

        100.x.x.x IP address (internal mesh)

        DNS name (like asus.tail5.ts.net)

    Use these for:

        ssh jesse@asus.tail5.ts.net

        scp, rsync, etc.

📡 3. MagicDNS

    You get *.ts.net domain-based DNS (like asus or trainr-asus)

    Works with ping/SSH directly:

    ping echo-k3
    ssh root@trainr-asus

🔄 4. Device Sharing (ACLs)

    You can share a machine with another Tailscale user (temporary or permanent)

    You can limit access to specific ports using ACLs:

        who can talk to who?

        what ports are open?

Defined in https://login.tailscale.com/admin/acls
🛠️ 5. Tailscale Services

You can enable:

    Exit Nodes → Use one machine as a VPN gateway for others

    Subnet Routers → Access entire subnets behind a Tailscale node

    SSH Relay → Use tailscale ssh with no SSH keys

    Serve (local web) → Serve files/apps to your Tailscale network

✅ CHECKLIST: TAILSCALE SETUP (YOU)

Here’s your bulletproof system setup, start to finish:
🔧 On Every Machine

apk add tailscale
tailscale up

    Log in with the same identity

    Machine joins your personal tailnet

🔍 View Your Network

tailscale status
tailscale ip -4

🔗 Test Connectivity

From one machine:

ping trainr-asus
ssh root@echo-k3

🌐 Enable SSH Proxy (optional but powerful)

tailscale set --ssh

    Then from any machine:

tailscale ssh root@trainr-asus

Works even without open ports or public IPs.
🧪 Enable Local Web Access (Serve mode)

tailscale serve / /home/jesse/shared
# or:
tailscale serve 8080 http://localhost:8080

Then visit: http://asus.tail5.ts.net:8080
🧱 ADVANCED (for scale)

You’re not doing these yet — but you will:

    tailscale serve → expose local APIs or tools

    tailscale funnel → expose to the internet (like ngrok)

    tailscale cert → request internal TLS certs

    tailscaled system service control for persistent boot

    Use Headscale → your own self-hosted controller if you scale big

📁 CONFIG FILE LOCATIONS
Alpine Tailscale Paths:

    Config: /var/lib/tailscale/tailscaled.state

    Auth/Keys: /var/lib/tailscale

    Logs: /var/log/tailscaled.log

    Daemon: rc-service tailscaled start

🔥 YOUR MISSION NOW

You're fully ready to:

    SSH into any of your machines

    Set up aliases for trainr, echo, etc.

    Add tailscale up to boot startup

    Prepare your own full config snapshot (tailscale status > snapshot.mark or similar)
