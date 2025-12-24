#!/usr/bin/env python3
"""
AI Chat Client - Interactive terminal interface for multi-agent workspace
"""
import os
import sys
import yaml
import threading
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, List
import filelock

# Paths
SHARED_ROOT = Path.home() / "shared"
CONFIG_DIR = SHARED_ROOT / "configs"
WORKSPACE = SHARED_ROOT / "ai-workspace"
CHATS_DIR = WORKSPACE / "chats"
JOBS_DIR = WORKSPACE / "jobs"

# ANSI colors
RESET = "\033[0m"
BOLD = "\033[1m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
GRAY = "\033[90m"


class ChatClient:
    def __init__(self):
        self.channels = self.load_channels()
        self.current_channel = "general"
        self.running = True
        self.last_positions = {}
        
        # Color map for agents
        self.agent_colors = {
            'architect-gtx': GREEN,
            'worker-i9': BLUE,
            'worker-npu': CYAN,
            'worker-smol': MAGENTA
        }
    
    def load_channels(self) -> Dict:
        """Load channels configuration"""
        config_file = CONFIG_DIR / "channels.yaml"
        if not config_file.exists():
            print(f"Error: Channels config not found at {config_file}")
            sys.exit(1)
        
        with open(config_file) as f:
            return yaml.safe_load(f)['channels']
    
    def clear_screen(self):
        """Clear terminal screen"""
        os.system('clear' if os.name != 'nt' else 'cls')
    
    def print_header(self):
        """Print client header"""
        print(f"{BOLD}{CYAN}╔════════════════════════════════════════════════════════════════╗{RESET}")
        print(f"{BOLD}{CYAN}║{RESET}  {BOLD}AI Multi-Agent Workspace{RESET}                                   {BOLD}{CYAN}║{RESET}")
        print(f"{BOLD}{CYAN}╠════════════════════════════════════════════════════════════════╣{RESET}")
        print(f"{BOLD}{CYAN}║{RESET}  Channel: {YELLOW}{self.current_channel}{RESET}".ljust(73) + f"{BOLD}{CYAN}║{RESET}")
        print(f"{BOLD}{CYAN}╚════════════════════════════════════════════════════════════════╝{RESET}\n")
    
    def print_help(self):
        """Print help commands"""
        print(f"\n{BOLD}Commands:{RESET}")
        print(f"  {GREEN}/channel <name>{RESET}     - Switch channel (general, admin, workflow)")
        print(f"  {GREEN}/job create{RESET}         - Create new job")
        print(f"  {GREEN}/job list{RESET}           - List all jobs")
        print(f"  {GREEN}/job assign <id> <agent>{RESET} - Assign job to agent")
        print(f"  {GREEN}/status{RESET}              - Show agent status")
        print(f"  {GREEN}/help{RESET}                - Show this help")
        print(f"  {GREEN}/quit{RESET}                - Exit client\n")
    
    def read_channel_tail(self, channel: str, lines: int = 20) -> List[str]:
        """Read last N messages from channel"""
        channel_file = CHATS_DIR / f"{channel}.md"
        if not channel_file.exists():
            return []
        
        with open(channel_file) as f:
            content = f.read()
        
        # Parse messages
        messages = []
        current_msg = []
        in_message = False
        
        for line in content.split('\n'):
            if line.startswith('```') and not in_message:
                in_message = True
                current_msg = [line]
            elif line.startswith('```') and in_message:
                current_msg.append(line)
                messages.append('\n'.join(current_msg))
                current_msg = []
                in_message = False
            elif in_message:
                current_msg.append(line)
        
        return messages[-lines:]
    
    def format_message(self, message: str) -> str:
        """Format message with colors"""
        lines = message.split('\n')
        if not lines:
            return ""
        
        # Parse header
        header = lines[0].replace('```', '').strip()
        content = '\n'.join(lines[1:-1]) if len(lines) > 2 else ""
        
        # Determine sender and status
        status = ""
        sender = header
        
        if '[' in header:
            parts = header.split('[')
            sender = parts[0].strip()
            status = '[' + parts[1] if len(parts) > 1 else ""
        
        # Get color for sender
        color = self.agent_colors.get(sender, GRAY)
        
        # Format status indicator
        if status:
            if 'TYPING' in status:
                status_color = YELLOW
            elif 'SENDING' in status:
                status_color = CYAN
            elif 'WORKING' in status:
                status_color = GREEN
            else:
                status_color = GRAY
            status_str = f" {status_color}{status}{RESET}"
        else:
            status_str = ""
        
        # Format output
        timestamp = datetime.now().strftime("%H:%M:%S")
        output = f"{GRAY}[{timestamp}]{RESET} {color}{BOLD}{sender}{RESET}{status_str}"
        
        if content.strip():
            output += f"\n{content}"
        
        return output
    
    def display_messages(self):
        """Display recent messages from current channel"""
        messages = self.read_channel_tail(self.current_channel, 15)
        
        if not messages:
            print(f"{GRAY}No messages in this channel yet.{RESET}\n")
            return
        
        print(f"{BOLD}Recent messages:{RESET}\n")
        for msg in messages:
            print(self.format_message(msg))
            print()  # Blank line between messages
    
    def write_message(self, message: str):
        """Write user message to current channel"""
        channel_file = CHATS_DIR / f"{self.current_channel}.md"
        lock_file = channel_file.with_suffix('.lock')
        
        try:
            with filelock.FileLock(str(lock_file), timeout=10):
                formatted_msg = f"```user\n{message}\n```\n\n"
                
                with open(channel_file, "a") as f:
                    f.write(formatted_msg)
                
                print(f"{GREEN}Message sent to {self.current_channel}{RESET}")
        except Exception as e:
            print(f"{RED}Failed to send message: {e}{RESET}")
    
    def switch_channel(self, channel: str):
        """Switch to different channel"""
        if channel not in self.channels:
            print(f"{RED}Unknown channel: {channel}{RESET}")
            print(f"Available: {', '.join(self.channels.keys())}")
            return
        
        self.current_channel = channel
        self.clear_screen()
        self.print_header()
        self.display_messages()
    
    def create_job(self):
        """Interactive job creation"""
        print(f"\n{BOLD}Create New Job{RESET}\n")
        
        title = input("Job title: ").strip()
        if not title:
            print(f"{RED}Title required{RESET}")
            return
        
        description = input("Description: ").strip()
        priority = input("Priority (low/medium/high) [medium]: ").strip() or "medium"
        
        # Requirements
        print("Requirements (one per line, empty to finish):")
        requirements = []
        while True:
            req = input("  - ").strip()
            if not req:
                break
            requirements.append(req)
        
        # Deliverables
        print("Deliverables (one per line, empty to finish):")
        deliverables = []
        while True:
            deliv = input("  - ").strip()
            if not deliv:
                break
            deliverables.append(deliv)
        
        # Generate job ID
        job_id = f"job-{int(time.time())}"
        
        # Create job file
        job = {
            'id': job_id,
            'title': title,
            'description': description,
            'priority': priority,
            'status': 'queued',
            'assigned_to': None,
            'created_by': 'user',
            'created_at': datetime.now().isoformat(),
            'requirements': requirements,
            'deliverables': deliverables,
            'dependencies': []
        }
        
        job_file = JOBS_DIR / "queue" / f"{job_id}.yaml"
        job_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(job_file, 'w') as f:
            yaml.dump(job, f, default_flow_style=False)
        
        print(f"\n{GREEN}Job {job_id} created!{RESET}")
        print(f"Use: {CYAN}/job assign {job_id} <agent>{RESET} to assign it")
    
    def list_jobs(self):
        """List all jobs"""
        print(f"\n{BOLD}All Jobs:{RESET}\n")
        
        for status_dir in ['queue', 'active', 'completed']:
            jobs_path = JOBS_DIR / status_dir
            if not jobs_path.exists():
                continue
            
            jobs = list(jobs_path.glob("*.yaml"))
            if jobs:
                print(f"{BOLD}{status_dir.upper()}:{RESET}")
                for job_file in jobs:
                    with open(job_file) as f:
                        job = yaml.safe_load(f)
                    
                    status_color = GREEN if status_dir == 'completed' else YELLOW
                    assigned = job.get('assigned_to', 'unassigned')
                    print(f"  {status_color}●{RESET} {job['id']}: {job['title']}")
                    print(f"    Assigned: {assigned} | Priority: {job.get('priority', 'medium')}")
                print()
    
    def assign_job(self, job_id: str, agent: str):
        """Assign job to agent"""
        job_file = JOBS_DIR / "queue" / f"{job_id}.yaml"
        
        if not job_file.exists():
            print(f"{RED}Job {job_id} not found in queue{RESET}")
            return
        
        with open(job_file) as f:
            job = yaml.safe_load(f)
        
        job['assigned_to'] = agent
        job['status'] = 'assigned'
        
        with open(job_file, 'w') as f:
            yaml.dump(job, f, default_flow_style=False)
        
        print(f"{GREEN}Job {job_id} assigned to {agent}{RESET}")
    
    def show_status(self):
        """Show agent status from ping logs"""
        ping_file = WORKSPACE / "logs" / "ping.log"
        
        if not ping_file.exists():
            print(f"{GRAY}No ping data available{RESET}")
            return
        
        print(f"\n{BOLD}Agent Status:{RESET}\n")
        
        # Read last 50 pings
        with open(ping_file) as f:
            pings = f.readlines()[-50:]
        
        # Group by agent
        agent_pings = {}
        for line in pings:
            parts = line.strip().split()
            if len(parts) >= 3:
                timestamp, agent, status = parts[0], parts[1], parts[2]
                agent_pings[agent] = timestamp
        
        # Display
        now = time.time()
        for agent, last_ping in agent_pings.items():
            try:
                ping_time = datetime.fromisoformat(last_ping).timestamp()
                age = int(now - ping_time)
                
                if age < 60:
                    status = f"{GREEN}●{RESET} ACTIVE ({age}s ago)"
                elif age < 300:
                    status = f"{YELLOW}●{RESET} IDLE ({age}s ago)"
                else:
                    status = f"{RED}●{RESET} OFFLINE ({age}s ago)"
                
                color = self.agent_colors.get(agent, GRAY)
                print(f"  {status} {color}{agent}{RESET}")
            except:
                pass
        
        print()
    
    def run(self):
        """Main client loop"""
        self.clear_screen()
        self.print_header()
        print(f"{BOLD}Welcome to AI Multi-Agent Workspace!{RESET}\n")
        print(f"Type {CYAN}/help{RESET} for commands\n")
        
        self.display_messages()
        
        while self.running:
            try:
                user_input = input(f"\n{BOLD}{BLUE}[{self.current_channel}]>{RESET} ").strip()
                
                if not user_input:
                    continue
                
                # Handle commands
                if user_input.startswith('/'):
                    parts = user_input[1:].split()
                    cmd = parts[0].lower()
                    
                    if cmd == 'quit' or cmd == 'exit':
                        print(f"{YELLOW}Goodbye!{RESET}")
                        self.running = False
                    
                    elif cmd == 'help':
                        self.print_help()
                    
                    elif cmd == 'channel':
                        if len(parts) > 1:
                            self.switch_channel(parts[1])
                        else:
                            print(f"{RED}Usage: /channel <name>{RESET}")
                    
                    elif cmd == 'job':
                        if len(parts) < 2:
                            print(f"{RED}Usage: /job <create|list|assign>{RESET}")
                        elif parts[1] == 'create':
                            self.create_job()
                        elif parts[1] == 'list':
                            self.list_jobs()
                        elif parts[1] == 'assign':
                            if len(parts) >= 4:
                                self.assign_job(parts[2], parts[3])
                            else:
                                print(f"{RED}Usage: /job assign <job_id> <agent>{RESET}")
                    
                    elif cmd == 'status':
                        self.show_status()
                    
                    elif cmd == 'refresh':
                        self.clear_screen()
                        self.print_header()
                        self.display_messages()
                    
                    else:
                        print(f"{RED}Unknown command: {cmd}{RESET}")
                
                else:
                    # Regular message
                    self.write_message(user_input)
            
            except KeyboardInterrupt:
                print(f"\n{YELLOW}Use /quit to exit{RESET}")
            except Exception as e:
                print(f"{RED}Error: {e}{RESET}")


if __name__ == "__main__":
    try:
        import filelock
    except ImportError:
        print("Installing required dependency: filelock")
        os.system("pip install filelock")
        import filelock
    
    client = ChatClient()
    client.run()