#!/bin/bash
# Audit all components in agency-forge

cd /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo

echo "=== AI-CORE COMPONENTS ==="
for component in ai-core/*/; do
    if [ -f "$component/Cargo.toml" ]; then
        name=$(basename "$component")
        if [ -f "$component/src/main.rs" ]; then
            if ls "$component/target/release/"* 2>/dev/null | grep -v "\.d$" | grep -q .; then
                echo "🟢 BUILT: $name"
            else
                echo "🟡 SOURCE: $name (not built)"
            fi
        else
            echo "🔴 STUB: $name (no source)"
        fi
    fi
done

echo ""
echo "=== AI-AGENTS ==="
for component in arsenal/ai-agents/*/; do
    if [ -f "$component/Cargo.toml" ]; then
        name=$(basename "$component")
        if [ -f "$component/src/main.rs" ]; then
            if ls "$component/target/release/"* 2>/dev/null | grep -v "\.d$" | grep -q .; then
                echo "🟢 BUILT: $name"
            else
                echo "🟡 SOURCE: $name (not built)"
            fi
        else
            echo "🔴 STUB: $name (no source)"
        fi
    fi
done

echo ""
echo "=== AI-MANAGERS ==="
for component in arsenal/ai-managers/*/; do
    if [ -f "$component/Cargo.toml" ]; then
        name=$(basename "$component")
        if [ -f "$component/src/main.rs" ]; then
            if ls "$component/target/release/"* 2>/dev/null | grep -v "\.d$" | grep -q .; then
                echo "🟢 BUILT: $name"
            else
                echo "🟡 SOURCE: $name (not built)"
            fi
        else
            echo "🔴 STUB: $name (no source)"
        fi
    fi
done

echo ""
echo "=== AI-SERVICES ==="
for component in arsenal/ai-services/*/; do
    if [ -f "$component/Cargo.toml" ]; then
        name=$(basename "$component")
        if [ -f "$component/src/main.rs" ]; then
            if ls "$component/target/release/"* 2>/dev/null | grep -v "\.d$" | grep -q .; then
                echo "🟢 BUILT: $name"
            else
                echo "🟡 SOURCE: $name (not built)"
            fi
        else
            echo "🔴 STUB: $name (no source)"
        fi
    fi
done

echo ""
echo "=== AI-TOOLS ==="
for component in arsenal/ai-tools/*/; do
    if [ -f "$component/Cargo.toml" ]; then
        name=$(basename "$component")
        if [ -f "$component/src/main.rs" ] || [ -f "$component/src/lib.rs" ]; then
            if ls "$component/target/release/"* 2>/dev/null | grep -v "\.d$" | grep -q .; then
                echo "🟢 BUILT: $name"
            else
                echo "🟡 SOURCE: $name (not built)"
            fi
        else
            echo "🔴 STUB: $name (no source)"
        fi
    fi
done
