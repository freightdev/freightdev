#!/bin/bash
# Build all AI agency services and agents

set -e  # Exit on error

AGENT_ROOT="/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo"
LOG_FILE="$AGENCY_ROOT/logs/build-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$AGENCY_ROOT/logs"

echo "=====================================================================" | tee -a "$LOG_FILE"
echo "Building AI Agency Forge - $(date)" | tee -a "$LOG_FILE"
echo "=====================================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Core services
CORE_SERVICES=(
    "core/ai-auditor"
    "core/api-gateway"
    "core/autonomous-coordinator"
    "core/command-coordinator"
    "core/coordinator"
)

# AI Agents
AGENTS=(
    "arsenal/ai-agents/file-ops"
    "arsenal/ai-agents/service-manager"
    "arsenal/ai-agents/data-collector"
    "arsenal/ai-agents/databbase-manager"
    "arsenal/ai-agents/web-search"
    "arsenal/ai-agents/messaging-service"
    "arsenal/ai-agents/screen-controller"
    "arsenal/ai-agents/vision-controller"
    "arsenal/ai-agents/code-assistant"
    "arsenal/ai-agents/pdf-service"
)

build_service() {
    local service=$1
    local name=$(basename "$service")

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    echo "Building: $name" | tee -a "$LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"

    cd "$AGENCY_ROOT/$service"

    if cargo build --release >> "$LOG_FILE" 2>&1; then
        echo "✅ $name built successfully" | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ $name build failed" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Build core services
echo "Building Core Services..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

for service in "${CORE_SERVICES[@]}"; do
    if ! build_service "$service"; then
        echo "Warning: $service failed to build" | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
done

# Build agents
echo "" | tee -a "$LOG_FILE"
echo "Building AI Agents..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

for agent in "${AGENTS[@]}"; do
    if ! build_service "$agent"; then
        echo "Warning: $agent failed to build" | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
done

echo "=====================================================================" | tee -a "$LOG_FILE"
echo "Build Complete - $(date)" | tee -a "$LOG_FILE"
echo "=====================================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
