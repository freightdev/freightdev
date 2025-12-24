1. What Tailscale actually is
Layer	What it does	Notes
Control plane	SaaS API that brokers keys & coordination	You can self-host it with Headscale if you outgrow SaaS.
GitHub
Data plane	Each device runs tailscaled (a WireGuard engine)	Peers talk P2P; falls back to DERP relays if NAT can’t punch through.
Tailnet	Your private overlay network	Think of it as a secure LAN that follows you everywhere.
Tailscale
2. Install & bootstrap on Alpine (what you just did)

# become root
su

# add stable + community repos (you’ve done this already)

# install tailscale & enable service
apk add tailscale
rc-update add tailscaled default
rc-service tailscaled start

# authenticate this node
tailscale up         # opens a URL; approve it from Lenovo

After approval:

tailscale ip         # shows this host’s 100.x.x.x address
tailscale status     # list of every peer in your tailnet

3. Daily commands you’ll actually use
Task	Command
Show peers	tailscale status
Get this node’s IP(s)	tailscale ip -4 / -6
Rename device	tailscale set --hostname trainr-asus
Funnel HTTP port 8000 publicly	tailscale funnel 8000
Tailscale
Serve an internal service only to tailnet	tailscale serve https /srv/web
Route LAN 192.168.1.0/24 via this box	tailscale up --advertise-routes=192.168.1.0/24
Tailscale
Make this an exit node	tailscale up --advertise-exit-node
Tailscale
Headless / CI join	tailscale up --authkey=<preauth-key>
Tailscale
4. DNS & names (MagicDNS)

    Enable in admin console → DNS ► MagicDNS.

    Every device auto-gets a FQDN like trainr-asus.ts.net and a short name trainr-asus.
    Tailscale

    Split-DNS rules live under DNS ► Nameservers.
    Tailscale

5. Access-control policy (ACL) file

Edit in the admin console Access controls → JSON like:

{
  "ACLs": [
    { "Action": "accept", "Users": ["jesse@github","uncle@github"],
      "Ports": ["trainr-asus:22","lenovo:22","*:443","*:8000"] }
  ],
  "TagOwners": {
    "tag:server": ["jesse@github"]
  },
  "Hosts": {
    "lenovo": "100.101.102.103"
  }
}

Example templates:
Tailscale

Save → changes propagate instantly.
6. Scaling beyond a handful of devices
Need	Feature	Docs
100 + devices / multiple users	Paid plan or self-host Headscale
GitHub
Public HTTP(s) endpoints	Funnel (TLS, LetsEncrypt)
Tailscale
Site-to-site LAN access	Subnet router (--advertise-routes)
Tailscale
Full-tunnel VPN	Exit node
Tailscale
CI / IaC joins	Auth keys (ephemeral, reusable)
Tailscale
7. Where configs live on Alpine
Path	Purpose
/var/lib/tailscale/	Machine keys & state (keep this backed up).
/etc/tailscale.d/	Drop-in override files (*.conf, optional).
/etc/apk/repositories	We added @main, @community, @testing, @edge-*.
8. Hardening & automation tips

    Firewall not needed inside tailnet; external ports can remain closed.

    Create an auth key with --reusable=true --ephemeral=true for scripted autoprovision of future nodes.

    Use tagged nodes (--advertise-tags=tag:server) so ACLs remain role-based.

    Rotate machine keys with tailscale up --reset when recycling hardware.

    Monitor with Prometheus metrics on https://localhost:9090/debug/metrics (enable in tailscaled).

9. When you outgrow SaaS

    Headscale = open-source control-server replacement.
    Install it on a VPS or your Lenovo, point all nodes at it via --login-server.
    GitHub

🎯 90-second “first-run” checklist

# Already done: apk update && apk add tailscale

rc-update add tailscaled default
rc-service tailscaled start
tailscale up --ssh            # auth from Lenovo browser

ssh root@trainr-asus          # done, secure, works anywhere

You now have:

    trainr-asus reachable over Tailscale from Lenovo, phone, cloud VMs, etc.

    ACLs, DNS, subnet routes, exit nodes, and Funnel ready whenever you turn them on.

