#!/usr/bin/env python3
"""
AI Agency Client
Interactive client for commanding the AI agency
"""

import requests
import json
import sys
import argparse
from typing import Dict, Any, List

class AgencyClient:
    def __init__(self, base_url: str = "http://127.0.0.1:9015"):
        self.base_url = base_url
        self.session = requests.Session()

    def execute_command(self, command: str, model: str = "mistral:latest") -> Dict[str, Any]:
        """Execute a natural language command"""
        url = f"{self.base_url}/command"
        payload = {
            "command": command,
            "model": model
        }

        try:
            response = self.session.post(url, json=payload, timeout=120)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"success": False, "error": str(e)}

    def execute_direct(self, actions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Execute direct agent actions without AI interpretation"""
        url = f"{self.base_url}/execute"
        payload = {"actions": actions}

        try:
            response = self.session.post(url, json=payload, timeout=120)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"success": False, "error": str(e)}

    def get_status(self) -> Dict[str, Any]:
        """Get system status"""
        url = f"{self.base_url}/status"

        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": str(e)}

    def check_health(self) -> bool:
        """Check if the coordinator is healthy"""
        url = f"{self.base_url}/health"

        try:
            response = self.session.get(url, timeout=5)
            return response.status_code == 200
        except:
            return False

def print_response(response: Dict[str, Any]):
    """Pretty print a response"""
    if response.get("success"):
        print("\n✅ Command executed successfully\n")

        if "actions_taken" in response:
            print("Actions taken:")
            for action in response["actions_taken"]:
                print(f"  • {action}")
            print()

        if "result" in response and response["result"]:
            print("Results:")
            print(json.dumps(response["result"], indent=2))

        if "execution_time_ms" in response:
            print(f"\n⏱️  Execution time: {response['execution_time_ms']}ms")
    else:
        print("\n❌ Command failed\n")
        if "error" in response:
            print(f"Error: {response['error']}")
        if "actions_taken" in response:
            print("\nPartial actions taken:")
            for action in response["actions_taken"]:
                print(f"  • {action}")

def main():
    parser = argparse.ArgumentParser(description="AI Agency Client")
    parser.add_argument("--url", default="http://127.0.0.1:9015", help="Coordinator URL")

    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Status command
    subparsers.add_parser("status", help="Get system status")

    # Health command
    subparsers.add_parser("health", help="Check system health")

    # Execute command
    exec_parser = subparsers.add_parser("exec", help="Execute natural language command")
    exec_parser.add_argument("text", nargs="+", help="Command text")
    exec_parser.add_argument("--model", default="mistral:latest", help="Ollama model to use")

    # Examples
    subparsers.add_parser("examples", help="Show example commands")

    args = parser.parse_args()

    client = AgencyClient(args.url)

    if args.command == "status":
        status = client.get_status()
        print(json.dumps(status, indent=2))

    elif args.command == "health":
        if client.check_health():
            print("✅ System is healthy")
            sys.exit(0)
        else:
            print("❌ System is not responding")
            sys.exit(1)

    elif args.command == "exec":
        command_text = " ".join(args.text)
        print(f"\n📝 Executing: {command_text}\n")

        response = client.execute_command(command_text, args.model)
        print_response(response)

    elif args.command == "examples":
        print("\n📚 Example Commands:\n")
        examples = [
            "Read the file /etc/hosts",
            "List all files in /tmp",
            "Execute command 'ls -la' in /home/admin",
            "Write 'Hello World' to /tmp/test.txt",
            "Check system status",
        ]
        for i, example in enumerate(examples, 1):
            print(f"  {i}. {example}")
        print()
        print("Usage:")
        print(f"  {sys.argv[0]} exec Read the file /etc/hosts")
        print()

    else:
        parser.print_help()

if __name__ == "__main__":
    main()
