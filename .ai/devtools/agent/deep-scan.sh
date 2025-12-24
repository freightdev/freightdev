#!/bin/bash
# Deep Scan of AI Agency Forge
# Comprehensive analysis of codebase structure, completeness, and issues

AGENT_ROOT="/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo"
SCAN_FILE="$AGENCY_ROOT/_meta/deep-scan.$(date +%Y%m%d-%H%M%S).md"

echo "Starting deep scan..."
echo "Output will be written to: $SCAN_FILE"

cat > "$SCAN_FILE" << 'SCAN_HEADER'
# AI Agency Forge - Deep Scan Report

**Date:** $(date)
**Scanned by:** CoDriver (Builder)
**Trigger:** Meta CoDriver architecture review

## Executive Summary

Scanning entire agency-forge codebase for:
- Agent completeness
- Communication protocols
- Configuration files
- Dependencies
- Missing functionality
- Integration points

---

SCAN_HEADER

# Add timestamp
echo "" >> "$SCAN_FILE"
echo "Generated: $(date)" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

# Count files
echo "## File Inventory" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"
echo "- Rust source files: $(find "$AGENCY_ROOT" -name "*.rs" -not -path "*/target/*" | wc -l)" >> "$SCAN_FILE"
echo "- Python files: $(find "$AGENCY_ROOT" -name "*.py" -not -path "*/target/*" | wc -l)" >> "$SCAN_FILE"
echo "- Cargo.toml files: $(find "$AGENCY_ROOT" -name "Cargo.toml" -not -path "*/target/*" | wc -l)" >> "$SCAN_FILE"
echo "- Proto files: $(find "$AGENCY_ROOT" -name "*.proto" 2>/dev/null | wc -l)" >> "$SCAN_FILE"
echo "- Config files: $(find "$AGENCY_ROOT" -name "config.toml" -o -name "config.yaml" 2>/dev/null | wc -l)" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

# Check agents
echo "## Agent Inventory" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"
echo "### Arsenal Agents" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

for agent_dir in "$AGENCY_ROOT/arsenal/ai-agents/"*/; do
    if [ -d "$agent_dir" ]; then
        agent_name=$(basename "$agent_dir")
        echo "#### $agent_name" >> "$SCAN_FILE"

        # Check for Cargo.toml
        if [ -f "$agent_dir/Cargo.toml" ]; then
            echo "- ✅ Cargo.toml exists" >> "$SCAN_FILE"

            # Check if built
            if [ -f "$agent_dir/target/release/$agent_name" ]; then
                size=$(du -h "$agent_dir/target/release/$agent_name" | cut -f1)
                echo "- ✅ Binary built: $size" >> "$SCAN_FILE"
            else
                echo "- ❌ Binary not built" >> "$SCAN_FILE"
            fi
        else
            echo "- ❌ No Cargo.toml" >> "$SCAN_FILE"
        fi

        # Check for Python
        if [ -f "$agent_dir/requirements.txt" ] || [ -f "$agent_dir/pyproject.toml" ]; then
            echo "- ✅ Python dependencies declared" >> "$SCAN_FILE"
        fi

        # Check for config
        if [ -f "$agent_dir/config.toml" ] || [ -f "$agent_dir/config.yaml" ]; then
            echo "- ✅ Config file exists" >> "$SCAN_FILE"
        else
            echo "- ⚠️  No config file" >> "$SCAN_FILE"
        fi

        # Check for tools directory
        if [ -d "$agent_dir/tools" ]; then
            tool_count=$(ls "$agent_dir/tools" 2>/dev/null | wc -l)
            echo "- ✅ Tools directory ($tool_count files)" >> "$SCAN_FILE"
        else
            echo "- ⚠️  No tools directory" >> "$SCAN_FILE"
        fi

        # Check for README
        if [ -f "$agent_dir/README.md" ]; then
            echo "- ✅ README exists" >> "$SCAN_FILE"
        else
            echo "- ⚠️  No README" >> "$SCAN_FILE"
        fi

        echo "" >> "$SCAN_FILE"
    fi
done

# Check core services
echo "### Core Services" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

for service_dir in "$AGENCY_ROOT/core/"*/; do
    if [ -d "$service_dir" ]; then
        service_name=$(basename "$service_dir")
        echo "#### $service_name" >> "$SCAN_FILE"

        if [ -f "$service_dir/Cargo.toml" ]; then
            echo "- ✅ Cargo.toml exists" >> "$SCAN_FILE"

            if [ -f "$service_dir/target/release/$service_name" ]; then
                size=$(du -h "$service_dir/target/release/$service_name" 2>/dev/null | cut -f1)
                echo "- ✅ Binary built: $size" >> "$SCAN_FILE"
            else
                echo "- ❌ Binary not built" >> "$SCAN_FILE"
            fi
        fi

        echo "" >> "$SCAN_FILE"
    fi
done

# Check for protobuf
echo "## Communication Protocols" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

proto_count=$(find "$AGENCY_ROOT" -name "*.proto" 2>/dev/null | wc -l)
if [ "$proto_count" -gt 0 ]; then
    echo "- ✅ Found $proto_count .proto files" >> "$SCAN_FILE"
    find "$AGENCY_ROOT" -name "*.proto" 2>/dev/null | while read proto; do
        echo "  - $(basename $proto)" >> "$SCAN_FILE"
    done
else
    echo "- ❌ No .proto files found (currently using JSON/HTTP)" >> "$SCAN_FILE"
fi
echo "" >> "$SCAN_FILE"

# Check for binary deps
echo "### Binary Protocol Dependencies" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"
echo "Checking Cargo.toml files for:" >> "$SCAN_FILE"
echo "- prost (protobuf)" >> "$SCAN_FILE"
echo "- tonic (gRPC)" >> "$SCAN_FILE"
echo "- rmp-serde (messagepack)" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

find "$AGENCY_ROOT" -name "Cargo.toml" -not -path "*/target/*" | while read cargo; do
    if grep -q "prost\|tonic\|rmp-serde" "$cargo" 2>/dev/null; then
        echo "- ✅ $(dirname $cargo | sed "s|$AGENCY_ROOT/||") uses binary protocol" >> "$SCAN_FILE"
    fi
done

echo "" >> "$SCAN_FILE"

# Check Ollama integration
echo "## Ollama Integration" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

ollama_refs=$(grep -r "11434\|ollama" "$AGENCY_ROOT" --include="*.rs" --include="*.py" -l 2>/dev/null | grep -v target | wc -l)
echo "- Files referencing Ollama: $ollama_refs" >> "$SCAN_FILE"

# Check for ollama cluster script
if [ -f "$AGENCY_ROOT/arsenal/ai-commands/ollama-cluster.py" ]; then
    echo "- ✅ ollama-cluster.py exists" >> "$SCAN_FILE"
else
    echo "- ❌ ollama-cluster.py missing" >> "$SCAN_FILE"
fi

echo "" >> "$SCAN_FILE"

# Check web search capability
echo "## Web Search Capability" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

if [ -d "$AGENCY_ROOT/arsenal/ai-agents/web-search" ]; then
    echo "- ✅ web-search agent exists" >> "$SCAN_FILE"
    if grep -q "duckduckgo\|search" "$AGENCY_ROOT/arsenal/ai-agents/web-search/src/main.rs" 2>/dev/null; then
        echo "- ✅ Search functionality implemented" >> "$SCAN_FILE"
    fi
else
    echo "- ❌ web-search agent missing" >> "$SCAN_FILE"
fi

echo "" >> "$SCAN_FILE"

# Check TODOs
echo "## TODOs and Incomplete Items" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

todo_count=$(grep -r "TODO\|FIXME\|XXX" "$AGENCY_ROOT" --include="*.rs" --include="*.py" 2>/dev/null | grep -v target | wc -l)
echo "- Found $todo_count TODO/FIXME/XXX comments" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"

if [ "$todo_count" -lt 50 ]; then
    grep -r "TODO\|FIXME\|XXX" "$AGENCY_ROOT" --include="*.rs" --include="*.py" 2>/dev/null | grep -v target | head -20 | while read line; do
        echo "  - $line" >> "$SCAN_FILE"
    done
else
    echo "  (Too many to list - check manually)" >> "$SCAN_FILE"
fi

echo "" >> "$SCAN_FILE"

# Summary
echo "## Scan Complete" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"
echo "Report generated: $(date)" >> "$SCAN_FILE"
echo "Next: Review findings and create fix plan" >> "$SCAN_FILE"

echo "Scan complete. Report written to: $SCAN_FILE"
