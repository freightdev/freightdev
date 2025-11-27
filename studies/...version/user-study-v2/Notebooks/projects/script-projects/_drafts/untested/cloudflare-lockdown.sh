#!/bin/bash
set -e

# Flush old rules
iptables -F
ip6tables -F

# Default policy: drop everything
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT

# Allow established sessions
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# -------------------------
# Allow Cloudflare IPv4 to Cloudflared tunnel port (7844 by default)
# -------------------------
for ip in \
173.245.48.0/20 \
103.21.244.0/22 \
103.22.200.0/22 \
103.31.4.0/22 \
141.101.64.0/18 \
108.162.192.0/18 \
190.93.240.0/20 \
188.114.96.0/20 \
197.234.240.0/22 \
198.41.128.0/17 \
162.158.0.0/15 \
104.16.0.0/13 \
104.24.0.0/14 \
172.64.0.0/13 \
131.0.72.0/22
do
    iptables -A INPUT -p tcp -s $ip --dport 7844 -j ACCEPT
done

# -------------------------
# Allow Cloudflare IPv6 to Cloudflared tunnel port (7844 by default)
# -------------------------
for ip in \
2400:cb00::/32 \
2606:4700::/32 \
2803:f800::/32 \
2405:b500::/32 \
2405:8100::/32 \
2a06:98c0::/29 \
2c0f:f248::/32
do
    ip6tables -A INPUT -p tcp -s $ip --dport 7844 -j ACCEPT
done

# Drop everything else
iptables -A INPUT -j DROP
ip6tables -A INPUT -j DROP

echo "[+] Cloudflare-only firewall rules applied."
