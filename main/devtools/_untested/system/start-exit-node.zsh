#!/usr/bin/env zsh
# start-exit-node.zsh
# Forces ASUS to act as a Tailscale exit node using wlan0 as outbound

OUT_IF="wlan0"

print ">>> Using outbound interface: $OUT_IF"

# 1. Enable IPv4/IPv6 forwarding immediately
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# 2. Make it permanent in sysctl.conf
if ! grep -q "net.ipv4.ip_forward" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
fi
if ! grep -q "net.ipv6.conf.all.forwarding" /etc/sysctl.conf; then
    echo "net.ipv6.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
fi

# 3. Configure NAT for wlan0
sudo iptables -t nat -A POSTROUTING -o "$OUT_IF" -j MASQUERADE
sudo iptables -A FORWARD -i tailscale0 -j ACCEPT
sudo iptables -A FORWARD -o tailscale0 -j ACCEPT

# 4. Save iptables rules
if command -v netfilter-persistent >/dev/null 2>&1; then
    sudo netfilter-persistent save
elif command -v iptables-save >/dev/null 2>&1; then
    sudo sh -c "iptables-save > /etc/iptables/rules.v4"
fi

# 5. Advertise exit node on Tailscale
sudo tailscale up --advertise-exit-node --accept-dns=false --exit-node-allow-lan-access

print "✅ ASUS is now a working Tailscale Exit Node over $OUT_IF"
