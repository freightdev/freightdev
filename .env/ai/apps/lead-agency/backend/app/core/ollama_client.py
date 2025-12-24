import ollama
import os
import random
from typing import List, Optional


class OllamaCluster:
    """Manages connections to the 4-node Ollama cluster"""

    def __init__(self):
        endpoints_str = os.getenv(
            "OLLAMA_ENDPOINTS",
            "http://192.168.12.106:11434,http://192.168.12.136:11434,http://192.168.12.66:11434,http://192.168.12.9:11434"
        )
        self.endpoints = [e.strip() for e in endpoints_str.split(",")]

        # Node specializations
        self.nodes = {
            "hostbox": "http://192.168.12.106:11434",  # L2: reasoning (qwen2.5:14b, gemma3:12b)
            "workbox": "http://192.168.12.136:11434",  # L1: vision/SQL
            "helpbox": "http://192.168.12.66:11434",   # L3: code generation
            "callbox": "http://192.168.12.9:11434",    # L4: quick tasks
        }

    def generate(
        self,
        model: str,
        prompt: str,
        node: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 1000
    ) -> str:
        """
        Generate text using Ollama cluster

        Args:
            model: Model name (e.g., "qwen2.5:14b")
            prompt: Input prompt
            node: Specific node to use (hostbox, workbox, helpbox, callbox)
            temperature: Sampling temperature
            max_tokens: Max tokens to generate

        Returns:
            Generated text
        """
        # Choose endpoint
        if node and node in self.nodes:
            endpoint = self.nodes[node]
        else:
            # Use hostbox as default for reasoning tasks
            endpoint = self.nodes["hostbox"]

        try:
            # Create client for specific endpoint
            client = ollama.Client(host=endpoint)

            # Generate response
            response = client.generate(
                model=model,
                prompt=prompt,
                options={
                    "temperature": temperature,
                    "num_predict": max_tokens,
                }
            )

            return response['response']

        except Exception as e:
            print(f"Error with {endpoint}: {e}")
            # Fallback to another endpoint
            if len(self.endpoints) > 1:
                fallback = random.choice([e for e in self.endpoints if e != endpoint])
                print(f"Trying fallback: {fallback}")
                client = ollama.Client(host=fallback)
                response = client.generate(
                    model=model,
                    prompt=prompt,
                    options={"temperature": temperature, "num_predict": max_tokens}
                )
                return response['response']
            else:
                raise


# Global instance
ollama_cluster = OllamaCluster()
