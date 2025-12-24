"""
Ollama Cluster Service
Manages connections to Ollama cluster and provides model access
"""
import requests
import json
import os
from typing import List, Dict, Optional, Generator
from pydantic import BaseModel


class ModelInfo(BaseModel):
    name: str
    node: str
    size: Optional[int] = None


class OllamaCluster:
    def __init__(self, nodes: List[str]):
        self.nodes = nodes

    def list_all_models(self) -> Dict[str, List[Dict]]:
        """Get all models from all nodes with full details"""
        inventory = {}
        for node in self.nodes:
            try:
                r = requests.get(f"http://{node}:11434/api/tags", timeout=2)
                if r.status_code == 200:
                    inventory[node] = r.json().get('models', [])
                else:
                    inventory[node] = []
            except Exception as e:
                print(f"Error contacting {node}: {e}")
                inventory[node] = []
        return inventory

    def get_all_unique_models(self) -> List[ModelInfo]:
        """Get a deduplicated list of all models across cluster"""
        models_map = {}
        inventory = self.list_all_models()

        for node, models in inventory.items():
            for model in models:
                model_name = model['name']
                if model_name not in models_map:
                    models_map[model_name] = ModelInfo(
                        name=model_name,
                        node=node,
                        size=model.get('size')
                    )

        return list(models_map.values())

    def find_model(self, model: str) -> List[str]:
        """Find which nodes have a specific model"""
        nodes_with_model = []
        for node in self.nodes:
            try:
                r = requests.get(f"http://{node}:11434/api/tags", timeout=2)
                if r.status_code == 200:
                    models = r.json().get('models', [])
                    if any(model in m['name'] for m in models):
                        nodes_with_model.append(node)
            except:
                pass
        return nodes_with_model

    def generate(self, model: str, prompt: str, stream: bool = False, node: Optional[str] = None) -> Generator:
        """Generate response from Ollama"""
        # If no node specified, find one that has the model
        if not node:
            nodes_with_model = self.find_model(model)
            if not nodes_with_model:
                raise ValueError(f"Model {model} not found on any node")
            node = nodes_with_model[0]  # Use first available node

        url = f"http://{node}:11434/api/generate"
        data = {"model": model, "prompt": prompt, "stream": stream}

        r = requests.post(url, json=data, stream=stream, timeout=120)

        if stream:
            for line in r.iter_lines():
                if line:
                    try:
                        yield json.loads(line)
                    except json.JSONDecodeError:
                        continue
        else:
            if r.status_code == 200:
                return r.json().get('response', '')
            else:
                raise Exception(f"Generation failed: {r.text}")

    def chat(self, model: str, messages: List[Dict], stream: bool = False, node: Optional[str] = None) -> Generator:
        """Chat with Ollama using conversation history"""
        # If no node specified, find one that has the model
        if not node:
            nodes_with_model = self.find_model(model)
            if not nodes_with_model:
                raise ValueError(f"Model {model} not found on any node")
            node = nodes_with_model[0]

        url = f"http://{node}:11434/api/chat"
        data = {"model": model, "messages": messages, "stream": stream}

        r = requests.post(url, json=data, stream=stream, timeout=120)

        if stream:
            for line in r.iter_lines():
                if line:
                    try:
                        yield json.loads(line)
                    except json.JSONDecodeError:
                        continue
        else:
            if r.status_code == 200:
                return r.json()
            else:
                raise Exception(f"Chat failed: {r.text}")

    def health_check(self) -> Dict[str, bool]:
        """Check health of all nodes"""
        status = {}
        for node in self.nodes:
            try:
                requests.get(f"http://{node}:11434/api/tags", timeout=1)
                status[node] = True
            except:
                status[node] = False
        return status


# Global cluster instance
_cluster = None

def get_cluster() -> OllamaCluster:
    """Get or create the global Ollama cluster instance"""
    global _cluster
    if _cluster is None:
        nodes_str = os.environ.get('OLLAMA_NODES', '192.168.12.106,192.168.12.66,192.168.12.9,192.168.12.136')
        nodes = [n.strip() for n in nodes_str.split(',') if n.strip()]
        _cluster = OllamaCluster(nodes)
    return _cluster
