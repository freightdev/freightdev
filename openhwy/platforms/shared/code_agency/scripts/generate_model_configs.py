#!/usr/bin/env python3
"""Generate model.json configuration files for all models in the models directory"""

import json
import os
from pathlib import Path

# Model directory
MODELS_DIR = Path(__file__).parent.parent / "models"

# Template for model configurations
MODEL_CONFIGS = {
    "tinyllama-1.1b": {
        "name": "TinyLlama 1.1B",
        "description": "Compact 1.1B parameter model, great for testing",
        "context_length": 2048,
        "quantization": "Q4_K_M"
    },
    "tinyllama-1.1b-chat-v1.0": {
        "name": "TinyLlama 1.1B Chat",
        "description": "Chat-optimized TinyLlama model",
        "context_length": 2048,
        "quantization": "Q4_K_M"
    },
    "qwen1.5-1.8b-chat": {
        "name": "Qwen 1.5 1.8B Chat",
        "description": "Qwen 1.5 chat model, 1.8B parameters",
        "context_length": 32768,
        "quantization": "Q4_K_M"
    },
    "osmosis-apply-1.7b": {
        "name": "Osmosis Apply 1.7B",
        "description": "Code application model, 1.7B parameters",
        "context_length": 4096,
        "quantization": "Q4_K_M"
    },
    "nous-hermes-llama2-7b": {
        "name": "Nous Hermes Llama2 7B",
        "description": "Nous Hermes model based on Llama2, 7B parameters",
        "context_length": 4096,
        "quantization": "Q4_K_M"
    },
    "codellama-7b": {
        "name": "Code Llama 7B",
        "description": "Meta's Code Llama for code generation, 7B parameters",
        "context_length": 16384,
        "quantization": "Q4_K_M"
    },
    "zephyr-7b": {
        "name": "Zephyr 7B",
        "description": "HuggingFaceH4's Zephyr model, 7B parameters",
        "context_length": 32768,
        "quantization": "Q4_K_M"
    },
    "yi-1.5-9b-chat": {
        "name": "Yi 1.5 9B Chat",
        "description": "Yi 1.5 chat model, 9B parameters",
        "context_length": 4096,
        "quantization": "Q4_K_M"
    },
    "mythomax-l2-13b": {
        "name": "MythoMax L2 13B",
        "description": "MythoMax model based on Llama2, 13B parameters",
        "context_length": 8192,
        "quantization": "Q4_K_M"
    },
    "openchat-3.5-1210": {
        "name": "OpenChat 3.5",
        "description": "OpenChat 3.5 conversational model",
        "context_length": 8192,
        "quantization": "Q4_K_M"
    }
}


def find_model_file(model_dir: Path) -> Path:
    """Find the .gguf model file in the directory"""
    # Check for Q4_K_M subdirectory first
    q4_dir = model_dir / "Q4_K_M"
    if q4_dir.exists():
        gguf_files = list(q4_dir.glob("*.gguf"))
        if gguf_files:
            return gguf_files[0]

    # Check in root model directory
    gguf_files = list(model_dir.glob("*.gguf"))
    if gguf_files:
        return gguf_files[0]

    # Check in any subdirectory
    for subdir in model_dir.iterdir():
        if subdir.is_dir():
            gguf_files = list(subdir.glob("*.gguf"))
            if gguf_files:
                return gguf_files[0]

    return None


def generate_model_json(model_name: str, model_dir: Path):
    """Generate model.json file for a model"""

    # Find the model file
    model_file = find_model_file(model_dir)

    if not model_file:
        print(f"⚠️  No .gguf file found for {model_name}")
        return False

    # Get configuration or use defaults
    config = MODEL_CONFIGS.get(model_name, {
        "name": model_name.replace("-", " ").title(),
        "description": f"{model_name} language model",
        "context_length": 4096,
        "quantization": "Q4_K_M"
    })

    # Get file size in MB
    file_size_mb = model_file.stat().st_size / (1024 * 1024)

    # Create model.json content
    model_json = {
        "name": config["name"],
        "description": config["description"],
        "path": str(model_file),
        "source": f"local://{model_file}",
        "size_mb": round(file_size_mb, 2),
        "context_length": config["context_length"],
        "quantization": config["quantization"],
        "format": "gguf",
        "architecture": "llama",
        "use_case": "chat",
        "parameters": {
            "temperature": 0.7,
            "top_p": 0.9,
            "top_k": 40,
            "repeat_penalty": 1.1
        }
    }

    # Write model.json
    json_path = model_dir / "model.json"
    with open(json_path, 'w') as f:
        json.dump(model_json, f, indent=2)

    print(f"✓ Generated {json_path}")
    print(f"  Model: {config['name']} ({file_size_mb:.0f}MB)")

    return True


def main():
    """Generate model.json files for all models"""
    print("🔍 Scanning models directory...")
    print(f"   Path: {MODELS_DIR}\n")

    if not MODELS_DIR.exists():
        print(f"❌ Models directory not found: {MODELS_DIR}")
        return

    generated_count = 0
    skipped_count = 0

    for item in MODELS_DIR.iterdir():
        if item.is_dir() and not item.name.startswith('.'):
            print(f"📦 Processing: {item.name}")

            # Skip if model.json already exists
            if (item / "model.json").exists():
                print(f"   Skipping: model.json already exists")
                skipped_count += 1
                continue

            if generate_model_json(item.name, item):
                generated_count += 1

            print()

    print("=" * 60)
    print(f"✅ Complete!")
    print(f"   Generated: {generated_count} model configs")
    print(f"   Skipped: {skipped_count} (already exist)")
    print("=" * 60)


if __name__ == "__main__":
    main()
