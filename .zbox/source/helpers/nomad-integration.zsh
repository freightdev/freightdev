#!/bin/zsh
#############################
# ZBOX Nomad Integration
# Orchestrate zBox VMs and containers with Nomad
#############################

export NOMAD_ADDR="${NOMAD_ADDR:-http://localhost:4646}"
export ZBOX_NOMAD_JOBS="$ZBOX_DIR/nomad/jobs"

# Initialize Nomad integration
zbox_nomad_init() {
    mkdir -p "$ZBOX_NOMAD_JOBS"

    if ! command -v nomad &>/dev/null; then
        echo "ERROR: Nomad not installed"
        return 1
    fi

    # Check if Nomad is running
    if ! nomad status &>/dev/null; then
        echo "WARNING: Nomad is not running"
        echo "Start with: sudo systemctl start nomad"
        return 1
    fi

    echo "✓ Nomad integration ready"
}

# Create Nomad job from VM manifest
zbox_nomad_create_vm_job() {
    local vm_manifest="$1"

    if [[ ! -f "$vm_manifest" ]]; then
        echo "ERROR: Manifest not found: $vm_manifest"
        return 1
    fi

    local vm_name=$(grep '^  name:' "$vm_manifest" | awk '{print $2}' | tr -d '"')
    local vcpus=$(grep '^  vcpus:' "$vm_manifest" | awk '{print $2}')
    local memory=$(grep '^  memory:' "$vm_manifest" | awk '{print $2}' | tr -d '"')

    local job_file="$ZBOX_NOMAD_JOBS/${vm_name}.nomad"

    cat > "$job_file" <<EOF
job "zbox-vm-${vm_name}" {
  datacenters = ["zbox-dc1"]
  type        = "service"

  group "vm" {
    count = 1

    task "firecracker" {
      driver = "exec"

      config {
        command = "/usr/bin/firecracker"
        args = [
          "--api-sock", "/run/firecracker-${vm_name}.socket",
          "--config-file", "$ZBOX_VMS/${vm_name}/firecracker.json"
        ]
      }

      resources {
        cpu    = $(( vcpus * 1000 ))
        memory = ${memory%M}
      }

      service {
        name = "zbox-vm-${vm_name}"
        port = "ssh"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    network {
      port "ssh" {
        static = 22
      }
    }
  }

  meta {
    zbox_managed = "true"
    zbox_profile = "$ZBOX_CURRENT_PROFILE"
  }
}
EOF

    echo "✓ Nomad job created: $job_file"
    echo ""
    echo "To run:"
    echo "  nomad job run $job_file"
}

# Run Nomad job
zbox_nomad_run() {
    local job_file="$1"

    if [[ -z "$job_file" ]]; then
        echo "Usage: zbox_nomad_run <job_file>"
        return 1
    fi

    if [[ ! -f "$job_file" ]]; then
        echo "ERROR: Job file not found: $job_file"
        return 1
    fi

    echo "Running Nomad job: $job_file"
    nomad job run "$job_file"
}

# List zBox-managed Nomad jobs
zbox_nomad_list() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "zBox Managed Nomad Jobs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    nomad job status -json 2>/dev/null | jq -r '.[] | select(.Meta.zbox_managed == "true") | "\(.ID)\t\(.Status)\t\(.Meta.zbox_profile)"' | \
    while IFS=$'\t' read -r job_id status profile; do
        echo "📦 Job: $job_id"
        echo "   Status:  $status"
        echo "   Profile: $profile"
        echo ""
    done
}

# Stop Nomad job
zbox_nomad_stop() {
    local job_name="$1"

    if [[ -z "$job_name" ]]; then
        echo "Usage: zbox_nomad_stop <job_name>"
        return 1
    fi

    echo "Stopping Nomad job: $job_name"
    nomad job stop "$job_name"
}

# Deploy entire profile to Nomad
zbox_nomad_deploy_profile() {
    local profile_name="${1:-$ZBOX_CURRENT_PROFILE}"

    echo "Deploying profile to Nomad: $profile_name"

    # Find all VMs in profile
    local profile_dir="$ZBOX_PROFILES/$profile_name"

    if [[ ! -d "$profile_dir" ]]; then
        echo "ERROR: Profile not found: $profile_name"
        return 1
    fi

    # Look for VM manifests
    for vm_manifest in "$profile_dir"/vms/*/manifest.yaml; do
        if [[ -f "$vm_manifest" ]]; then
            echo "Creating Nomad job for VM: $vm_manifest"
            zbox_nomad_create_vm_job "$vm_manifest"
        fi
    done

    echo ""
    echo "✓ Profile deployment jobs created"
    echo "Review jobs in: $ZBOX_NOMAD_JOBS"
}

# Aliases
alias njobs='zbox_nomad_list'
alias nrun='zbox_nomad_run'
alias nstop='zbox_nomad_stop'
alias ndeploy='zbox_nomad_deploy_profile'
