#!/bin/bash

# AI Development Environment Setup Script
echo "Setting up AI development environment..."

# Create main project directory
mkdir -p ~/ai-projects
cd ~/ai-projects

# Create directory structure
mkdir -p {cursor-ide,chatgpt-clone,shared-libs,data,models,scripts,configs}

# CursorIDE project structure
mkdir -p cursor-ide/{frontend,backend,language-servers,extensions,tests}
mkdir -p cursor-ide/frontend/{src,public,components,styles}
mkdir -p cursor-ide/backend/{api,db,services,middleware}

# ChatGPT Clone project structure
mkdir -p chatgpt-clone/{frontend,backend,model-server,training,data-pipeline,tests}
mkdir -p chatgpt-clone/backend/{api,db,services,auth}
mkdir -p chatgpt-clone/model-server/{inference,fine-tuning,embeddings}
mkdir -p chatgpt-clone/training/{datasets,scripts,configs}

# Shared libraries
mkdir -p shared-libs/{rust-ffi,python-utils,database,auth,logging}

# Data directories
mkdir -p data/{raw,processed,embeddings,conversations,truck-driver-data}
mkdir -p models/{local,fine-tuned,embeddings,checkpoints}

# Create initial config files
cat > configs/databases.yaml << 'EOF'
postgresql:
  host: localhost
  port: 5432
  database: ai_dev
  user: ${USER}
  
redis:
  host: localhost
  port: 6379
  db: 0
  
duckdb:
  path: ./data/analytics.duckdb
EOF

cat > configs/models.yaml << 'EOF'
llama:
  model_path: ./models/llama-2-7b-chat
  context_length: 4096
  
embeddings:
  model: sentence-transformers/all-MiniLM-L6-v2
  cache_dir: ./models/embeddings
  
inference:
  batch_size: 8
  max_tokens: 2048
  temperature: 0.7
EOF

# Create environment files
cat > .env.example << 'EOF'
# Database URLs
DATABASE_URL=postgresql://localhost/ai_dev
REDIS_URL=redis://localhost:6379
DUCKDB_PATH=./data/analytics.duckdb

# API Keys (fill in your keys)
OPENAI_API_KEY=your_openai_key_here
HUGGINGFACE_TOKEN=your_hf_token_here

# Model paths
LLAMA_MODEL_PATH=./models/llama-2-7b-chat
EMBEDDINGS_MODEL=sentence-transformers/all-MiniLM-L6-v2

# Server settings
BACKEND_PORT=8000
FRONTEND_PORT=3000
MODEL_SERVER_PORT=8001
EOF

# Create Python requirements file
cat > requirements.txt << 'EOF'
# Core ML/AI
torch
transformers
accelerate
bitsandbytes
sentence-transformers
langchain
chromadb

# Databases
psycopg2-binary
redis
duckdb
sqlalchemy
alembic

# Web framework
fastapi
uvicorn
websockets
gradio
streamlit

# Data processing
pandas
numpy
requests
beautifulsoup4
scrapy

# Development
black
isort
mypy
flake8
pytest
pre-commit
EOF

# Create basic FastAPI backend
mkdir -p chatgpt-clone/backend/api
cat > chatgpt-clone/backend/api/main.py << 'EOF'
from fastapi import FastAPI, WebSocket, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import redis
import psycopg2
from typing import List, Dict
import json

app = FastAPI(title="ChatGPT Clone API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connections
redis_client = redis.Redis(host='localhost', port=6379, db=0)

@app.get("/")
async def root():
    return {"message": "ChatGPT Clone API is running!"}

@app.get("/health")
async def health_check():
    try:
        # Test Redis
        redis_status = redis_client.ping()
        
        # Test PostgreSQL
        conn = psycopg2.connect("dbname=ai_dev")
        conn.close()
        postgres_status = True
    except:
        postgres_status = False
        
    return {
        "status": "healthy" if redis_status and postgres_status else "unhealthy",
        "redis": redis_status,
        "postgresql": postgres_status
    }

@app.websocket("/chat")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # TODO: Process message with your model
            response = {
                "response": f"Echo: {message.get('message', '')}",
                "timestamp": "2025-08-06T02:00:00Z"
            }
            
            await websocket.send_text(json.dumps(response))
    except Exception as e:
        print(f"WebSocket error: {e}")
        await websocket.close()
EOF

# Create basic model server
cat > chatgpt-clone/model-server/inference.py << 'EOF'
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="Model Inference Server")

# Global model and tokenizer
model = None
tokenizer = None

@app.on_event("startup")
async def load_model():
    global model, tokenizer
    print("Loading model...")
    # TODO: Load your fine-tuned model or llama.cpp bindings
    print("Model loaded successfully!")

@app.post("/generate")
async def generate_text(prompt: str, max_tokens: int = 100):
    # TODO: Implement text generation using your Rust FFI bindings
    return {
        "generated_text": f"Generated response for: {prompt}",
        "tokens_used": max_tokens
    }

@app.get("/model/info")
async def model_info():
    return {
        "model_name": "Custom LLM",
        "context_length": 4096,
        "status": "loaded"
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
EOF

# Create data collection script for truck drivers
cat > scripts/truck_driver_data_collector.py << 'EOF'
import requests
from bs4 import BeautifulSoup
import json
import time
from datetime import datetime
import duckdb

class TruckDriverDataCollector:
    def __init__(self):
        self.db = duckdb.connect('data/truck_driver_data.duckdb')
        self.setup_database()
    
    def setup_database(self):
        """Create tables for truck driver data"""
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS conversations (
                id INTEGER PRIMARY KEY,
                timestamp TIMESTAMP,
                driver_id VARCHAR,
                message TEXT,
                response TEXT,
                context VARCHAR
            )
        """)
        
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS training_data (
                id INTEGER PRIMARY KEY,
                timestamp TIMESTAMP,
                source VARCHAR,
                content TEXT,
                category VARCHAR,
                processed BOOLEAN DEFAULT FALSE
            )
        """)
    
    def collect_trucking_resources(self):
        """Collect data from trucking websites, forums, etc."""
        # TODO: Implement web scraping for trucking-specific content
        sources = [
            "https://www.truckinginfo.com/",
            "https://www.overdriveonline.com/",
            # Add more trucking resources
        ]
        
        for source in sources:
            try:
                # Implement scraping logic
                print(f"Collecting from {source}")
                # Store in database
            except Exception as e:
                print(f"Error collecting from {source}: {e}")
    
    def store_conversation(self, driver_id, message, response, context=""):
        """Store truck driver conversations for training"""
        self.db.execute("""
            INSERT INTO conversations (timestamp, driver_id, message, response, context)
            VALUES (?, ?, ?, ?, ?)
        """, (datetime.now(), driver_id, message, response, context))

if __name__ == "__main__":
    collector = TruckDriverDataCollector()
    collector.collect_trucking_resources()
EOF

# Create Rust FFI integration example
cat > shared-libs/rust-ffi/llama_bindings.py << 'EOF'
import ctypes
import os
from typing import Optional

class LlamaRustFFI:
    """Python bindings for Rust llama.cpp FFI"""
    
    def __init__(self, lib_path: str = "./target/release/libllama_ffi.so"):
        if os.path.exists(lib_path):
            self.lib = ctypes.CDLL(lib_path)
            self.setup_bindings()
        else:
            print(f"Rust library not found at {lib_path}")
            print("Please build your Rust FFI library first")
            self.lib = None
    
    def setup_bindings(self):
        """Setup function signatures for Rust FFI"""
        if not self.lib:
            return
            
        # Example function signatures
        self.lib.llama_init.argtypes = [ctypes.c_char_p]
        self.lib.llama_init.restype = ctypes.c_void_p
        
        self.lib.llama_generate.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
        self.lib.llama_generate.restype = ctypes.c_char_p
    
    def initialize_model(self, model_path: str) -> bool:
        """Initialize the LLaMA model"""
        if not self.lib:
            return False
        try:
            self.model_ptr = self.lib.llama_init(model_path.encode('utf-8'))
            return self.model_ptr is not None
        except Exception as e:
            print(f"Error initializing model: {e}")
            return False
    
    def generate_text(self, prompt: str, max_tokens: int = 100) -> Optional[str]:
        """Generate text using the model"""
        if not self.lib or not hasattr(self, 'model_ptr'):
            return None
        try:
            result = self.lib.llama_generate(
                self.model_ptr,
                prompt.encode('utf-8'),
                max_tokens
            )
            return result.decode('utf-8') if result else None
        except Exception as e:
            print(f"Error generating text: {e}")
            return None

# Usage example
if __name__ == "__main__":
    llama = LlamaRustFFI()
    if llama.initialize_model("./models/llama-2-7b-chat.gguf"):
        response = llama.generate_text("Hello, I'm a truck driver and I need help with", 100)
        print(f"Generated: {response}")
EOF

echo "Project structure created successfully!"
echo ""
echo "Next steps:"
echo "1. cd ~/ai-projects"
echo "2. cp .env.example .env (and fill in your API keys)"
echo "3. Create PostgreSQL database: createdb ai_dev"
echo "4. Install Python packages: pip install -r requirements.txt"
echo "5. Build your Rust FFI library"
echo "6. Start developing!"
echo ""
echo "Directory structure:"
tree ~/ai-projects -L 2 2>/dev/null || find ~/ai-projects -type d | head -20