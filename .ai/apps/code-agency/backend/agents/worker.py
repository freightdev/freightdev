#!/usr/bin/env python3
"""
AI Worker Agent - Monitors channels and executes jobs
"""
import os
import sys
import time
import json
import yaml
import signal
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import requests
import filelock

# Paths
SHARED_ROOT = Path.home() / "shared"
CONFIG_DIR = SHARED_ROOT / "configs"
WORKSPACE = SHARED_ROOT / "ai-workspace"
LOGS_DIR = WORKSPACE / "logs"
CHATS_DIR = WORKSPACE / "chats"
JOBS_DIR = WORKSPACE / "jobs"

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOGS_DIR / "system.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class Agent:
    def __init__(self, agent_id: str):
        self.agent_id = agent_id
        self.config = self.load_config()
        self.agent_config = self.config['agents'][agent_id]
        self.channels_config = self.load_channels_config()
        self.running = True
        self.last_positions = {}  # Track read positions in channels
        self.current_job = None
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self.shutdown)
        signal.signal(signal.SIGTERM, self.shutdown)
        
        logger.info(f"Agent {agent_id} initialized with model {self.agent_config['model']}")
    
    def load_config(self) -> Dict:
        """Load machine configuration"""
        config_file = CONFIG_DIR / "machines.yaml"
        if not config_file.exists():
            logger.error(f"Config file not found: {config_file}")
            sys.exit(1)
        
        with open(config_file) as f:
            return yaml.safe_load(f)
    
    def load_channels_config(self) -> Dict:
        """Load channels configuration"""
        config_file = CONFIG_DIR / "channels.yaml"
        if not config_file.exists():
            logger.error(f"Channels config not found: {config_file}")
            sys.exit(1)
        
        with open(config_file) as f:
            return yaml.safe_load(f)
    
    def shutdown(self, signum, frame):
        """Graceful shutdown"""
        logger.info(f"Agent {self.agent_id} shutting down...")
        self.running = False
        sys.exit(0)
    
    def ping(self):
        """Send heartbeat to ping log"""
        try:
            with open(LOGS_DIR / "ping.log", "a") as f:
                f.write(f"{datetime.now().isoformat()} {self.agent_id} ALIVE\n")
        except Exception as e:
            logger.error(f"Failed to ping: {e}")
    
    def log_error(self, error: str):
        """Log error to error log"""
        try:
            with open(LOGS_DIR / "error.log", "a") as f:
                f.write(f"{datetime.now().isoformat()} {self.agent_id} {error}\n")
        except Exception as e:
            logger.error(f"Failed to log error: {e}")
    
    def can_access_channel(self, channel: str) -> bool:
        """Check if agent has permission for channel"""
        channel_config = self.channels_config['channels'].get(channel)
        if not channel_config:
            return False
        
        members = channel_config.get('members', [])
        if 'all' in members or self.agent_id in members:
            return True
        
        # Check by role
        agent_role = self.agent_config.get('role')
        if agent_role in members:
            return True
        
        return False
    
    def read_channel(self, channel: str) -> List[str]:
        """Read new messages from channel"""
        channel_file = CHATS_DIR / f"{channel}.md"
        if not channel_file.exists():
            return []
        
        try:
            with open(channel_file) as f:
                content = f.read()
            
            # Track position to only get new messages
            last_pos = self.last_positions.get(channel, 0)
            current_pos = len(content)
            
            if current_pos <= last_pos:
                return []
            
            new_content = content[last_pos:]
            self.last_positions[channel] = current_pos
            
            # Parse messages (simple split on triple backticks)
            messages = []
            lines = new_content.split('\n')
            current_msg = []
            in_message = False
            
            for line in lines:
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
            
            return messages
        except Exception as e:
            self.log_error(f"Failed to read channel {channel}: {e}")
            return []
    
    def write_to_channel(self, channel: str, message: str, status: str = ""):
        """Write message to channel with optional status indicator"""
        channel_file = CHATS_DIR / f"{channel}.md"
        lock_file = channel_file.with_suffix('.lock')
        
        try:
            with filelock.FileLock(str(lock_file), timeout=10):
                status_tag = f" [{status}]" if status else ""
                formatted_msg = f"```{self.agent_id}{status_tag}\n{message}\n```\n\n"
                
                with open(channel_file, "a") as f:
                    f.write(formatted_msg)
                
                logger.info(f"Wrote to {channel}: {message[:50]}...")
        except Exception as e:
            self.log_error(f"Failed to write to channel {channel}: {e}")
    
    def call_ollama(self, prompt: str, context: str = "") -> str:
        """Call Ollama API with prompt"""
        host = self.agent_config['host']
        model = self.agent_config['model']
        
        full_prompt = f"{context}\n\n{prompt}" if context else prompt
        
        try:
            response = requests.post(
                f"http://{host}/api/generate",
                json={
                    "model": model,
                    "prompt": full_prompt,
                    "stream": False
                },
                timeout=300
            )
            
            if response.status_code == 200:
                return response.json().get('response', '')
            else:
                self.log_error(f"Ollama API error: {response.status_code}")
                return ""
        except Exception as e:
            self.log_error(f"Failed to call Ollama: {e}")
            return ""
    
    def check_jobs(self):
        """Check for assigned jobs"""
        queue_dir = JOBS_DIR / "queue"
        if not queue_dir.exists():
            return None
        
        # Look for jobs assigned to this agent
        for job_file in queue_dir.glob("*.yaml"):
            try:
                with open(job_file) as f:
                    job = yaml.safe_load(f)
                
                if job.get('assigned_to') == self.agent_id and job.get('status') == 'assigned':
                    return job, job_file
            except Exception as e:
                self.log_error(f"Failed to read job {job_file}: {e}")
        
        return None
    
    def execute_job(self, job: Dict, job_file: Path):
        """Execute an assigned job"""
        job_id = job['id']
        logger.info(f"Executing job {job_id}")
        
        # Update job status
        job['status'] = 'in_progress'
        self.save_job(job, job_file)
        
        # Announce in workflow channel
        self.write_to_channel('workflow', f"Starting job {job_id}: {job['title']}", "WORKING")
        
        # Build context from referenced files
        context = f"Job: {job['title']}\n\nDescription:\n{job['description']}\n\n"
        
        if 'requirements' in job:
            context += "Requirements:\n" + '\n'.join(f"- {r}" for r in job['requirements']) + "\n\n"
        
        # Load context files if specified
        if 'context_files' in job:
            for ctx_file in job['context_files']:
                ctx_path = SHARED_ROOT / ctx_file
                if ctx_path.exists():
                    with open(ctx_path) as f:
                        context += f"\n--- {ctx_file} ---\n{f.read()}\n"
        
        # Call Ollama
        self.write_to_channel('workflow', f"Processing job {job_id}...", "TYPING")
        response = self.call_ollama(
            f"Complete this task and provide the deliverables:\n\n{job.get('deliverables', [])}",
            context
        )
        
        if response:
            # Write response to workflow
            self.write_to_channel('workflow', f"Job {job_id} result:\n\n{response}")
            
            # Move job to completed
            job['status'] = 'completed'
            job['completed_at'] = datetime.now().isoformat()
            job['result'] = response
            
            completed_file = JOBS_DIR / "completed" / job_file.name
            self.save_job(job, completed_file)
            job_file.unlink()
            
            logger.info(f"Job {job_id} completed")
        else:
            # Job failed
            job['status'] = 'failed'
            self.save_job(job, job_file)
            self.write_to_channel('workflow', f"Job {job_id} failed - check error logs")
    
    def save_job(self, job: Dict, path: Path):
        """Save job to file"""
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, 'w') as f:
            yaml.dump(job, f, default_flow_style=False)
    
    def process_message(self, channel: str, message: str):
        """Process a message from a channel"""
        # Extract sender and content
        lines = message.split('\n')
        if not lines:
            return
        
        header = lines[0].replace('```', '').strip()
        content = '\n'.join(lines[1:-1]) if len(lines) > 2 else ""
        
        # Ignore own messages
        if header.startswith(self.agent_id):
            return
        
        # Ignore status messages
        if '[TYPING]' in header or '[SENDING]' in header:
            return
        
        # Check if mentioned or needs response
        if f"@{self.agent_id}" in content or channel == "general":
            logger.info(f"Processing message in {channel}: {content[:50]}...")
            
            # Only respond in general if directly mentioned or appropriate
            if channel == "general" and f"@{self.agent_id}" not in content:
                # Skip most general chat unless it's a question
                if '?' not in content:
                    return
            
            # Generate response
            self.write_to_channel(channel, "Thinking...", "TYPING")
            response = self.call_ollama(content)
            
            if response:
                self.write_to_channel(channel, response)
    
    def run(self):
        """Main agent loop"""
        logger.info(f"Agent {self.agent_id} starting main loop")
        
        # Get accessible channels
        accessible_channels = [
            ch for ch in self.channels_config['channels'].keys()
            if self.can_access_channel(ch)
        ]
        
        logger.info(f"Monitoring channels: {accessible_channels}")
        
        ping_interval = 30
        last_ping = time.time()
        
        while self.running:
            try:
                # Send heartbeat
                if time.time() - last_ping > ping_interval:
                    self.ping()
                    last_ping = time.time()
                
                # Check for jobs
                job_data = self.check_jobs()
                if job_data:
                    job, job_file = job_data
                    self.execute_job(job, job_file)
                
                # Monitor channels
                for channel in accessible_channels:
                    messages = self.read_channel(channel)
                    for msg in messages:
                        self.process_message(channel, msg)
                
                time.sleep(2)
                
            except Exception as e:
                self.log_error(f"Error in main loop: {e}")
                logger.error(f"Error in main loop: {e}")
                time.sleep(5)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: worker.py <agent_id>")
        print("Example: worker.py architect-gtx")
        sys.exit(1)
    
    agent_id = sys.argv[1]
    agent = Agent(agent_id)
    agent.run()