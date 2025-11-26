#!/bin/bash

# Create configuration files for your AI projects
cd ~/ai-projects

# Database configuration
cat > configs/database.yaml << 'EOF'
postgresql:
  host: localhost
  port: 5432
  database: ai_dev
  user: root
  
redis:
  host: localhost
  port: 6379
  db: 0
  
duckdb:
  path: ./data/analytics.duckdb
EOF

# Model configuration
cat > configs/models.yaml << 'EOF'
llama:
  model_path: ./models/local/llama-2-7b-chat
  context_length: 4096
  max_tokens: 2048
  temperature: 0.7
  
embeddings:
  model: sentence-transformers/all-MiniLM-L6-v2
  cache_dir: ./models/embeddings
  batch_size: 32
  
inference:
  device: cuda
  batch_size: 8
  max_new_tokens: 512
  do_sample: true
  temperature: 0.8
  top_p: 0.9
EOF

# Environment variables template
cat > .env.example << 'EOF'
# Database URLs
DATABASE_URL=postgresql://root@localhost/ai_dev
REDIS_URL=redis://localhost:6379
DUCKDB_PATH=./data/analytics.duckdb

# API Keys (replace with your actual keys)
OPENAI_API_KEY=your_openai_key_here
HUGGINGFACE_TOKEN=your_hf_token_here

# Model paths
LLAMA_MODEL_PATH=./models/local/llama-2-7b-chat
EMBEDDINGS_MODEL=sentence-transformers/all-MiniLM-L6-v2

# Server settings
BACKEND_PORT=8000
FRONTEND_PORT=3000
MODEL_SERVER_PORT=8001
WEBSOCKET_PORT=8002

# Truck driver data collection
TRUCKING_DATA_DB=./data/truck_driver_data.duckdb
CONVERSATION_LOG_DIR=./data/conversations
EOF

# Create a simple FastAPI backend
cat > chatgpt-clone/backend/main.py << 'EOF'
from fastapi import FastAPI, WebSocket, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import redis
import json
import uuid
from datetime import datetime
from typing import List, Optional
import asyncio

app = FastAPI(title="Custom ChatGPT API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Redis connection for session management
try:
    redis_client = redis.Redis(host='localhost', port=6379, db=0)
except:
    redis_client = None
    print("Redis not available - sessions will not persist")

class ChatMessage(BaseModel):
    message: str
    user_id: Optional[str] = None
    conversation_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    conversation_id: str
    timestamp: datetime
    tokens_used: int = 0

@app.get("/")
async def root():
    return {"message": "Custom ChatGPT Clone API", "status": "running"}

@app.get("/health")
async def health_check():
    redis_status = False
    if redis_client:
        try:
            redis_status = redis_client.ping()
        except:
            pass
    
    return {
        "status": "healthy",
        "redis": redis_status,
        "timestamp": datetime.now()
    }

@app.post("/chat", response_model=ChatResponse)
async def chat_completion(message: ChatMessage):
    # Generate conversation ID if not provided
    conversation_id = message.conversation_id or str(uuid.uuid4())
    
    # TODO: Replace with your actual model inference
    # For now, simple echo with truck driving context
    if "truck" in message.message.lower() or "driving" in message.message.lower():
        response_text = f"As an AI assistant for truck drivers, I understand you're asking about: {message.message}. This is a placeholder response."
    else:
        response_text = f"I received your message: {message.message}. This is a placeholder response from your custom ChatGPT clone."
    
    # Store conversation in Redis if available
    if redis_client:
        try:
            conversation_key = f"conversation:{conversation_id}"
            redis_client.lpush(conversation_key, json.dumps({
                "timestamp": datetime.now().isoformat(),
                "user_message": message.message,
                "ai_response": response_text,
                "user_id": message.user_id
            }))
            redis_client.expire(conversation_key, 86400 * 7)  # 7 days
        except Exception as e:
            print(f"Redis error: {e}")
    
    return ChatResponse(
        response=response_text,
        conversation_id=conversation_id,
        timestamp=datetime.now(),
        tokens_used=len(response_text.split())  # Simple token approximation
    )

@app.websocket("/ws/{conversation_id}")
async def websocket_endpoint(websocket: WebSocket, conversation_id: str):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Process the message (placeholder)
            user_message = message_data.get("message", "")
            
            # TODO: Replace with actual model inference
            if "truck" in user_message.lower():
                ai_response = f"Truck driving assistance: {user_message}"
            else:
                ai_response = f"AI Response: {user_message}"
            
            response = {
                "response": ai_response,
                "conversation_id": conversation_id,
                "timestamp": datetime.now().isoformat(),
                "type": "message"
            }
            
            await websocket.send_text(json.dumps(response))
            
    except Exception as e:
        print(f"WebSocket error: {e}")
        await websocket.close()

@app.get("/conversations/{conversation_id}")
async def get_conversation(conversation_id: str):
    if not redis_client:
        return {"error": "Session storage not available"}
    
    try:
        conversation_key = f"conversation:{conversation_id}"
        messages = redis_client.lrange(conversation_key, 0, -1)
        return {
            "conversation_id": conversation_id,
            "messages": [json.loads(msg) for msg in messages]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# Create model server for inference
cat > chatgpt-clone/model-server/server.py << 'EOF'
from fastapi import FastAPI
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
import uvicorn
from pydantic import BaseModel
from typing import Optional
import os

app = FastAPI(title="Model Inference Server")

# Global variables for model and tokenizer
model = None
tokenizer = None
device = "cuda" if torch.cuda.is_available() else "cpu"

class GenerationRequest(BaseModel):
    prompt: str
    max_tokens: int = 100
    temperature: float = 0.8
    top_p: float = 0.9
    do_sample: bool = True

class GenerationResponse(BaseModel):
    generated_text: str
    tokens_used: int
    model_name: str

@app.on_event("startup")
async def load_model():
    global model, tokenizer
    print("Loading model...")
    
    # TODO: Replace with your actual model path or Rust FFI
    # For now, we'll use a placeholder
    print(f"Device: {device}")
    print("Model loaded successfully! (Placeholder)")

@app.post("/generate", response_model=GenerationResponse)
async def generate_text(request: GenerationRequest):
    # TODO: Implement actual text generation
    # This could use your Rust FFI bindings to llama.cpp
    
    # Placeholder response
    generated_text = f"Generated response for: {request.prompt[:100]}..."
    
    return GenerationResponse(
        generated_text=generated_text,
        tokens_used=len(generated_text.split()),
        model_name="Custom LLM (Placeholder)"
    )

@app.get("/model/info")
async def model_info():
    return {
        "model_name": "Custom LLM",
        "context_length": 4096,
        "device": device,
        "cuda_available": torch.cuda.is_available(),
        "status": "loaded" if model else "not_loaded"
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "device": device,
        "model_loaded": model is not None
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
EOF

# Create truck driver data collector
cat > scripts/truck_data_collector.py << 'EOF'
import duckdb
import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime
import time

class TruckDriverDataCollector:
    def __init__(self, db_path="./data/truck_driver_data.duckdb"):
        self.db = duckdb.connect(db_path)
        self.setup_database()
    
    def setup_database(self):
        """Create tables for truck driver data"""
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS conversations (
                id INTEGER PRIMARY KEY,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                driver_id VARCHAR,
                message TEXT,
                response TEXT,
                context VARCHAR,
                session_id VARCHAR
            )
        """)
        
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS training_data (
                id INTEGER PRIMARY KEY,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                source VARCHAR,
                content TEXT,
                category VARCHAR,
                keywords VARCHAR[],
                processed BOOLEAN DEFAULT FALSE
            )
        """)
        
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS trucking_resources (
                id INTEGER PRIMARY KEY,
                url VARCHAR,
                title VARCHAR,
                content TEXT,
                scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                category VARCHAR
            )
        """)
    
    def store_conversation(self, driver_id, message, response, context="", session_id=""):
        """Store truck driver conversations for training"""
        self.db.execute("""
            INSERT INTO conversations (driver_id, message, response, context, session_id)
            VALUES (?, ?, ?, ?, ?)
        """, (driver_id, message, response, context, session_id))
        print(f"Stored conversation for driver {driver_id}")
    
    def collect_trucking_resources(self):
        """Collect data from trucking websites"""
        sources = [
            {"url": "https://www.truckinginfo.com/", "category": "news"},
            {"url": "https://www.overdriveonline.com/", "category": "industry"},
            # Add more sources as needed
        ]
        
        for source in sources:
            try:
                print(f"Collecting from {source['url']}")
                # Implement your scraping logic here
                # For now, just log the attempt
                self.db.execute("""
                    INSERT INTO trucking_resources (url, title, category)
                    VALUES (?, ?, ?)
                """, (source['url'], f"Scraped from {source['url']}", source['category']))
                
            except Exception as e:
                print(f"Error collecting from {source['url']}: {e}")
    
    def get_conversation_history(self, driver_id):
        """Get conversation history for a specific driver"""
        return self.db.execute("""
            SELECT * FROM conversations 
            WHERE driver_id = ? 
            ORDER BY timestamp DESC
        """, (driver_id,)).fetchall()
    
    def export_training_data(self):
        """Export data for model training"""
        return self.db.execute("""
            SELECT message, response, context 
            FROM conversations 
            WHERE LENGTH(message) > 10 AND LENGTH(response) > 10
        """).fetchall()

if __name__ == "__main__":
    collector = TruckDriverDataCollector()
    
    # Example usage
    collector.store_conversation(
        driver_id="driver_001",
        message="How do I calculate my hours of service?",
        response="You can drive up to 11 hours after 10 consecutive hours off duty...",
        context="hours_of_service",
        session_id="session_123"
    )
    
    print("Data collector initialized and example data stored!")
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
# Core ML/AI
torch
torchvision  
torchaudio
transformers
accelerate
sentence-transformers
langchain
chromadb

# Databases
redis
psycopg2-binary
duckdb
sqlalchemy
alembic

# Web framework
fastapi
uvicorn
websockets
gradio
streamlit
pydantic

# Data processing
pandas
numpy
requests
beautifulsoup4
scrapy
matplotlib
seaborn
plotly

# Development
black
isort
mypy
flake8
pytest
python-dotenv
EOF

echo "Configuration files created successfully!"
echo "Next steps:"
echo "1. Copy .env.example to .env and fill in your API keys"
echo "2. Install remaining packages: pip install -r requirements.txt"
echo "3. Set up PostgreSQL database: createdb ai_dev"
echo "4. Test the APIs: python chatgpt-clone/backend/main.py"
echo "5. Start building your Rust FFI integration!"