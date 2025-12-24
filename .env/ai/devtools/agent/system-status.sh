#!/bin/bash
# Complete system status check

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "═══════════════════════════════════════════════════════"
echo "  AGENCY FORGE - SYSTEM STATUS"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📅 Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🖥️  Host: $(hostname)"
echo "📂 Root: $PROJECT_ROOT"
echo ""

# Function to check if port is listening
check_port() {
    local port=$1
    ss -tlnp 2>/dev/null | grep -q ":$port " && return 0 || return 1
}

# Function to check health endpoint
check_health() {
    local url=$1
    curl -sf "$url" >/dev/null 2>&1 && return 0 || return 1
}

# Function to check systemd service
check_systemd() {
    local service=$1
    systemctl --user is-active "$service" >/dev/null 2>&1 && return 0 || return 1
}

# External Services
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "EXTERNAL SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# SurrealDB
if check_systemd "surrealdb.service"; then
    if check_port 8000; then
        echo "✓ SurrealDB       [🟢 RUNNING] Port: 8000"
    else
        echo "⚠ SurrealDB       [🟡 STARTED] Port: 8000 (not listening)"
    fi
else
    echo "✗ SurrealDB       [🔴 STOPPED]"
fi

# llama.cpp
if check_systemd "llamacpp.service"; then
    if check_port 11435 && check_health "http://localhost:11435/health"; then
        echo "✓ llama.cpp       [🟢 RUNNING] Port: 11435"
    else
        echo "⚠ llama.cpp       [🟡 STARTED] Port: 11435 (not healthy)"
    fi
else
    echo "✗ llama.cpp       [🔴 STOPPED]"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AI-CORE SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if binaries exist
for component in coordinator api-gateway command-coordinator ai-auditor; do
    case "$component" in
        coordinator)
            binary="$PROJECT_ROOT/ai-core/coordinator/target/release/coordinator-abstraction"
            service_name="coordinator.service"
            port="TBD"
            ;;
        api-gateway)
            binary="$PROJECT_ROOT/ai-core/api-gateway/target/release/api-gateway"
            service_name="api-gateway.service"
            port="TBD"
            ;;
        command-coordinator)
            binary="$PROJECT_ROOT/ai-core/command-coordinator/target/release/command-coordinator"
            service_name="command-coordinator.service"
            port="TBD"
            ;;
        ai-auditor)
            binary="$PROJECT_ROOT/ai-core/ai-auditor/target/release/auditor-agent"
            service_name="ai-auditor.service"
            port="TBD"
            ;;
    esac

    if [ -f "$binary" ]; then
        if check_systemd "$service_name" 2>/dev/null; then
            echo "✓ $component       [🟢 RUNNING] Built + Deployed"
        else
            echo "⚠ $component       [🟡 BUILT] Not deployed"
        fi
    else
        echo "✗ $component       [🔴 NOT BUILT]"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AI-AGENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Lead Scraper
if check_systemd "lead-scraper.service"; then
    if check_port 9013 && check_health "http://localhost:9013/health"; then
        echo "✓ lead-scraper    [🟢 RUNNING] Port: 9013"
    else
        echo "⚠ lead-scraper    [🟡 STARTED] Port: 9013 (not healthy)"
    fi
else
    if [ -f "$PROJECT_ROOT/arsenal/ai-agents/lead-scraper/target/release/lead-scraper" ]; then
        echo "⚠ lead-scraper    [🟡 BUILT] Not deployed"
    else
        echo "✗ lead-scraper    [🔴 NOT BUILT]"
    fi
fi

# Lead Analyzer
if check_systemd "lead-analyzer.service"; then
    if check_port 9014 && check_health "http://localhost:9014/health"; then
        echo "✓ lead-analyzer   [🟢 RUNNING] Port: 9014"
    else
        echo "⚠ lead-analyzer   [🟡 STARTED] Port: 9014 (not healthy)"
    fi
else
    if [ -f "$PROJECT_ROOT/arsenal/ai-agents/lead-analyzer/target/release/lead-analyzer" ]; then
        echo "⚠ lead-analyzer   [🟡 BUILT] Not deployed"
    else
        echo "✗ lead-analyzer   [🔴 NOT BUILT]"
    fi
fi

# Data Collector
if check_systemd "data-collector.service" 2>/dev/null; then
    if check_port 9006; then
        echo "✓ data-collector  [🟢 RUNNING] Port: 9006"
    else
        echo "⚠ data-collector  [🟡 STARTED] Port: 9006"
    fi
else
    if [ -f "$PROJECT_ROOT/arsenal/ai-agents/data-collector/target/release/data-collector" ]; then
        echo "⚠ data-collector  [🟡 BUILT] Not deployed"
    else
        echo "✗ data-collector  [🔴 NOT BUILT]"
    fi
fi

# Other agents (just check if built)
for agent in web-scraper web-searcher code-assistant trading-twins; do
    case "$agent" in
        web-scraper) binary="web-scraper" ;;
        web-searcher) binary="web-search" ;;
        code-assistant) binary="code-assistant" ;;
        trading-twins) binary="trading-agent" ;;
    esac

    if [ -f "$PROJECT_ROOT/arsenal/ai-agents/$agent/target/release/$binary" ]; then
        echo "⚠ $agent       [🟡 BUILT] Not deployed"
    else
        echo "✗ $agent       [🔴 NOT BUILT]"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AI-MANAGERS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Lead Manager
if check_systemd "lead-manager.service"; then
    if check_port 9015 && check_health "http://localhost:9015/health"; then
        echo "✓ lead-manager    [🟢 RUNNING] Port: 9015"
    else
        echo "⚠ lead-manager    [🟡 STARTED] Port: 9015 (not healthy)"
    fi
else
    if [ -f "$PROJECT_ROOT/arsenal/ai-managers/lead-manager/target/release/lead-manager" ]; then
        echo "⚠ lead-manager    [🟡 BUILT] Not deployed"
    else
        echo "✗ lead-manager    [🔴 NOT BUILT]"
    fi
fi

# Database Manager
if check_systemd "database-manager.service" 2>/dev/null; then
    if check_port 9012; then
        echo "✓ database-manager [🟢 RUNNING] Port: 9012"
    else
        echo "⚠ database-manager [🟡 STARTED] Port: 9012"
    fi
else
    if [ -f "$PROJECT_ROOT/arsenal/ai-managers/database-manager/target/release/db-manager" ]; then
        echo "⚠ database-manager [🟡 BUILT] Not deployed (HIGH PRIORITY)"
    else
        echo "✗ database-manager [🔴 NOT BUILT]"
    fi
fi

# Other managers
for manager in prompt-manager service-manager; do
    case "$manager" in
        prompt-manager) binary="prompt-security-controller"; port="9001" ;;
        service-manager) binary="service-manager"; port="9000" ;;
    esac

    if [ -f "$PROJECT_ROOT/arsenal/ai-managers/$manager/target/release/$binary" ]; then
        echo "⚠ $manager       [🟡 BUILT] Not deployed"
    else
        echo "✗ $manager       [🔴 NOT BUILT]"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AUTOMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Daily scraper timer
if systemctl --user is-enabled lead-scraper-daily.timer >/dev/null 2>&1; then
    echo "✓ Daily Scraper   [🟢 ENABLED] Runs at 9 AM"
else
    echo "⚠ Daily Scraper   [🔴 DISABLED]"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count services
running=$(systemctl --user list-units --type=service --state=running | grep -cE '(lead|surreal|llama)' || echo "0")
enabled=$(systemctl --user list-unit-files --type=service --state=enabled | grep -cE '(lead|surreal|llama)' || echo "0")

# Count ports listening
ports_listening=$(ss -tlnp 2>/dev/null | grep -cE '(8000|9013|9014|9015|11435)' || echo "0")

echo "Services Running:    $running"
echo "Services Enabled:    $enabled"
echo "Ports Listening:     $ports_listening/5"
echo ""

# Overall health
if [ "$running" -ge 5 ] && [ "$ports_listening" -ge 5 ]; then
    echo "Overall Status:      🟢 HEALTHY"
    echo ""
    echo "✓ Lead generation system is fully operational"
elif [ "$running" -ge 3 ]; then
    echo "Overall Status:      🟡 PARTIAL"
    echo ""
    echo "⚠ Some services are not running"
    echo "  Run: $PROJECT_ROOT/bin/lead-system/start-lead-system.sh"
else
    echo "Overall Status:      🔴 DOWN"
    echo ""
    echo "✗ System is not operational"
    echo "  Run: $PROJECT_ROOT/bin/lead-system/start-lead-system.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUICK COMMANDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Start system:     $PROJECT_ROOT/bin/lead-system/start-lead-system.sh"
echo "Stop system:      $PROJECT_ROOT/bin/lead-system/stop-lead-system.sh"
echo "Test system:      $PROJECT_ROOT/bin/lead-system/quick-test.sh"
echo "Scrape leads:     $PROJECT_ROOT/bin/lead-system/scrape-leads.sh all 30"
echo "Daily digest:     $PROJECT_ROOT/bin/lead-system/daily-digest.sh"
echo "View logs:        journalctl --user -u lead-manager -f"
echo ""
echo "Full audit:       cat $PROJECT_ROOT/docs/SYSTEM_AUDIT.md"
echo "═══════════════════════════════════════════════════════"
