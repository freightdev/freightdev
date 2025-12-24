sudo cat > /etc/apt/sources.list.d/pve-install-repo.sources << EOL
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOL

sudo wget https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg -O /usr/share/keyrings/proxmox-archive-keyring.gpg

sudo sha256sum /usr/share/keyrings/proxmox-archive-keyring.gpg

sudo apt update
sudo apt full-upgrade -y
sudo apt install -y proxmox-default-kernel

# sudo reboot

# After reboot, install Proxmox VE
# sudo apt install -y proxmox-ve postfix open-iscsi chrony

# Remove old Debian kernel (optional but recommended)
# sudo apt remove linux-image-amd64 'linux-image-6.12*' -y
# sudo update-grub

# Remove os-prober (recommended for VMs)
# sudo apt remove os-prober -y
