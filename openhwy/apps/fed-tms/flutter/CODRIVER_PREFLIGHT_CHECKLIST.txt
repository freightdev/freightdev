╔══════════════════════════════════════════════════════════════════════════════╗
║                    CODRIVER AGENCY PRE-FLIGHT CHECKLIST                      ║
║                   Run this BEFORE starting anything tomorrow                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

YOU ARE SO CLOSE. DON'T FUCK IT UP BY RUSHING.

This checklist ensures all paths are correct before you start services.

═══════════════════════════════════════════════════════════════════════════════
                         STEP 1: VERIFY DIRECTORY STRUCTURE
═══════════════════════════════════════════════════════════════════════════════

Run these commands to verify everything is where it should be:

# 1. Verify .codriver.d exists
ls -la ~/.codriver.d 2>/dev/null && echo "✓ .codriver.d found" || echo "✗ .codriver.d MISSING"

# 2. Verify bin/ directory
ls -la ~/.codriver.d/bin 2>/dev/null && echo "✓ bin/ found" || echo "✗ bin/ MISSING"

# 3. Verify etc/ configs
ls -la ~/.codriver.d/etc/agentd/*.yaml 2>/dev/null && echo "✓ configs found" || echo "✗ configs MISSING"

# 4. Verify systemd services
ls -la ~/.codriver.d/etc/systemd/*.service 2>/dev/null && echo "✓ systemd services found" || echo "✗ systemd services MISSING"

# 5. Verify srv/ directory
ls -la ~/.codriver.d/srv 2>/dev/null && echo "✓ srv/ found" || echo "✗ srv/ MISSING"

# 6. Verify var/ runtime directories
ls -la ~/.codriver.d/var/{data,logs,runtime,state} 2>/dev/null && echo "✓ var/ directories found" || echo "✗ var/ directories MISSING"

# 7. Verify src/ in workspace
ls -la ~/WORKSPACE/.ranger/src 2>/dev/null && echo "✓ src/ found" || echo "✗ src/ MISSING"


═══════════════════════════════════════════════════════════════════════════════
                         STEP 2: CHECK ALL HARD-CODED PATHS
═══════════════════════════════════════════════════════════════════════════════

These are the most common path issues. Check each one:

# Check systemd service paths
echo "Checking systemd service paths..."
grep -r "ExecStart=" ~/.codriver.d/etc/systemd/*.service 2>/dev/null | while read line; do
    path=$(echo "$line" | grep -oP 'ExecStart=\K[^ ]+')
    if [ -f "$path" ] || [ -f "${path%% *}" ]; then
        echo "✓ $path exists"
    else
        echo "✗ $path MISSING"
    fi
done

# Check config file paths
echo ""
echo "Checking config file references..."
grep -r "path:" ~/.codriver.d/etc/agentd/*.yaml 2>/dev/null | grep -v "^#" | while read line; do
    # Extract path value (basic grep, may need adjustment)
    echo "Config reference: $line"
done

# Check Python script paths
echo ""
echo "Checking Python script paths..."
find ~/.codriver.d/srv -name "*.py" -type f 2>/dev/null | while read script; do
    # Check if script references absolute paths
    if grep -q "/home/" "$script" 2>/dev/null; then
        echo "⚠ $script contains hard-coded /home/ paths"
    fi
done

# Check Rust binary paths
echo ""
echo "Checking Rust binary locations..."
find ~/WORKSPACE/.ranger/src -name "Cargo.toml" -type f 2>/dev/null | while read cargo; do
    dir=$(dirname "$cargo")
    name=$(basename "$dir")
    if [ -f "$dir/target/release/$name" ] || [ -f "$dir/target/debug/$name" ]; then
        echo "✓ Binary for $name exists"
    else
        echo "⚠ Binary for $name NOT BUILT"
    fi
done


═══════════════════════════════════════════════════════════════════════════════
                         STEP 3: VERIFY ENVIRONMENT VARIABLES
═══════════════════════════════════════════════════════════════════════════════

# Check if .env files exist
echo "Checking .env files..."
find ~/.codriver.d/srv -name ".env" -o -name ".env.example" 2>/dev/null | while read env; do
    if [ -f "$env" ]; then
        echo "✓ Found: $env"
        # Check if it has required variables
        if [ "$(basename $env)" = ".env.example" ]; then
            actual_env="${env%.example}"
            if [ ! -f "$actual_env" ]; then
                echo "  ⚠ Missing actual .env file: $actual_env"
                echo "  → Run: cp $env $actual_env"
            fi
        fi
    fi
done

# Check coordinator .env
if [ -f ~/WORKSPACE/.ranger/src/coordinator/.env ]; then
    echo "✓ Coordinator .env exists"
else
    echo "✗ Coordinator .env MISSING"
    echo "  → Run: cp ~/WORKSPACE/.ranger/src/coordinator/.env.example ~/WORKSPACE/.ranger/src/coordinator/.env"
fi


═══════════════════════════════════════════════════════════════════════════════
                         STEP 4: VERIFY DEPENDENCIES
═══════════════════════════════════════════════════════════════════════════════

# Check Rust installed
if command -v cargo &> /dev/null; then
    echo "✓ Rust installed: $(cargo --version)"
else
    echo "✗ Rust NOT INSTALLED"
fi

# Check Go installed
if command -v go &> /dev/null; then
    echo "✓ Go installed: $(go version)"
else
    echo "✗ Go NOT INSTALLED"
fi

# Check Python installed
if command -v python3 &> /dev/null; then
    echo "✓ Python installed: $(python3 --version)"
else
    echo "✗ Python NOT INSTALLED"
fi

# Check SurrealDB
if command -v surreal &> /dev/null; then
    echo "✓ SurrealDB installed: $(surreal version 2>/dev/null | head -1)"
else
    echo "✗ SurrealDB NOT INSTALLED"
fi

# Check Ollama
if command -v ollama &> /dev/null; then
    echo "✓ Ollama installed"
else
    echo "⚠ Ollama not found in PATH (may be Docker)"
fi


═══════════════════════════════════════════════════════════════════════════════
                         STEP 5: CHECK DATABASE
═══════════════════════════════════════════════════════════════════════════════

# Check if SurrealDB data exists
if [ -d ~/.codriver.d/var/data/surrealdb ]; then
    echo "✓ SurrealDB data directory exists"
    ls -lh ~/.codriver.d/var/data/surrealdb
else
    echo "✗ SurrealDB data directory MISSING"
fi

# Check if database is initialized
if [ -f ~/.codriver.d/etc/agentd/init-db.surql ]; then
    echo "✓ Database init script exists"
else
    echo "⚠ Database init script missing"
fi


═══════════════════════════════════════════════════════════════════════════════
                         STEP 6: VERIFY BUILD STATUS
═══════════════════════════════════════════════════════════════════════════════

# Count Rust projects
rust_projects=$(find ~/WORKSPACE/.ranger/src -name "Cargo.toml" -type f 2>/dev/null | wc -l)
echo "Found $rust_projects Rust projects"

# Count built binaries
built_binaries=$(find ~/WORKSPACE/.ranger/src -path "*/target/release/*" -type f -executable 2>/dev/null | wc -l)
echo "Found $built_binaries built release binaries"

# Count Go projects
go_projects=$(find ~/.codriver.d/srv -name "go.mod" -type f 2>/dev/null | wc -l)
echo "Found $go_projects Go projects"


═══════════════════════════════════════════════════════════════════════════════
                         STEP 7: CHECK SYSTEMD SERVICES
═══════════════════════════════════════════════════════════════════════════════

# List all systemd services
echo "Systemd services found:"
ls -1 ~/.codriver.d/etc/systemd/*.service 2>/dev/null | while read service; do
    name=$(basename "$service")
    echo "  - $name"
done

# Check if any are enabled/active (if using systemd --user)
if command -v systemctl &> /dev/null; then
    echo ""
    echo "Checking systemd --user services..."
    systemctl --user list-units 'codriver-*' 'lead-*' 'trucking-*' 'housing-*' 2>/dev/null || echo "  (No active systemd --user services)"
fi


═══════════════════════════════════════════════════════════════════════════════
                         STEP 8: VERIFY PORTS
═══════════════════════════════════════════════════════════════════════════════

# Expected ports (adjust if needed)
declare -A expected_ports=(
    ["coordinator"]=9999
    ["api-gateway"]=8080
    ["auth-service"]=8081
    ["email-service"]=8082
    ["payment-service"]=8083
    ["user-service"]=8084
    ["surrealdb"]=8000
    ["ollama"]=11434
)

echo "Checking if ports are in use..."
for service in "${!expected_ports[@]}"; do
    port=${expected_ports[$service]}
    if lsof -i :$port &> /dev/null || ss -tuln | grep -q ":$port "; then
        echo "⚠ Port $port ($service) is already in use"
    else
        echo "✓ Port $port ($service) is available"
    fi
done


═══════════════════════════════════════════════════════════════════════════════
                         STEP 9: CHECK LOGS DIRECTORY
═══════════════════════════════════════════════════════════════════════════════

# Verify logs directory is writable
if [ -d ~/.codriver.d/var/logs ]; then
    if [ -w ~/.codriver.d/var/logs ]; then
        echo "✓ Logs directory is writable"
    else
        echo "✗ Logs directory is NOT writable"
    fi
else
    echo "✗ Logs directory MISSING"
    echo "  → Run: mkdir -p ~/.codriver.d/var/logs"
fi


═══════════════════════════════════════════════════════════════════════════════
                         STEP 10: CHECK PID FILES
═══════════════════════════════════════════════════════════════════════════════

# Check if old PID files exist
if [ -d ~/.codriver.d/var/runtime/pids ]; then
    pid_count=$(ls -1 ~/.codriver.d/var/runtime/pids/*.pid 2>/dev/null | wc -l)
    if [ $pid_count -gt 0 ]; then
        echo "⚠ Found $pid_count old PID files"
        echo "  These processes may still be running:"
        ls -1 ~/.codriver.d/var/runtime/pids/*.pid 2>/dev/null | while read pidfile; do
            pid=$(cat "$pidfile" 2>/dev/null)
            name=$(basename "$pidfile" .pid)
            if ps -p $pid &> /dev/null; then
                echo "    ✓ $name (PID $pid) is RUNNING"
            else
                echo "    ✗ $name (PID $pid) is DEAD (stale PID file)"
            fi
        done
        echo ""
        echo "  Clean up stale PIDs before starting:"
        echo "  → Run: rm ~/.codriver.d/var/runtime/pids/*.pid"
    else
        echo "✓ No old PID files (clean start)"
    fi
else
    echo "✗ PID directory MISSING"
    echo "  → Run: mkdir -p ~/.codriver.d/var/runtime/pids"
fi


═══════════════════════════════════════════════════════════════════════════════
                         STEP 11: GENERATE FIX SCRIPT
═══════════════════════════════════════════════════════════════════════════════

This will generate a script to fix common path issues.

# Create fix script
cat > ~/WORKSPACE/.ranger/fix-paths.sh << 'FIXSCRIPT'
#!/bin/bash
# Auto-generated path fix script

echo "Fixing common path issues..."

# Fix 1: Create missing directories
mkdir -p ~/.codriver.d/{bin,etc,srv,var/{data,logs,runtime/pids,state}}
echo "✓ Created missing directories"

# Fix 2: Copy .env.example to .env files
find ~/.codriver.d/srv -name ".env.example" | while read example; do
    actual="${example%.example}"
    if [ ! -f "$actual" ]; then
        cp "$example" "$actual"
        echo "✓ Created $actual"
    fi
done

# Fix 3: Make scripts executable
find ~/WORKSPACE/.ranger -name "*.sh" -type f -exec chmod +x {} \;
echo "✓ Made scripts executable"

# Fix 4: Clean stale PID files
if [ -d ~/.codriver.d/var/runtime/pids ]; then
    find ~/.codriver.d/var/runtime/pids -name "*.pid" | while read pidfile; do
        pid=$(cat "$pidfile" 2>/dev/null)
        if ! ps -p $pid &> /dev/null; then
            rm "$pidfile"
            echo "✓ Removed stale PID: $(basename $pidfile)"
        fi
    done
fi

echo ""
echo "Path fixes complete!"
FIXSCRIPT

chmod +x ~/WORKSPACE/.ranger/fix-paths.sh
echo "✓ Generated fix script: ~/WORKSPACE/.ranger/fix-paths.sh"
echo "  Run it with: ~/WORKSPACE/.ranger/fix-paths.sh"


═══════════════════════════════════════════════════════════════════════════════
                         STEP 12: FINAL CHECKLIST
═══════════════════════════════════════════════════════════════════════════════

Before starting services tomorrow, verify:

□ All directories exist
□ All configs have correct paths
□ All .env files created from .env.example
□ All Rust projects built (cargo build --release)
□ All Go services built (go build)
□ SurrealDB data directory exists
□ No processes using required ports
□ No stale PID files
□ Logs directory is writable
□ All scripts are executable

If ANY of these fail, run fix-paths.sh first.


═══════════════════════════════════════════════════════════════════════════════
                         TESTING ORDER (TOMORROW)
═══════════════════════════════════════════════════════════════════════════════

When you're ready to test tomorrow, start services in this order:

1. SurrealDB
   → Start first, wait for it to be ready
   → Verify: curl http://localhost:8000/health

2. Coordinator
   → The brain that orchestrates everything
   → Verify: curl http://localhost:9999/health

3. Microservices (auth, email, payment, user)
   → Start all Go services
   → Verify each with curl

4. API Gateway
   → Routes requests to services
   → Verify: curl http://localhost:8080/health

5. Wheeler Agents
   → Start individual agents one by one
   → Monitor logs for errors

6. Test end-to-end
   → Send test command through API gateway
   → Watch it route through coordinator to agents


═══════════════════════════════════════════════════════════════════════════════
                         SAVE THIS CHECKLIST
═══════════════════════════════════════════════════════════════════════════════

Tomorrow morning:

1. cd ~/WORKSPACE/.ranger
2. Run this checklist (copy to checklist.sh)
3. Run fix-paths.sh if needed
4. Build any missing binaries
5. Start services in order
6. Test thoroughly
7. Document any issues

You're SO CLOSE. Don't rush it.

═══════════════════════════════════════════════════════════════════════════════

Run this entire checklist now. Fix issues tonight. Test tomorrow.

🚛 You got this.
