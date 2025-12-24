#!/bin/zsh
#############################
# ZBOX VM Manager
# Manage VMs across KVM, Firecracker, QEMU
#############################

export ZBOX_VMS="${ZBOX_DIR}/vms"
export ZBOX_VM_IMAGES="/var/lib/zbox/images"
export ZBOX_VM_ROOTFS="/var/lib/zbox/rootfs"

# Initialize VM management
zbox_vm_init() {
    mkdir -p "$ZBOX_VMS" "$ZBOX_VM_IMAGES" "$ZBOX_VM_ROOTFS"

    # Check for hypervisors
    zbox_check_infrastructure
}

# Check infrastructure availability
zbox_check_infrastructure() {
    echo "Checking infrastructure..."
    echo ""

    # Check KVM/libvirt
    if command -v virsh &>/dev/null; then
        echo "✅ libvirt installed"
        if virsh -c qemu:///system list &>/dev/null; then
            echo "✅ libvirt accessible"
        else
            echo "⚠️  libvirt not accessible (may need sudo)"
        fi
    else
        echo "❌ libvirt not installed"
    fi

    # Check Firecracker
    if command -v firecracker &>/dev/null; then
        echo "✅ Firecracker installed"
    else
        echo "❌ Firecracker not installed"
    fi

    # Check Docker
    if command -v docker &>/dev/null; then
        echo "✅ Docker installed"
        if docker ps &>/dev/null; then
            echo "✅ Docker accessible"
        else
            echo "⚠️  Docker not accessible (may need sudo/group)"
        fi
    else
        echo "❌ Docker not installed"
    fi

    # Check Nomad
    if command -v nomad &>/dev/null; then
        echo "✅ Nomad installed"
        if nomad status &>/dev/null; then
            echo "✅ Nomad accessible"
        else
            echo "⚠️  Nomad not running"
        fi
    else
        echo "❌ Nomad not installed"
    fi
}

# List all VMs
zbox_vm_list() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "zBox Managed VMs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # List VMs from manifests (N) returns empty list if no matches
    for vm_manifest in "$ZBOX_VMS"/**/manifest.yaml(N); do
        if [[ -f "$vm_manifest" ]]; then
            local vm_name=$(grep '^  name:' "$vm_manifest" | awk '{print $2}' | tr -d '"')
            local vm_type=$(grep '^  type:' "$vm_manifest" | awk '{print $2}' | tr -d '"')
            local provider=$(grep '^  provider:' "$vm_manifest" | awk '{print $2}' | tr -d '"')

            echo "🖥️  VM: $vm_name"
            echo "   Type:     $vm_type"
            echo "   Provider: $provider"
            echo "   Manifest: $vm_manifest"

            # Check if running
            case "$provider" in
                libvirt|kvm)
                    if virsh -c qemu:///system list --all 2>/dev/null | grep -q "$vm_name"; then
                        echo "   Status:   ✅ Running"
                    else
                        echo "   Status:   ⏹️  Stopped"
                    fi
                    ;;
                firecracker)
                    if [[ -S "/run/firecracker-${vm_name}.socket" ]]; then
                        echo "   Status:   ✅ Running"
                    else
                        echo "   Status:   ⏹️  Stopped"
                    fi
                    ;;
            esac

            echo ""
        fi
    done
}

# Create VM from manifest
zbox_vm_create() {
    local manifest_file="$1"

    if [[ -z "$manifest_file" ]] || [[ ! -f "$manifest_file" ]]; then
        echo "Usage: zbox_vm_create <manifest.yaml>"
        return 1
    fi

    echo "Creating VM from manifest: $manifest_file"

    # Parse manifest (basic YAML parsing)
    local vm_name=$(grep '^  name:' "$manifest_file" | awk '{print $2}' | tr -d '"')
    local provider=$(grep '^  provider:' "$manifest_file" | awk '{print $2}' | tr -d '"')

    echo "VM Name: $vm_name"
    echo "Provider: $provider"

    # Create VM directory
    mkdir -p "$ZBOX_VMS/$vm_name"
    cp "$manifest_file" "$ZBOX_VMS/$vm_name/manifest.yaml"

    # Provider-specific creation
    case "$provider" in
        firecracker)
            zbox_vm_create_firecracker "$ZBOX_VMS/$vm_name/manifest.yaml"
            ;;
        libvirt|kvm)
            zbox_vm_create_libvirt "$ZBOX_VMS/$vm_name/manifest.yaml"
            ;;
        qemu)
            zbox_vm_create_qemu "$ZBOX_VMS/$vm_name/manifest.yaml"
            ;;
        *)
            echo "ERROR: Unknown provider: $provider"
            return 1
            ;;
    esac
}

# Create Firecracker microVM
zbox_vm_create_firecracker() {
    local manifest="$1"

    echo "Creating Firecracker microVM..."

    local vm_name=$(grep '^  name:' "$manifest" | awk '{print $2}' | tr -d '"')
    local vcpus=$(grep '^  vcpus:' "$manifest" | awk '{print $2}')
    local memory=$(grep '^  memory:' "$manifest" | awk '{print $2}' | tr -d '"')

    # Create rootfs
    local rootfs="$ZBOX_VM_ROOTFS/${vm_name}.ext4"
    local rootfs_size=$(grep -A1 'name: "root"' "$manifest" | grep 'size:' | awk '{print $2}' | tr -d '"')

    echo "Creating rootfs: $rootfs ($rootfs_size)"
    dd if=/dev/zero of="$rootfs" bs=1 count=0 seek="$rootfs_size" 2>/dev/null
    mkfs.ext4 "$rootfs" >/dev/null 2>&1

    # Create Firecracker config
    local config="$ZBOX_VMS/$vm_name/firecracker.json"

    cat > "$config" <<EOF
{
  "boot-source": {
    "kernel_image_path": "/opt/firecracker/kernels/vmlinux",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "$rootfs",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "machine-config": {
    "vcpu_count": $vcpus,
    "mem_size_mib": ${memory%M}
  },
  "network-interfaces": []
}
EOF

    echo "✓ Firecracker VM created: $vm_name"
    echo "  Config: $config"
    echo "  Rootfs: $rootfs"
}

# Create libvirt/KVM VM
zbox_vm_create_libvirt() {
    local manifest="$1"

    echo "Creating libvirt/KVM VM..."

    local vm_name=$(grep '^  name:' "$manifest" | awk '{print $2}' | tr -d '"')
    local vcpus=$(grep '^  vcpus:' "$manifest" | awk '{print $2}')
    local memory=$(grep '^  memory:' "$manifest" | awk '{print $2}' | tr -d '"' | sed 's/M/*1024/;s/G/*1024*1024/' | bc)

    # Create disk
    local disk="$ZBOX_VM_ROOTFS/${vm_name}.qcow2"
    local disk_size=$(grep -A1 'name: "root"' "$manifest" | grep 'size:' | awk '{print $2}' | tr -d '"')

    echo "Creating disk: $disk ($disk_size)"
    qemu-img create -f qcow2 "$disk" "$disk_size" >/dev/null 2>&1

    # Create libvirt XML
    local xml="$ZBOX_VMS/$vm_name/domain.xml"

    cat > "$xml" <<EOF
<domain type='kvm'>
  <name>$vm_name</name>
  <memory unit='KiB'>$memory</memory>
  <vcpu placement='static'>$vcpus</vcpu>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
    <boot dev='hd'/>
  </os>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$disk'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
  </devices>
</domain>
EOF

    echo "✓ libvirt VM created: $vm_name"
    echo "  XML: $xml"
    echo "  Disk: $disk"
    echo ""
    echo "To define in libvirt:"
    echo "  virsh define $xml"
}

# Start VM
zbox_vm_start() {
    local vm_name="$1"

    if [[ -z "$vm_name" ]]; then
        echo "Usage: zbox_vm_start <vm_name>"
        return 1
    fi

    local manifest="$ZBOX_VMS/$vm_name/manifest.yaml"

    if [[ ! -f "$manifest" ]]; then
        echo "ERROR: VM not found: $vm_name"
        return 1
    fi

    local provider=$(grep '^  provider:' "$manifest" | awk '{print $2}' | tr -d '"')

    echo "Starting VM: $vm_name (provider: $provider)"

    case "$provider" in
        firecracker)
            local config="$ZBOX_VMS/$vm_name/firecracker.json"
            local socket="/run/firecracker-${vm_name}.socket"

            rm -f "$socket"
            firecracker --api-sock "$socket" --config-file "$config" &
            echo "✓ Firecracker VM started"
            echo "  Socket: $socket"
            ;;

        libvirt|kvm)
            virsh -c qemu:///system start "$vm_name"
            ;;

        qemu)
            echo "QEMU direct start not yet implemented"
            ;;
    esac
}

# Stop VM
zbox_vm_stop() {
    local vm_name="$1"

    if [[ -z "$vm_name" ]]; then
        echo "Usage: zbox_vm_stop <vm_name>"
        return 1
    fi

    local manifest="$ZBOX_VMS/$vm_name/manifest.yaml"

    if [[ ! -f "$manifest" ]]; then
        echo "ERROR: VM not found: $vm_name"
        return 1
    fi

    local provider=$(grep '^  provider:' "$manifest" | awk '{print $2}' | tr -d '"')

    echo "Stopping VM: $vm_name"

    case "$provider" in
        firecracker)
            local socket="/run/firecracker-${vm_name}.socket"
            # Send shutdown via API
            curl -X PUT "unix://${socket}/actions" -d '{"action_type": "SendCtrlAltDel"}'
            ;;

        libvirt|kvm)
            virsh -c qemu:///system shutdown "$vm_name"
            ;;
    esac
}

# Destroy VM
zbox_vm_destroy() {
    local vm_name="$1"
    local force="${2:-false}"

    if [[ -z "$vm_name" ]]; then
        echo "Usage: zbox_vm_destroy <vm_name> [force]"
        return 1
    fi

    echo "⚠️  WARNING: This will permanently destroy VM: $vm_name"

    if [[ "$force" != "true" ]] && [[ "$force" != "1" ]]; then
        echo "Are you sure? (yes/no)"
        read -r response
        if [[ "$response" != "yes" ]]; then
            echo "Cancelled"
            return 1
        fi
    fi

    # Stop VM first
    zbox_vm_stop "$vm_name"

    # Remove VM files
    rm -rf "$ZBOX_VMS/$vm_name"
    rm -f "$ZBOX_VM_ROOTFS/${vm_name}."*

    # Remove from libvirt if applicable
    virsh -c qemu:///system undefine "$vm_name" 2>/dev/null

    echo "✓ VM destroyed: $vm_name"
}

# Aliases
alias vmlist='zbox_vm_list'
alias vmcreate='zbox_vm_create'
alias vmstart='zbox_vm_start'
alias vmstop='zbox_vm_stop'
alias vmkill='zbox_vm_destroy'
