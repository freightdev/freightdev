#!/bin/bash

# Distributed Aider Setup
# This script helps you run aider with load-balanced Ollama instances

# ============================================
# CONFIGURATION
# ============================================

# Define your laptop IPs (change these to your actual IPs)
LAPTOP_IPS=(
    "192.168.12.138"  #* Laptop Workbox
    "192.168.12.106"  #* Laptop Hostbox
    "192.168.12.66"  #* Laptop Helpbox
    "192.168.12.9"  #* Laptop Callbox
)

OLLAMA_PORT="11434" #* Port 11434
LOCAL_OLLAMA="http://localhost:11434"

# ============================================
# FUNCTIONS
# ============================================

check_ollama() {
    local host=$1
    if curl -s -o /dev/null -w "%{http_code}" "$host/api/tags" | grep -q "200"; then
        return 0
    else
        return 1
    fi
}

find_available_ollama() {
    echo "🔍 Checking for available Ollama instances..."

    # Check local first
    if check_ollama "$LOCAL_OLLAMA"; then
        echo "✅ Local Ollama available: $LOCAL_OLLAMA"
        echo "$LOCAL_OLLAMA"
        return 0
    fi

    # Check remote laptops
    for ip in "${LAPTOP_IPS[@]}"; do
        remote_url="http://${ip}:${OLLAMA_PORT}"
        if check_ollama "$remote_url"; then
            echo "✅ Remote Ollama available: $remote_url"
            echo "$remote_url"
            return 0
        fi
    done

    echo "❌ No Ollama instances available!"
    return 1
}

list_all_ollama_status() {
    echo ""
    echo "📊 Ollama Instance Status:"
    echo "=========================="

    # Check local
    echo -n "Local (localhost): "
    if check_ollama "$LOCAL_OLLAMA"; then
        echo "✅ Online"
    else
        echo "❌ Offline"
    fi

    # Check all remote
    for ip in "${LAPTOP_IPS[@]}"; do
        remote_url="http://${ip}:${OLLAMA_PORT}"
        echo -n "Remote ($ip): "
        if check_ollama "$remote_url"; then
            echo "✅ Online"
        else
            echo "❌ Offline"
        fi
    done
    echo ""
}

show_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║   DISTRIBUTED AIDER SETUP MENU        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    list_all_ollama_status
    echo "What do you want to do?"
    echo ""
    echo "1) Start Aider (auto-select best Ollama)"
    echo "2) Start Aider with specific Ollama host"
    echo "3) Check all Ollama instances"
    echo "4) Configure new project"
    echo "5) Edit laptop IPs"
    echo "6) Show Aider tips"
    echo "7) Exit"
    echo ""
    read -p "Choose an option: " choice
}

start_aider_auto() {
    ollama_host=$(find_available_ollama)
    if [ $? -eq 0 ]; then
        echo ""
        echo "🚀 Starting Aider with: $ollama_host"
        echo ""
        export OLLAMA_API_BASE="$ollama_host"
        
        # Check if we're in a git repo
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "⚠️  Not in a git repository. Initialize one? (y/n)"
            read -p "> " init_git
            if [[ $init_git == "y" ]]; then
                git init
                echo "✅ Git repository initialized"
            fi
        fi
        
        # Start aider with recommended settings
        aider \
            --model ollama/deepseek-coder-v2 \
            --no-auto-commits \
            --dark-mode
    else
        echo "Cannot start Aider without Ollama"
        read -p "Press enter to continue..."
    fi
}

start_aider_manual() {
    echo ""
    echo "Available hosts:"
    echo "0) localhost"
    i=1
    for ip in "${LAPTOP_IPS[@]}"; do
        echo "$i) $ip"
        ((i++))
    done
    echo ""
    read -p "Choose host number: " host_choice
    
    if [[ $host_choice == "0" ]]; then
        ollama_host="$LOCAL_OLLAMA"
    else
        idx=$((host_choice - 1))
        ollama_host="http://${LAPTOP_IPS[$idx]}:${OLLAMA_PORT}"
    fi
    
    echo ""
    echo "🚀 Starting Aider with: $ollama_host"
    export OLLAMA_API_BASE="$ollama_host"
    
    aider \
        --model ollama/deepseek-coder-v2 \
        --no-auto-commits \
        --dark-mode
}

configure_project() {
    echo ""
    echo "🔧 Project Configuration Wizard"
    echo "=============================="
    echo ""
    
    read -p "Project name: " project_name
    read -p "Project directory (or . for current): " project_dir
    
    if [[ $project_dir != "." ]]; then
        mkdir -p "$project_dir"
        cd "$project_dir" || exit
    fi
    
    # Initialize git if not exists
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        git init
        echo "✅ Git initialized"
    fi
    
    # Create .aider.conf.yml
    cat > .aider.conf.yml << EOF
# Aider configuration for: $project_name
model: ollama/deepseek-coder-v2
dark-mode: true
no-auto-commits: true
edit-format: diff
show-diffs: true
EOF
    
    echo "✅ Created .aider.conf.yml"
    echo ""
    echo "Project configured! You can now run aider in this directory."
    read -p "Press enter to continue..."
}

edit_ips() {
    echo ""
    echo "Current laptop IPs:"
    for i in "${!LAPTOP_IPS[@]}"; do
        echo "$((i+1)). ${LAPTOP_IPS[$i]}"
    done
    echo ""
    echo "Edit this script to change IPs: $0"
    echo "Look for the LAPTOP_IPS array at the top"
    read -p "Press enter to continue..."
}

show_tips() {
    clear
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                    AIDER TIPS & TRICKS                     ║
╚═══════════════════════════════════════════════════════════╝

📚 WHAT AIDER CAN DO:
━━━━━━━━━━━━━━━━━━━━━
• Write new code files from scratch
• Refactor existing code
• Fix bugs by reading error messages
• Add features to your project
• Update multiple files at once
• Search through documentation (if you paste it)
• Explain code and suggest improvements

🎯 HOW TO USE AIDER:
━━━━━━━━━━━━━━━━━━
1. Start aider in your project directory
2. Add files to context: /add filename.py
3. Ask it to code: "add a login function to auth.py"
4. Review changes, accept or reject
5. Repeat!

💡 BEST PRACTICES:
━━━━━━━━━━━━━━━━
• Work in git repos (aider uses commits)
• Add only relevant files to context
• Be specific in requests
• Review diffs before accepting
• Use /help to see all commands

🔧 USEFUL COMMANDS:
━━━━━━━━━━━━━━━━
/add <file>     - Add file to chat
/drop <file>    - Remove file from chat
/ls            - List files in chat
/diff          - Show pending changes
/undo          - Undo last change
/commit        - Commit changes
/help          - Show all commands
/quit          - Exit aider

🌐 DISTRIBUTED SETUP:
━━━━━━━━━━━━━━━━━━
Your setup will:
1. Try local Ollama first (fastest)
2. Fall back to remote laptops if needed
3. Each aider instance is independent
4. Share code via git, not aider-to-aider

💭 AIDER'S "SOURCE OF TRUTH":
━━━━━━━━━━━━━━━━━━━━━━━━━
• YOUR CODE FILES (it reads and edits them)
• Git history (it uses commits)
• Files you add to context (/add)
• Your instructions in the chat

⚠️  WHAT AIDER IS NOT:
━━━━━━━━━━━━━━━━━━━━
❌ Not a file watcher (use entr, watchman, etc.)
❌ Not a terminal helper (use LLM CLI tools)
❌ Not a multi-agent system (each is independent)
❌ Not a project manager (use git + your brain)

EOF
    read -p "Press enter to continue..."
}

# ============================================
# MAIN LOOP
# ============================================

while true; do
    show_menu
    
    case $choice in
        1) start_aider_auto ;;
        2) start_aider_manual ;;
        3) list_all_ollama_status; read -p "Press enter to continue..." ;;
        4) configure_project ;;
        5) edit_ips ;;
        6) show_tips ;;
        7) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
