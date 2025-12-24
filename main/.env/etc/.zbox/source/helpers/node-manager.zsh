#!/bin/zsh
#############################
# zBox Node Manager
# Discover and manage infrastructure nodes
# Compatible with YOUR node format
#############################

export ZBOX_NODES="$ZBOX_DIR/.env/nodes"

# List all available nodes
zbox_node_list() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Available Infrastructure Nodes"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ ! -d "$ZBOX_NODES" ]] || [[ -z "$(ls -A $ZBOX_NODES/*.yaml 2>/dev/null)" ]]; then
        echo "No nodes configured"
        echo "Nodes directory: $ZBOX_NODES"
        return 0
    fi

    for node_file in "$ZBOX_NODES"/*.yaml; do
        [[ -f "$node_file" ]] || continue
        [[ "$(basename "$node_file")" == "README.md" ]] && continue

        # Extract basic info
        node_id=$(grep '^id:' "$node_file" | head -1 | awk '{print $2}')
        node_name=$(grep '^name:' "$node_file" | head -1 | awk '{print $2}' | tr -d '"')
        node_ip=$(grep '^  local:' "$node_file" | head -1 | awk '{print $2}' | tr -d '"')

        echo "🖥️  Node: $node_id"
        echo "   Name:    $node_name"
        echo "   IP:      $node_ip"

        # Get capabilities (only top-level capabilities, not nested hardware capabilities)
        awk '
            /^capabilities:/ { in_caps=1; next }
            in_caps && /^[^ ]/ { exit }
            in_caps && /^  - / { sub(/^  - /, ""); print "   • " $0 }
        ' "$node_file"

        echo ""
    done
}

# Get node details
zbox_node_status() {
    local node_id="${1:-}"

    if [[ -z "$node_id" ]]; then
        echo "Usage: zbox node status <node_id>"
        echo ""
        echo "Available nodes:"
        for node_file in "$ZBOX_NODES"/*.yaml(N); do
            [[ -f "$node_file" ]] || continue
            [[ "$(basename "$node_file")" == "README.md" ]] && continue
            local id=$(grep '^id:' "$node_file" | awk '{print $2}')
            echo "  - $id"
        done
        return 1
    fi

    local node_file="$ZBOX_NODES/${node_id}_node.yaml"
    if [[ ! -f "$node_file" ]]; then
        # Try without _node suffix
        node_file="$ZBOX_NODES/${node_id}.yaml"
        if [[ ! -f "$node_file" ]]; then
            echo "ERROR: Node not found: $node_id"
            return 1
        fi
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Node Details: $node_id"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Parse basic info
    local name=$(grep '^name:' "$node_file" | head -1 | awk '{print $2}' | tr -d '"')
    local ip=$(grep '^  local:' "$node_file" | head -1 | awk '{print $2}' | tr -d '"')
    local os=$(grep '^    os:' "$node_file" | head -1 | cut -d: -f2- | xargs)
    local kernel=$(grep '^    kernel:' "$node_file" | head -1 | cut -d: -f2- | xargs)

    echo "Basic Info:"
    echo "  ID:      $node_id"
    echo "  Name:    $name"
    echo "  IP:      $ip"
    echo "  OS:      ${os:-Unknown}"
    echo "  Kernel:  ${kernel:-Unknown}"
    echo ""

    # Capabilities
    echo "Capabilities:"
    local in_caps=0
    while IFS= read -r line; do
        if [[ "$line" == "capabilities:" ]]; then
            in_caps=1
            continue
        fi
        if [[ $in_caps -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]*- ]]; then
                local cap=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
                echo "  ✓ $cap"
            else
                break
            fi
        fi
    done < "$node_file"
    echo ""

    # CPU Info
    echo "CPU:"
    local cpu_name=$(grep 'processor:' -A 20 "$node_file" | grep '^      name:' | head -1 | cut -d: -f2- | xargs)
    local cpu_cores=$(grep 'processor:' -A 20 "$node_file" | grep '^        total:' | head -1 | awk '{print $2}')
    local cpu_threads=$(grep 'processor:' -A 20 "$node_file" | grep '^      threads:' | head -1 | awk '{print $2}')

    [[ -n "$cpu_name" ]] && echo "  Model:   $cpu_name"
    [[ -n "$cpu_cores" ]] && echo "  Cores:   $cpu_cores"
    [[ -n "$cpu_threads" ]] && echo "  Threads: $cpu_threads"
    echo ""

    # Memory Info
    echo "Memory:"
    # Handle both array and single memory configs
    local mem_size=$(grep '^    memory:' -A 10 "$node_file" | grep 'size:' | head -1 | awk '{print $2}')
    local mem_type=$(grep '^    memory:' -A 10 "$node_file" | grep 'type:' | head -1 | awk '{print $2}')

    [[ -n "$mem_size" ]] && echo "  Size:    ${mem_size}GB"
    [[ -n "$mem_type" ]] && echo "  Type:    $mem_type"
    echo ""

    # Storage Info
    echo "Storage:"
    local storage_model=$(grep 'storage:' -A 10 "$node_file" | grep 'model:' | head -1 | cut -d: -f2- | xargs)
    local storage_cap=$(grep 'storage:' -A 10 "$node_file" | grep 'capacity_gb:' | head -1 | awk '{print $2}')
    local storage_type=$(grep 'storage:' -A 10 "$node_file" | grep 'type:' | head -1 | cut -d: -f2- | xargs)

    [[ -n "$storage_type" ]] && echo "  Type:     $storage_type"
    [[ -n "$storage_model" ]] && echo "  Model:    $storage_model"
    [[ -n "$storage_cap" ]] && echo "  Capacity: ${storage_cap}GB"
    echo ""

    # Network status
    echo "Network Status:"
    if ping -c 1 -W 1 "$ip" &>/dev/null; then
        echo "  Ping:     ✅ Reachable"

        # Try SSH (default port 22)
        if timeout 2 ssh -p 22 -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o BatchMode=yes "$ip" "echo 1" &>/dev/null 2>&1; then
            echo "  SSH:      ✅ Connected"
        else
            echo "  SSH:      ⚠️  Not accessible (key-based auth may be required)"
        fi
    else
        echo "  Ping:     ❌ Unreachable"
    fi
}

# Get total resources across all nodes
zbox_get_total_resources() {
    local total_cores=0
    local total_mem=0
    local total_storage=0
    local node_count=0

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total Resources Across All Nodes"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    for node_file in "$ZBOX_NODES"/*.yaml(N); do
        [[ -f "$node_file" ]] || continue
        [[ "$(basename "$node_file")" == "README.md" ]] && continue
        ((node_count++))

        local cores=$(grep 'processor:' -A 20 "$node_file" | grep '^        total:' | head -1 | awk '{print $2}')
        local mem=$(grep -A 10 '^    memory:' "$node_file" | grep 'size:' | head -1 | awk '{print $2}')
        local storage=$(grep 'storage:' -A 10 "$node_file" | grep 'capacity_gb:' | head -1 | awk '{print $2}')

        [[ -n "$cores" ]] && total_cores=$((total_cores + cores))
        [[ -n "$mem" ]] && total_mem=$((total_mem + mem))
        [[ -n "$storage" ]] && total_storage=$((total_storage + storage))
    done

    echo "Nodes:    $node_count"
    echo "CPU:      $total_cores cores"
    echo "Memory:   ${total_mem}GB"
    echo "Storage:  ${total_storage}GB"
}

# Check which nodes have specific capability
zbox_nodes_with_capability() {
    local search_cap="$1"

    if [[ -z "$search_cap" ]]; then
        echo "Usage: zbox_nodes_with_capability <capability>"
        echo "Examples: 'Libvirt', 'Docker', 'Ollama'"
        return 1
    fi

    echo "Nodes with capability: $search_cap"
    echo ""

    for node_file in "$ZBOX_NODES"/*.yaml(N); do
        [[ -f "$node_file" ]] || continue
        [[ "$(basename "$node_file")" == "README.md" ]] && continue

        if grep -i "capabilities:" -A 10 "$node_file" | grep -qi "$search_cap"; then
            local id=$(grep '^id:' "$node_file" | awk '{print $2}')
            local name=$(grep '^name:' "$node_file" | awk '{print $2}' | tr -d '"')
            echo "✓ $id ($name)"
        fi
    done
}
