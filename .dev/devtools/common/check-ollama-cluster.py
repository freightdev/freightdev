#!/usr/bin/env python3
import requests
import json
import sys
import os
from typing import List, Dict

class OllamaCluster:
    def __init__(self, nodes: List[str]):
        self.nodes = nodes
    
    def list_all_models(self) -> Dict[str, List]:
        inventory = {}
        for node in self.nodes:
            try:
                r = requests.get(f"http://{node}:11434/api/tags", timeout=2)
                inventory[node] = [m['name'] for m in r.json()['models']]
            except:
                inventory[node] = []
        return inventory
    
    def find_model(self, model: str) -> List[str]:
        nodes_with_model = []
        for node in self.nodes:
            try:
                r = requests.get(f"http://{node}:11434/api/tags", timeout=2)
                if any(model in m['name'] for m in r.json()['models']):
                    nodes_with_model.append(node)
            except:
                pass
        return nodes_with_model
    
    def generate(self, node: str, model: str, prompt: str, stream: bool = False):
        url = f"http://{node}:11434/api/generate"
        data = {"model": model, "prompt": prompt, "stream": stream}
        r = requests.post(url, json=data, stream=stream)
        if stream:
            for line in r.iter_lines():
                if line:
                    yield json.loads(line)
        else:
            return r.json()['response']
    
    def health_check(self) -> Dict[str, bool]:
        status = {}
        for node in self.nodes:
            try:
                requests.get(f"http://{node}:11434/api/tags", timeout=1)
                status[node] = True
            except:
                status[node] = False
        return status

if __name__ == "__main__":
    nodes = os.environ.get('OLLAMA_NODES', '').split(',')
    cluster = OllamaCluster(nodes)
    
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "list":
            for node, models in cluster.list_all_models().items():
                print(f"\n=== {node} ===")
                for m in models:
                    print(f"  {m}")
        elif cmd == "health":
            for node, alive in cluster.health_check().items():
                status = "✓" if alive else "✗"
                print(f"{status} {node}")
        elif cmd == "find" and len(sys.argv) > 2:
            model = sys.argv[2]
            nodes = cluster.find_model(model)
            if nodes:
                print(f"Model '{model}' found on: {', '.join(nodes)}")
            else:
                print(f"Model '{model}' not found on any node")
    else:
        print("Usage: ollama-cluster.py [list|health|find MODEL]")
