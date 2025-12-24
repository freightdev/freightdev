#!/usr/bin/env python3
"""
System Monitor - Displays real-time status of all agents and jobs
"""
import os
import sys
import time
from pathlib import Path
from datetime import datetime
import yaml

# Paths
SHARED_ROOT = Path.home() / "shared"
CONFIG_DIR = SHARED_ROOT / "configs"
WORKSPACE = SHARED_ROOT / "ai-workspace"
LOGS_DIR = WORKSPACE / "logs"
JOBS_DIR = WORKSPACE / "jobs"

# ANSI colors
RESET = "\033[0m"
BOLD = "\033[1m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
CYAN = "\033[36m"
GRAY = "\033[90m"


def clear_screen():
    os.system('clear' if os.name != 'nt' else 'cls')


def get_agent_status():
    """Get status of all agents from ping log"""
    ping_file = LOGS_DIR / "ping.log"
    
    if not ping_file.exists():
        return {}
    
    with open(ping_file) as f:
        pings = f.readlines()[-100:]
    
    agent_pings = {}
    for line in pings:
        parts = line.strip().split()
        if len(parts) >= 3:
            timestamp, agent, status = parts[0], parts[1], parts[2]
            agent_pings[agent] = timestamp
    
    return agent_pings


def get_job_counts():
    """Count jobs by status"""
    counts = {'queued': 0, 'assigned': 0, 'in_progress': 0, 'completed': 0, 'failed': 0}
    
    for status_dir in ['queue', 'active', 'completed']:
        jobs_path = JOBS_DIR / status_dir
        if not jobs_path.exists():
            continue
        
        for job_file in jobs_path.glob("*.yaml"):
            try:
                with open(job_file) as f:
                    job = yaml.safe_load(f)
                status = job.get('status', 'unknown')
                if status in counts:
                    counts[status] += 1
            except:
                pass
    
    return counts


def get_recent_errors():
    """Get recent errors from error log"""
    error_file = LOGS_DIR / "error.log"
    
    if not error_file.exists():
        return []
    
    with open(error_file) as f:
        errors = f.readlines()[-10:]
    
    return [e.strip() for e in errors if e.strip()]


def format_agent_status(agent_pings):
    """Format agent status display"""
    lines = [f"{BOLD}{CYAN}Agent Status:{RESET}"]
    lines.append("─" * 60)
    
    if not agent_pings:
        lines.append(f"{GRAY}No agents active{RESET}")
        return lines
    
    now = time.time()
    for agent, last_ping in sorted(agent_pings.items()):
        try:
            ping_time = datetime.fromisoformat(last_ping).timestamp()
            age = int(now - ping_time)
            
            if age < 60:
                status = f"{GREEN}●{RESET} ACTIVE"
                time_str = f"{age}s ago"
            elif age < 300:
                status = f"{YELLOW}●{RESET} IDLE"
                time_str = f"{age}s ago"
            else:
                status = f"{RED}●{RESET} OFFLINE"
                minutes = age // 60
                time_str = f"{minutes}m ago"
            
            lines.append(f"  {status} {BOLD}{agent:<20}{RESET} Last seen: {time_str}")
        except:
            lines.append(f"  {RED}●{RESET} {BOLD}{agent:<20}{RESET} Parse error")
    
    return lines


def format_job_stats(counts):
    """Format job statistics display"""
    lines = [f"\n{BOLD}{CYAN}Job Statistics:{RESET}"]
    lines.append("─" * 60)
    
    total = sum(counts.values())
    
    if total == 0:
        lines.append(f"{GRAY}No jobs in system{RESET}")
        return lines
    
    lines.append(f"  Total Jobs: {BOLD}{total}{RESET}")
    lines.append("")
    lines.append(f"  {YELLOW}●{RESET} Queued:      {counts['queued']}")
    lines.append(f"  {CYAN}●{RESET} Assigned:    {counts['assigned']}")
    lines.append(f"  {BLUE}●{RESET} In Progress: {counts['in_progress']}")
    lines.append(f"  {GREEN}●{RESET} Completed:   {counts['completed']}")
    if counts['failed'] > 0:
        lines.append(f"  {RED}●{RESET} Failed:      {counts['failed']}")
    
    return lines


def format_recent_errors(errors):
    """Format recent errors display"""
    if not errors:
        return []
    
    lines = [f"\n{BOLD}{RED}Recent Errors:{RESET}"]
    lines.append("─" * 60)
    
    for error in errors[-5:]:
        # Truncate long errors
        if len(error) > 100:
            error = error[:97] + "..."
        lines.append(f"  {RED}!{RESET} {error}")
    
    return lines


def display_dashboard():
    """Display monitoring dashboard"""
    clear_screen()
    
    # Header
    print(f"{BOLD}{CYAN}╔════════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{CYAN}║{RESET}  {BOLD}AI Multi-Agent System Monitor{RESET}                             {BOLD}{CYAN}║{RESET}")
    print(f"{BOLD}{CYAN}║{RESET}  {GRAY}Press Ctrl+C to exit{RESET}                                       {BOLD}{CYAN}║{RESET}")
    print(f"{BOLD}{CYAN}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
    
    # Get data
    agent_status = get_agent_status()
    job_counts = get_job_counts()
    recent_errors = get_recent_errors()
    
    # Display sections
    for line in format_agent_status(agent_status):
        print(line)
    
    for line in format_job_stats(job_counts):
        print(line)
    
    error_lines = format_recent_errors(recent_errors)
    if error_lines:
        for line in error_lines:
            print(line)
    
    # Footer
    print(f"\n{GRAY}Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{RESET}")


def main():
    """Main monitoring loop"""
    try:
        while True:
            display_dashboard()
            time.sleep(5)
    except KeyboardInterrupt:
        print(f"\n\n{YELLOW}Monitor stopped{RESET}")
        sys.exit(0)


if __name__ == "__main__":
    main()