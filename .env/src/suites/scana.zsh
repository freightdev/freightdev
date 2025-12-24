###################
# SCAN FUNCTIONS
###################

scan_sudo() {
    section "Sudo / Privileges"
    echo "=== Privileges Check ==="

    if [[ $EUID -ne 0 ]]; then
        echo "⚠️  Some sections may require sudo — you may be prompted for your password."
    else
        echo "You are running as root. All scans will have full privileges."
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 1. BIOS / Firmware
scan_bios() {
    section "BIOS / Firmware"
    echo "=== BIOS / Firmware Summary ==="

    if command -v dmidecode &>/dev/null; then
        if sudo dmidecode -t bios 2>/dev/null | grep -E 'Vendor:|Version:|Release Date:' &>/dev/null; then
            sudo dmidecode -t bios 2>/dev/null | grep -E 'Vendor:|Version:|Release Date:'
        else
            echo "Failed to read BIOS information (may require root privileges)"
        fi
    else
        echo "dmidecode not installed"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 2. OS / Kernel
scan_os() {
    section "OS / Kernel"
    echo "=== OS & Kernel Summary ==="

    # Kernel info
    uname -a

    # OS release info
    if [[ -f /etc/os-release ]]; then
        echo
        echo "--- OS Release ---"
        awk -F= '/^(NAME|VERSION|ID|VERSION_ID)=/ {gsub(/"/,"",$2); printf "%s: %s\n", $1, $2}' /etc/os-release
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 3. CPU
scan_cpu() {
    section "CPU"

    if command -v lscpu &>/dev/null; then
        # Gather info from lscpu
        local model arch cores threads sockets tpc max_mhz min_mhz virt
        local l1d l1i l2 l3

        model=$(lscpu | awk -F: '/Model name/ {gsub(/^ +| +$/,"",$2); print $2}')
        arch=$(lscpu | awk -F: '/Architecture/ {gsub(/^ +| +$/,"",$2); print $2}')
        cores=$(lscpu | awk -F: '/Core\(s\) per socket/ {gsub(/^ +| +$/,"",$2); print $2}')
        threads=$(lscpu | awk -F: '/CPU\(s\):/ {gsub(/^ +| +$/,"",$2); print $2}')
        sockets=$(lscpu | awk -F: '/Socket\(s\)/ {gsub(/^ +| +$/,"",$2); print $2}')
        tpc=$(lscpu | awk -F: '/Thread\(s\) per core/ {gsub(/^ +| +$/,"",$2); print $2}')
        max_mhz=$(lscpu | awk -F: '/CPU max MHz/ {gsub(/^ +| +$/,"",$2); printf "%.0f MHz\n",$2}')
        min_mhz=$(lscpu | awk -F: '/CPU min MHz/ {gsub(/^ +| +$/,"",$2); printf "%.0f MHz\n",$2}')
        virt=$(lscpu | awk -F: '/Virtualization/ {gsub(/^ +| +$/,"",$2); print $2}')
        l1d=$(lscpu | awk -F: '/L1d cache/ {gsub(/^ +| +$/,"",$2); print $2}')
        l1i=$(lscpu | awk -F: '/L1i cache/ {gsub(/^ +| +$/,"",$2); print $2}')
        l2=$(lscpu | awk -F: '/L2 cache/ {gsub(/^ +| +$/,"",$2); print $2}')
        l3=$(lscpu | awk -F: '/L3 cache/ {gsub(/^ +| +$/,"",$2); print $2}')

        echo "=== CPU Summary ==="
        echo "Model          : $model"
        echo "Architecture   : $arch"
        echo "Sockets        : $sockets"
        echo "Cores          : $cores"
        echo "Threads        : $threads"
        echo "Threads/Core   : $tpc"
        echo "Max MHz        : $max_mhz"
        echo "Min MHz        : $min_mhz"
        echo "Virtualization : $virt"
        echo "L1d Cache      : $l1d"
        echo "L1i Cache      : $l1i"
        echo "L2 Cache       : $l2"
        echo "L3 Cache       : $l3"
        echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"

    else
        # Fallback to /proc/cpuinfo
        echo "=== CPU Summary (fallback) ==="
        awk -F: '
            /^model name/ {if(!m++) print "Model: "$2}
            /^cpu cores/ {if(!c++) print "Cores: "$2}
            /^siblings/ {if(!t++) print "Threads: "$2}
        ' /proc/cpuinfo
        echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
    fi
}



# 4. Memory
scan_memory() {
    section "Memory"

    if command -v free &>/dev/null; then
        local total used free buff cache swap
        read -r total used free buff cache <<<$(free -m | awk '/Mem:/ {print $2, $3, $4, $6, $7}')
        swap=$(free -m | awk '/Swap:/ {print $2, $3, $4}')
        echo "=== Memory Summary ==="
        echo "Total RAM     : ${total} MiB"
        echo "Used RAM      : ${used} MiB"
        echo "Free RAM      : ${free} MiB"
        echo "Buffers/Cache : ${buff} / ${cache} MiB"
        echo "Swap          : $swap MiB"
        echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
    else
        # Fallback
        echo "=== Memory Summary (fallback) ==="
        head -n5 /proc/meminfo
        echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
    fi
}


# 5. Storage & Disks
scan_storage() {
    section "Storage & Disks"
    echo "=== Disk & Storage Summary ==="

    # List disks and partitions
    if command -v lsblk &>/dev/null; then
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
    else
        echo "lsblk command not found"
    fi

    # Show disk usage
    if command -v df &>/dev/null; then
        echo
        echo "--- Filesystem Usage ---"
        df -hT | grep -v tmpfs | grep -v overlay
    fi

    # SMART health check
    if command -v smartctl &>/dev/null; then
        echo
        echo "--- SMART Health Check ---"
        for dev in /dev/sd?; do
            [[ -e "$dev" ]] || continue
            echo "-- ${dev##*/} --"
            sudo smartctl -H "$dev" 2>/dev/null || echo "SMART check failed for $dev"
        done
    else
        echo "smartctl not available"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 6. GPU / Accelerators
scan_gpu() {
    section "GPU / Accelerators"
    echo "=== GPU & Accelerator Summary ==="

    if command -v lspci &>/dev/null; then
        echo "--- PCI GPUs ---"
        lspci | grep -Ei 'vga|3d|display'
    else
        echo "lspci not available"
    fi

    echo
    echo "--- /dev GPU/NPU Devices ---"
    if compgen -G "/dev/dri*" >/dev/null 2>&1 || compgen -G "/dev/*npu*" >/dev/null 2>&1; then
        for dev in /dev/dri* /dev/*npu*; do
            [[ -e "$dev" ]] || continue
            echo "Found device: $dev"
        done
    else
        echo "No /dev/dri or NPU devices found"
    fi

    # Optional: detect CUDA / OpenCL
    if command -v nvidia-smi &>/dev/null; then
        echo
        echo "--- NVIDIA GPU Info ---"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}

# 7. Network
scan_network() {
    section "Network"
    echo "=== Network Summary ==="
    print -P "Local IP: $(ip route get 1 | awk '{print $NF;exit}')"
    print -P "Public IP: $(curl -s https://ipinfo.io/ip)"
    print -P "DNS Servers:"
    grep nameserver /etc/resolv.conf
    print -P "Active Connections:"
    ss -tuln


    # Interfaces
    echo "--- Interfaces ---"
    if command -v ip &>/dev/null; then
        ip -brief addr show
    elif command -v ifconfig &>/dev/null; then
        ifconfig -a
    else
        echo "No network interface command available"
    fi

    echo
    # Routing
    echo "--- Routing Table ---"
    if command -v ip &>/dev/null; then
        ip route
    elif command -v route &>/dev/null; then
        route -n
    else
        echo "No routing table command available"
    fi

    echo
    # DNS
    echo "--- DNS ---"
    if [[ -r /etc/resolv.conf ]]; then
        grep -E 'nameserver' /etc/resolv.conf
    else
        echo "Cannot read /etc/resolv.conf"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 8. Firewall & Security
scan_firewall() {
    section "Firewall & Security"
    echo "=== Firewall & Security Summary ==="

    if command -v iptables &>/dev/null; then
        echo "--- iptables Rules ---"
        if sudo iptables -L -v -n &>/dev/null; then
            sudo iptables -L -v -n
        else
            echo "Failed to read iptables rules or insufficient permissions"
        fi
    elif command -v nft &>/dev/null; then
        echo "--- nftables Rules ---"
        if sudo nft list ruleset &>/dev/null; then
            sudo nft list ruleset
        else
            echo "Failed to read nftables rules or insufficient permissions"
        fi
    else
        echo "No iptables or nftables found"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}

# 9. Container Runtime
scan_containers() {
    section "Container Runtime"
    echo "=== Container Runtime Summary ==="

    if command -v nerdctl &>/dev/null; then
        echo "--- nerdctl Version ---"
        nerdctl version 2>/dev/null
        echo
        echo "--- Containers ---"
        nerdctl ps -a 2>/dev/null
    elif command -v ctr &>/dev/null; then
        echo "--- containerd (ctr) Version ---"
        ctr version 2>/dev/null
        echo
        echo "--- Containers ---"
        sudo ctr containers list 2>/dev/null
    elif command -v docker &>/dev/null; then
        echo "--- Docker Version ---"
        docker version 2>/dev/null
        echo
        echo "--- Containers ---"
        docker ps -a 2>/dev/null
    else
        echo "No container runtime found (nerdctl, ctr, or docker)"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 10. Services
scan_services() {
    section "Services"
    echo "=== Services Summary ==="

    if command -v rc-status &>/dev/null; then
        echo "--- OpenRC Services ---"
        if sudo rc-status &>/dev/null; then
            sudo rc-status
        else
            echo "Failed to read OpenRC status or insufficient permissions"
        fi
    elif command -v systemctl &>/dev/null; then
        echo "--- systemd Running Services ---"
        if systemctl list-units --type=service --state=running &>/dev/null; then
            systemctl list-units --type=service --state=running
        else
            echo "Failed to read systemd services"
        fi
    elif command -v service &>/dev/null; then
        echo "--- SysV Services ---"
        if sudo service --status-all &>/dev/null; then
            sudo service --status-all
        else
            echo "Failed to read SysV services"
        fi
    else
        echo "No service management tool found"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 11. Running Processes
scan_processes() {
    section "Running Processes"
    echo "=== Top Processes by Memory Usage ==="

    if ps aux --sort=-%mem &>/dev/null; then
        ps aux --sort=-%mem | head -n 15
    elif ps aux &>/dev/null; then
        ps aux | sort -k4 -nr | head -n 15
    else
        echo "Failed to get process information"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 12. Jupyter / Dev Services
scan_notebooks() {
    section "Jupyter / Development"
    echo "=== Jupyter / Dev Processes ==="

    if pgrep -af jupyter &>/dev/null; then
        pgrep -af jupyter
    else
        echo "No Jupyter processes detected"
    fi

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}


# 13. Summary
scan_summary() {
    section "Summary"
    echo "Scan completed at: $(date)"
}

# Main scan function
scana() {
    case "${1:-all}" in
        all|"")
            scan_sudo
            scan_bios
            scan_os
            scan_cpu
            scan_memory
            scan_storage
            scan_gpu
            scan_network
            scan_firewall
            scan_containers
            scan_services
            scan_processes
            scan_notebooks
            scan_summary
            ;;
        sudo)         scan_sudo; scan_summary ;;
        bios)         scan_bios; scan_summary ;;
        os)           scan_os; scan_summary ;;
        cpu)          scan_cpu; scan_summary ;;
        gpu)          scan_gpu; scan_summary ;;
        memory)       scan_memory; scan_summary ;;
        storage)      scan_storage; scan_summary ;;
        network)      scan_network; scan_summary ;;
        firewall)     scan_firewall; scan_summary ;;
        container|containers)    scan_containers; scan_summary ;;
        services)     scan_services; scan_summary ;;
        processes)    scan_processes; scan_summary ;;
        notebooks)    scan_notebooks; scan_summary ;;
        help|--help|-h)
            cat <<EOF
Usage: scan [option]

Options:
    all          Run all scans (default)
    sudo         Check sudo requirements
    bios         BIOS/Firmware information
    os           Operating system and kernel
    cpu          CPU information
    gpu          GPU and accelerator information
    memory       Memory usage
    storage      Storage and disk information
    network      Network configuration
    firewall     Firewall and security settings
    containers   Container runtime information
    services     System services
    processes    Running processes
    notebooks    Jupyter/development services
    help         Show this help message

Examples:
    scan              # Run all scans
    scan cpu          # Show only CPU information
    scan network      # Show only network information
EOF
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use 'scan help' for usage information"
            return 1
            ;;
    esac
}
