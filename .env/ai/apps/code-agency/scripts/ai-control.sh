#!/bin/bash
# AI Multi-Agent System Control Script

SHARED_ROOT="$HOME/shared"
WORKSPACE="$SHARED_ROOT/ai-workspace"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

show_help() {
    echo -e "${BOLD}AI Multi-Agent System Control${RESET}"
    echo ""
    echo "Usage: ai-control <command>"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}status${RESET}           Show status of all agents"
    echo -e "  ${GREEN}start <agent>${RESET}    Start an agent worker"
    echo -e "  ${GREEN}stop <agent>${RESET}     Stop an agent worker"
    echo -e "  ${GREEN}restart <agent>${RESET}  Restart an agent worker"
    echo -e "  ${GREEN}logs <agent>${RESET}     Show logs for an agent"
    echo -e "  ${GREEN}jobs${RESET}             List all jobs"
    echo -e "  ${GREEN}clean${RESET}            Clean up old logs and completed jobs"
    echo -e "  ${GREEN}test${RESET}             Test Ollama connections"
    echo -e "  ${GREEN}backup${RESET}           Backup workspace"
    echo -e "  ${GREEN}restore${RESET}          Restore workspace from backup"
    echo ""
}

get_agents() {
    grep -E "^  [a-z]" "$SHARED_ROOT/configs/machines.yaml" | sed 's/:$//' | sed 's/^  //'
}

check_agent_status() {
    local agent=$1
    local pid=$(pgrep -f "worker.py $agent")
    
    if [ -n "$pid" ]; then
        echo -e "${GREEN}●${RESET} RUNNING (PID: $pid)"
    else
        echo -e "${RED}●${RESET} STOPPED"
    fi
}

show_status() {
    echo -e "${BOLD}${CYAN}Agent Status:${RESET}\n"
    
    while IFS= read -r agent; do
        printf "  %-20s " "$agent"
        check_agent_status "$agent"
    done < <(get_agents)
    
    echo ""
    echo -e "${BOLD}${CYAN}Recent Activity:${RESET}"
    
    if [ -f "$WORKSPACE/logs/ping.log" ]; then
        tail -5 "$WORKSPACE/logs/ping.log" | while read line; do
            echo "  $line"
        done
    else
        echo -e "  ${YELLOW}No ping log found${RESET}"
    fi
}

start_agent() {
    local agent=$1
    
    if [ -z "$agent" ]; then
        echo -e "${RED}Error: Agent name required${RESET}"
        echo "Available agents:"
        get_agents | sed 's/^/  - /'
        exit 1
    fi
    
    # Check if already running
    if pgrep -f "worker.py $agent" > /dev/null; then
        echo -e "${YELLOW}Agent $agent is already running${RESET}"
        exit 1
    fi
    
    echo -e "${GREEN}Starting agent: $agent${RESET}"
    nohup python3 "$SHARED_ROOT/scripts/worker.py" "$agent" >> "$WORKSPACE/logs/${agent}.log" 2>&1 &
    echo "Started with PID: $!"
}

stop_agent() {
    local agent=$1
    
    if [ -z "$agent" ]; then
        echo -e "${RED}Error: Agent name required${RESET}"
        exit 1
    fi
    
    local pid=$(pgrep -f "worker.py $agent")
    
    if [ -z "$pid" ]; then
        echo -e "${YELLOW}Agent $agent is not running${RESET}"
        exit 1
    fi
    
    echo -e "${YELLOW}Stopping agent: $agent (PID: $pid)${RESET}"
    kill -TERM $pid
    
    # Wait for graceful shutdown
    sleep 2
    
    if pgrep -f "worker.py $agent" > /dev/null; then
        echo -e "${RED}Agent didn't stop gracefully, forcing...${RESET}"
        kill -KILL $pid
    fi
    
    echo -e "${GREEN}Agent stopped${RESET}"
}

restart_agent() {
    local agent=$1
    stop_agent "$agent"
    sleep 1
    start_agent "$agent"
}

show_logs() {
    local agent=$1
    
    if [ -z "$agent" ]; then
        echo -e "${YELLOW}Showing system logs:${RESET}"
        tail -f "$WORKSPACE/logs/system.log"
    else
        if [ -f "$WORKSPACE/logs/${agent}.log" ]; then
            echo -e "${YELLOW}Showing logs for: $agent${RESET}"
            tail -f "$WORKSPACE/logs/${agent}.log"
        else
            echo -e "${RED}No logs found for agent: $agent${RESET}"
        fi
    fi
}

list_jobs() {
    echo -e "${BOLD}${CYAN}Job Queue:${RESET}\n"
    
    for status_dir in queue active completed; do
        local jobs_path="$WORKSPACE/jobs/$status_dir"
        
        if [ -d "$jobs_path" ] && [ "$(ls -A $jobs_path 2>/dev/null)" ]; then
            echo -e "${BOLD}${status_dir^^}:${RESET}"
            
            for job_file in "$jobs_path"/*.yaml; do
                [ -f "$job_file" ] || continue
                
                local job_id=$(basename "$job_file" .yaml)
                local title=$(grep "^title:" "$job_file" | cut -d'"' -f2)
                local assigned=$(grep "^assigned_to:" "$job_file" | awk '{print $2}')
                
                if [ "$status_dir" = "completed" ]; then
                    echo -e "  ${GREEN}●${RESET} $job_id: $title"
                elif [ "$status_dir" = "active" ]; then
                    echo -e "  ${BLUE}●${RESET} $job_id: $title (assigned: $assigned)"
                else
                    echo -e "  ${YELLOW}●${RESET} $job_id: $title"
                fi
            done
            echo ""
        fi
    done
}

clean_workspace() {
    echo -e "${YELLOW}Cleaning workspace...${RESET}\n"
    
    # Archive old logs
    if [ -f "$WORKSPACE/logs/system.log" ]; then
        local size=$(stat -f%z "$WORKSPACE/logs/system.log" 2>/dev/null || stat -c%s "$WORKSPACE/logs/system.log")
        if [ "$size" -gt 10485760 ]; then # 10MB
            echo "Archiving system.log..."
            gzip -c "$WORKSPACE/logs/system.log" > "$WORKSPACE/logs/system.log.$(date +%Y%m%d).gz"
            > "$WORKSPACE/logs/system.log"
        fi
    fi
    
    # Clean old error logs
    if [ -f "$WORKSPACE/logs/error.log" ]; then
        echo "Cleaning error.log (keeping last 1000 lines)..."
        tail -1000 "$WORKSPACE/logs/error.log" > "$WORKSPACE/logs/error.log.tmp"
        mv "$WORKSPACE/logs/error.log.tmp" "$WORKSPACE/logs/error.log"
    fi
    
    # Archive completed jobs older than 7 days
    echo "Archiving old completed jobs..."
    find "$WORKSPACE/jobs/completed" -name "*.yaml" -mtime +7 -exec gzip {} \;
    
    echo -e "${GREEN}Cleanup complete${RESET}"
}

test_connections() {
    echo -e "${BOLD}${CYAN}Testing Ollama Connections:${RESET}\n"
    
    while IFS= read -r agent; do
        local host=$(grep -A10 "^  $agent:" "$SHARED_ROOT/configs/machines.yaml" | grep "host:" | awk '{print $2}')
        local model=$(grep -A10 "^  $agent:" "$SHARED_ROOT/configs/machines.yaml" | grep "model:" | awk '{print $2}')
        
        printf "  %-20s " "$agent"
        
        if curl -s --connect-timeout 5 "http://$host/api/tags" > /dev/null 2>&1; then
            # Check if model exists
            if curl -s "http://$host/api/tags" | grep -q "$model"; then
                echo -e "${GREEN}✓ OK${RESET} ($host - $model)"
            else
                echo -e "${YELLOW}⚠ Connected but model missing${RESET} ($model)"
            fi
        else
            echo -e "${RED}✗ FAILED${RESET} (cannot reach $host)"
        fi
    done < <(get_agents)
}

backup_workspace() {
    local backup_dir="$HOME/backups/ai-workspace"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/backup_$timestamp.tar.gz"
    
    mkdir -p "$backup_dir"
    
    echo -e "${YELLOW}Creating backup...${RESET}"
    tar -czf "$backup_file" -C "$HOME" "shared/ai-workspace" "shared/configs" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup created: $backup_file${RESET}"
        
        # Keep only last 5 backups
        ls -t "$backup_dir"/backup_*.tar.gz | tail -n +6 | xargs -r rm
    else
        echo -e "${RED}Backup failed${RESET}"
    fi
}

restore_workspace() {
    local backup_dir="$HOME/backups/ai-workspace"
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}No backups found${RESET}"
        exit 1
    fi
    
    echo -e "${BOLD}Available backups:${RESET}\n"
    ls -lh "$backup_dir"/backup_*.tar.gz | awk '{print $9}' | nl
    
    echo ""
    read -p "Select backup number to restore (or 0 to cancel): " selection
    
    if [ "$selection" = "0" ]; then
        echo "Cancelled"
        exit 0
    fi
    
    local backup_file=$(ls "$backup_dir"/backup_*.tar.gz | sed -n "${selection}p")
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}Invalid selection${RESET}"
        exit 1
    fi
    
    echo -e "${YELLOW}Restoring from: $backup_file${RESET}"
    read -p "This will overwrite current workspace. Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        tar -xzf "$backup_file" -C "$HOME"
        echo -e "${GREEN}Restore complete${RESET}"
    else
        echo "Cancelled"
    fi
}

# Main command dispatcher
case "$1" in
    status)
        show_status
        ;;
    start)
        start_agent "$2"
        ;;
    stop)
        stop_agent "$2"
        ;;
    restart)
        restart_agent "$2"
        ;;
    logs)
        show_logs "$2"
        ;;
    jobs)
        list_jobs
        ;;
    clean)
        clean_workspace
        ;;
    test)
        test_connections
        ;;
    backup)
        backup_workspace
        ;;
    restore)
        restore_workspace
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${RESET}\n"
        show_help
        exit 1
        ;;
esac