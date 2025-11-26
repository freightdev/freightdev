#!/bin/zsh
#############################
# Install zBox Infrastructure
# KVM, libvirt, Firecracker, Nomad, etc.
#############################

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "zBox Infrastructure Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
else
    echo "ERROR: Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

#############################
# Install KVM + libvirt
#############################
install_kvm_libvirt() {
    echo "[1/6] Installing KVM + libvirt..."

    case "$OS" in
        debian|ubuntu)
            sudo apt-get update
            sudo apt-get install -y \
                qemu-kvm \
                libvirt-daemon-system \
                libvirt-clients \
                bridge-utils \
                virt-manager \
                virtinst
            ;;

        fedora|centos|rhel)
            sudo dnf install -y \
                qemu-kvm \
                libvirt \
                virt-install \
                virt-manager \
                bridge-utils
            ;;

        arch|manjaro)
            sudo pacman -S --noconfirm \
                qemu \
                libvirt \
                virt-manager \
                bridge-utils \
                dnsmasq \
                iptables-nft
            ;;
    esac

    # Enable and start libvirt
    sudo systemctl enable libvirtd
    sudo systemctl start libvirtd

    # Add user to libvirt group
    sudo usermod -aG libvirt $USER

    echo "✓ KVM + libvirt installed"
}

#############################
# Install Firecracker
#############################
install_firecracker() {
    echo "[2/6] Installing Firecracker..."

    local fc_version="v1.4.1"
    local arch="x86_64"

    # Download Firecracker
    curl -L https://github.com/firecracker-microvm/firecracker/releases/download/${fc_version}/firecracker-${fc_version}-${arch}.tgz -o /tmp/firecracker.tgz

    # Extract
    sudo mkdir -p /opt/firecracker/bin
    sudo tar -xzf /tmp/firecracker.tgz -C /opt/firecracker/bin
    sudo chmod +x /opt/firecracker/bin/firecracker-*

    # Create symlinks
    sudo ln -sf /opt/firecracker/bin/firecracker-${fc_version}-${arch} /usr/bin/firecracker
    sudo ln -sf /opt/firecracker/bin/jailer-${fc_version}-${arch} /usr/bin/jailer

    # Download kernel
    sudo mkdir -p /opt/firecracker/kernels
    if [[ ! -f /opt/firecracker/kernels/vmlinux ]]; then
        echo "  Downloading kernel..."
        sudo curl -L https://s3.amazonaws.com/spec.ccfc.min/img/quickstart_guide/x86_64/kernels/vmlinux.bin -o /opt/firecracker/kernels/vmlinux
    fi

    rm -f /tmp/firecracker.tgz

    echo "✓ Firecracker installed"
}

#############################
# Install Docker
#############################
install_docker() {
    echo "[3/6] Installing Docker..."

    if command -v docker &>/dev/null; then
        echo "  Docker already installed"
        return 0
    fi

    case "$OS" in
        debian|ubuntu)
            # Add Docker repository
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        fedora)
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        arch|manjaro)
            sudo pacman -S --noconfirm docker docker-compose
            ;;
    esac

    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add user to docker group
    sudo usermod -aG docker $USER

    echo "✓ Docker installed"
}

#############################
# Install Nomad
#############################
install_nomad() {
    echo "[4/6] Installing Nomad..."

    if command -v nomad &>/dev/null; then
        echo "  Nomad already installed"
        return 0
    fi

    local nomad_version="1.7.2"

    # Download Nomad
    curl -L https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip -o /tmp/nomad.zip

    # Extract
    sudo unzip -o /tmp/nomad.zip -d /usr/local/bin/
    sudo chmod +x /usr/local/bin/nomad

    rm -f /tmp/nomad.zip

    # Create Nomad directories
    sudo mkdir -p /etc/nomad.d /opt/nomad/data

    # Create Nomad config
    sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<'EOF'
datacenter = "zbox-dc1"
data_dir   = "/opt/nomad/data"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
}
EOF

    # Create systemd service
    sudo tee /etc/systemd/system/nomad.service > /dev/null <<'EOF'
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nomad
    sudo systemctl start nomad

    echo "✓ Nomad installed"
}

#############################
# Install ZFS (optional)
#############################
install_zfs() {
    echo "[5/6] Installing ZFS (optional)..."

    read -p "Install ZFS? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Skipped"
        return 0
    fi

    case "$OS" in
        debian|ubuntu)
            sudo apt-get install -y zfsutils-linux
            ;;

        fedora)
            sudo dnf install -y https://zfsonlinux.org/fedora/zfs-release-2-3.fc$(rpm -E %fedora).noarch.rpm
            sudo dnf install -y zfs
            ;;

        arch|manjaro)
            yay -S --noconfirm zfs-dkms
            ;;
    esac

    echo "✓ ZFS installed"
}

#############################
# Setup zBox directories
#############################
setup_zbox_dirs() {
    echo "[6/6] Setting up zBox directories..."

    sudo mkdir -p /var/lib/zbox/{images,rootfs,vms}
    sudo chown -R $USER:$USER /var/lib/zbox

    mkdir -p ~/.zbox/{vms,nomad/jobs}

    echo "✓ zBox directories created"
}

#############################
# Main installation
#############################
main() {
    echo "This will install:"
    echo "  - KVM + libvirt"
    echo "  - Firecracker microVMs"
    echo "  - Docker"
    echo "  - Nomad orchestration"
    echo "  - ZFS (optional)"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi

    install_kvm_libvirt
    install_firecracker
    install_docker
    install_nomad
    install_zfs
    setup_zbox_dirs

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ zBox Infrastructure Installation Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "IMPORTANT: You need to log out and back in for group changes to take effect!"
    echo ""
    echo "Then verify with:"
    echo "  zbox_check_infrastructure"
    echo ""
    echo "Next steps:"
    echo "  1. Load admin profile: ZBOX_PROFILE=admin zsh"
    echo "  2. Check status: zbox_check_infrastructure"
    echo "  3. Create a VM: zbox_vm_create <manifest.yaml>"
    echo ""
}

main "$@"
