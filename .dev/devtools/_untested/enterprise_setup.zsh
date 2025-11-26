#!/usr/bin/env zsh

#######################################################
# ENTERPRISE MICROSERVICES REPO SETUP
# GO APIs + Python AI/Web + Database Stack
#######################################################

# ========================
# DATABASE RECOMMENDATIONS
# ========================

# For your stack, here's the enterprise database setup:

# PRIMARY DATABASE
# PostgreSQL - The enterprise standard for microservices
# - ACID compliance
# - JSON support for flexible schemas
# - Full-text search
# - Excellent Go and Python support
# - Scales to billions of rows

# CACHE LAYER
# Redis - In-memory data structure store
# - Sub-millisecond response times
# - Pub/Sub for real-time features
# - Session storage
# - API response caching

# AI/ML DATA
# Vector Database for AI embeddings:
# - Qdrant (Rust-based, blazing fast)
# - Or Pinecone (managed service)
# - Or pgvector extension for PostgreSQL

# TIME-SERIES DATA (if needed)
# InfluxDB - for metrics, logs, IoT data

# ========================
# REPOSITORY STRUCTURE
# ========================

create_microservices_repo() {
    local project_name="enterprise-stack"

    echo "🏗️  Creating enterprise microservices repository..."

    # Create main project structure
    mkdir -p "$project_name/services/api-gateway"
    mkdir -p "$project_name/services/auth-service"
    mkdir -p "$project_name/services/user-service"
    mkdir -p "$project_name/services/ai-service"
    mkdir -p "$project_name/web/frontend"
    mkdir -p "$project_name/web/admin"
    mkdir -p "$project_name/shared/proto"
    mkdir -p "$project_name/shared/configs"
    mkdir -p "$project_name/shared/scripts"
    mkdir -p "$project_name/infrastructure/docker"
    mkdir -p "$project_name/infrastructure/k8s"
    mkdir -p "$project_name/infrastructure/terraform"
    mkdir -p "$project_name/databases/migrations"
    mkdir -p "$project_name/databases/seeds"
    mkdir -p "$project_name/databases/schemas"
    mkdir -p "$project_name/docs/api"
    mkdir -p "$project_name/docs/architecture"
    mkdir -p "$project_name/docs/deployment"


    cd "$project_name"

    # Initialize git repository
    git init

    # ========================
    # ROOT CONFIGURATION FILES
    # ========================

    # Docker Compose for local development
    cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  # Databases
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: enterprise_db
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./databases/migrations:/docker-entrypoint-initdb.d

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # Vector database for AI
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  # Go API Gateway
  api-gateway:
    build:
      context: ./services/api-gateway
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
      - JWT_SECRET=your-secret-key
    depends_on:
      - postgres
      - redis

  # Go Auth Service
  auth-service:
    build:
      context: ./services/auth-service
      dockerfile: Dockerfile
    ports:
      - "8081:8081"
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis

  # Go User Service
  user-service:
    build:
      context: ./services/user-service
      dockerfile: Dockerfile
    ports:
      - "8082:8082"
    environment:
      - DB_HOST=postgres
    depends_on:
      - postgres

  # Python AI Service
  ai-service:
    build:
      context: ./services/ai-service
      dockerfile: Dockerfile
    ports:
      - "8083:8083"
    environment:
      - QDRANT_HOST=qdrant
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    depends_on:
      - qdrant

  # Python Web Frontend
  web-frontend:
    build:
      context: ./web/frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - API_GATEWAY_URL=http://api-gateway:8080
    depends_on:
      - api-gateway

volumes:
  postgres_data:
  redis_data:
  qdrant_data:
EOF

    # Environment variables template
    cat > .env.example <<'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=enterprise_db
DB_USER=dev
DB_PASSWORD=devpass

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Vector Database
QDRANT_HOST=localhost
QDRANT_PORT=6333

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this

# AI Configuration
OPENAI_API_KEY=your-openai-api-key
HUGGING_FACE_API_KEY=your-hf-api-key

# Environment
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=info
EOF

    # ========================
    # GO API GATEWAY SERVICE
    # ========================

    echo "🔧 Setting up Go API Gateway..."

    cd services/api-gateway
    go mod init api-gateway

    # Go dependencies
    cat > go.mod <<'EOF'
module api-gateway

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/golang-jwt/jwt/v5 v5.0.0
    github.com/go-redis/redis/v8 v8.11.5
    gorm.io/gorm v1.25.4
    gorm.io/driver/postgres v1.5.2
    github.com/joho/godotenv v1.4.0
)
EOF

    # Main API Gateway code
    cat > main.go <<'EOF'
package main

import (
    "log"
    "net/http"
    "os"

    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
)

func main() {
    // Load environment variables
    if err := godotenv.Load(); err != nil {
        log.Printf("No .env file found")
    }

    // Initialize Gin router
    r := gin.Default()

    // Health check
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "status": "healthy",
            "service": "api-gateway",
        })
    })

    // API routes
    api := r.Group("/api/v1")
    {
        // Proxy to auth service
        api.Any("/auth/*path", proxyToService("auth-service", "8081"))

        // Proxy to user service
        api.Any("/users/*path", proxyToService("user-service", "8082"))

        // Proxy to AI service
        api.Any("/ai/*path", proxyToService("ai-service", "8083"))
    }

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("API Gateway starting on port %s", port)
    r.Run(":" + port)
}

func proxyToService(service, port string) gin.HandlerFunc {
    return func(c *gin.Context) {
        // TODO: Implement service proxy logic
        c.JSON(http.StatusOK, gin.H{
            "message": "Proxying to " + service,
            "path": c.Param("path"),
        })
    }
}
EOF

    # Dockerfile for Go service
    cat > Dockerfile <<'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]
EOF

    cd ../..

    # ========================
    # PYTHON AI SERVICE
    # ========================

    echo "🤖 Setting up Python AI Service..."

    cd services/ai-service

    # Python requirements
    cat > requirements.txt <<'EOF'
# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0

# AI/ML Libraries
openai==1.3.5
transformers==4.35.2
torch==2.1.1
sentence-transformers==2.2.2
numpy==1.24.4
pandas==2.1.3

# Vector Database
qdrant-client==1.6.9

# Template Engine
jinja2==3.1.2

# Database
psycopg2-binary==2.9.9
sqlalchemy==2.0.23

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
httpx==0.25.2
EOF

    # Main AI service code
    cat > main.py <<'EOF'
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
from dotenv import load_dotenv
import openai
from qdrant_client import QdrantClient
from transformers import pipeline

# Load environment variables
load_dotenv()

app = FastAPI(title="AI Service", version="1.0.0")

# Initialize AI models and clients
openai.api_key = os.getenv("OPENAI_API_KEY")
qdrant_client = QdrantClient(host=os.getenv("QDRANT_HOST", "localhost"))

# Initialize transformers pipeline
sentiment_analyzer = pipeline("sentiment-analysis")

class TextInput(BaseModel):
    text: str

class ChatInput(BaseModel):
    message: str
    conversation_id: str = None

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "ai-service"}

@app.post("/analyze/sentiment")
async def analyze_sentiment(input_data: TextInput):
    try:
        result = sentiment_analyzer(input_data.text)
        return {"sentiment": result[0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat/completion")
async def chat_completion(input_data: ChatInput):
    try:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": input_data.message}]
        )
        return {"response": response.choices[0].message.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/embeddings/create")
async def create_embeddings(input_data: TextInput):
    try:
        # Create embeddings using OpenAI
        response = openai.embeddings.create(
            model="text-embedding-ada-002",
            input=input_data.text
        )
        embedding = response.data[0].embedding

        # Store in vector database
        # TODO: Implement Qdrant storage

        return {"embedding": embedding[:10]}  # Return first 10 dimensions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8083)
EOF

    # Dockerfile for Python service
    cat > Dockerfile <<'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

EXPOSE 8083
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8083"]
EOF

    cd ../..

    # ========================
    # PYTHON WEB FRONTEND
    # ========================

    echo "🌐 Setting up Python Web Frontend..."

    cd web/frontend

    # Web frontend requirements
    cat > requirements.txt <<'EOF'
# Web Framework
flask==3.0.0
flask-cors==4.0.0

# Template Engine
jinja2==3.1.2

# HTTP Client
httpx==0.25.2
requests==2.31.0

# Environment
python-dotenv==1.0.0

# Development
flask-debugtoolbar==0.13.1
EOF

    # Flask app with Jinja2 templates
    cat > app.py <<'EOF'
from flask import Flask, render_template, request, jsonify
import httpx
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# API Gateway URL
API_GATEWAY_URL = os.getenv('API_GATEWAY_URL', 'http://localhost:8080')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/ai')
def ai_interface():
    return render_template('ai_interface.html')

@app.route('/api/chat', methods=['POST'])
async def chat():
    try:
        data = request.get_json()
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{API_GATEWAY_URL}/api/v1/ai/chat/completion",
                json=data
            )
            return response.json()
    except Exception as e:
        return {"error": str(e)}, 500

@app.route('/api/sentiment', methods=['POST'])
async def analyze_sentiment():
    try:
        data = request.get_json()
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{API_GATEWAY_URL}/api/v1/ai/analyze/sentiment",
                json=data
            )
            return response.json()
    except Exception as e:
        return {"error": str(e)}, 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)
EOF

    # Create templates directory and base template
    mkdir -p templates

    cat > templates/base.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Enterprise AI Stack{% endblock %}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100">
    <nav class="bg-blue-600 text-white p-4">
        <div class="container mx-auto flex justify-between items-center">
            <h1 class="text-xl font-bold">Enterprise Stack</h1>
            <div class="space-x-4">
                <a href="/" class="hover:underline">Home</a>
                <a href="/ai" class="hover:underline">AI Interface</a>
            </div>
        </div>
    </nav>

    <main class="container mx-auto mt-8 px-4">
        {% block content %}{% endblock %}
    </main>
</body>
</html>
EOF

    cat > templates/index.html <<'EOF'
{% extends "base.html" %}

{% block content %}
<div class="max-w-4xl mx-auto">
    <h1 class="text-4xl font-bold text-center mb-8">Enterprise Microservices Stack</h1>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-lg shadow-lg">
            <h3 class="text-xl font-semibold mb-4">Go APIs</h3>
            <p class="text-gray-600">High-performance microservices built with Go</p>
            <ul class="mt-4 space-y-2">
                <li>• API Gateway</li>
                <li>• Auth Service</li>
                <li>• User Service</li>
            </ul>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-lg">
            <h3 class="text-xl font-semibold mb-4">Python AI</h3>
            <p class="text-gray-600">AI/ML services with modern frameworks</p>
            <ul class="mt-4 space-y-2">
                <li>• OpenAI Integration</li>
                <li>• Sentiment Analysis</li>
                <li>• Vector Embeddings</li>
            </ul>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-lg">
            <h3 class="text-xl font-semibent mb-4">Database Stack</h3>
            <p class="text-gray-600">Enterprise-grade data storage</p>
            <ul class="mt-4 space-y-2">
                <li>• PostgreSQL</li>
                <li>• Redis Cache</li>
                <li>• Vector DB</li>
            </ul>
        </div>
    </div>

    <div class="mt-12 text-center">
        <a href="/ai" class="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition">
            Try AI Interface
        </a>
    </div>
</div>
{% endblock %}
EOF

    cd ../..

    # ========================
    # DATABASE SETUP
    # ========================

    echo "🗄️  Setting up database structure..."

    cd databases

    # Database initialization script
    cat > init.sql <<'EOF'
-- Create databases
CREATE DATABASE enterprise_db;
CREATE DATABASE enterprise_test;

-- Create extensions
\c enterprise_db;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sessions table
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI conversations table
CREATE TABLE ai_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI messages table
CREATE TABLE ai_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    tokens_used INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON user_sessions(expires_at);
CREATE INDEX idx_conversations_user_id ON ai_conversations(user_id);
CREATE INDEX idx_messages_conversation_id ON ai_messages(conversation_id);
EOF

    cd ..

    # ========================
    # DEVELOPMENT SCRIPTS
    # ========================

    echo "⚙️  Creating development scripts..."

    mkdir -p scripts

    # Development setup script
    cat > scripts/dev-setup.sh <<'EOF'
#!/bin/bash

echo "🚀 Setting up development environment..."

# Copy environment file
if [ ! -f .env ]; then
    cp .env.example .env
    echo "📝 Created .env file - please update with your values"
fi

# Start databases
echo "🗄️  Starting databases..."
docker-compose up -d postgres redis qdrant

# Wait for databases to be ready
echo "⏳ Waiting for databases to be ready..."
sleep 10

# Install Go dependencies
echo "🔧 Installing Go dependencies..."
cd services/api-gateway && go mod tidy && cd ../..

# Install Python dependencies for AI service
echo "🤖 Installing AI service dependencies..."
cd services/ai-service && pip install -r requirements.txt && cd ../..

# Install Python dependencies for web frontend
echo "🌐 Installing web frontend dependencies..."
cd web/frontend && pip install -r requirements.txt && cd ../..

echo "✅ Development environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Update .env file with your API keys"
echo "2. Run: docker-compose up"
echo "3. Visit: http://localhost:3000"
EOF

    chmod +x scripts/dev-setup.sh

    # Production deployment script
    cat > scripts/deploy.sh <<'EOF'
#!/bin/bash

echo "🚀 Deploying to production..."

# Build all services
docker-compose build

# Deploy with zero downtime
docker-compose up -d

echo "✅ Deployment complete!"
EOF

    chmod +x scripts/deploy.sh

    # ========================
    # DOCUMENTATION
    # ========================

    echo "📚 Creating documentation..."

    # Main README
    cat > README.md <<'EOF'
# Enterprise Microservices Stack

A production-ready microservices architecture with:
- **Go** - High-performance API services
- **Python** - AI/ML and web frontend
- **PostgreSQL** - Primary database
- **Redis** - Caching and sessions
- **Qdrant** - Vector database for AI

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Frontend  │    │   API Gateway   │    │   Auth Service  │
│   (Python)      │───▶│   (Go)          │───▶│   (Go)          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │   AI Service    │    │  User Service   │
                       │   (Python)      │    │   (Go)          │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │     Qdrant      │    │   PostgreSQL    │
                       │  (Vector DB)    │    │   + Redis       │
                       └─────────────────┘    └─────────────────┘
```

## Quick Start

```bash
# 1. Setup development environment
./scripts/dev-setup.sh

# 2. Start all services
docker-compose up

# 3. Access the application
open http://localhost:3000
```

## Services

- **API Gateway** (Go) - Port 8080
- **Auth Service** (Go) - Port 8081
- **User Service** (Go) - Port 8082
- **AI Service** (Python) - Port 8083
- **Web Frontend** (Python) - Port 3000

## Databases

- **PostgreSQL** - Port 5432
- **Redis** - Port 6379
- **Qdrant** - Port 6333

## Environment Variables

Copy `.env.example` to `.env` and update with your values:

```bash
# Required for AI features
OPENAI_API_KEY=your-openai-api-key

# Database passwords (change in production)
DB_PASSWORD=your-secure-password
JWT_SECRET=your-jwt-secret
```
EOF

    # Create .gitignore
    cat > .gitignore <<'EOF'
# Environment
.env
.env.local

# Go
vendor/
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out
go.work

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
venv/
env/
ENV/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Database
*.db
*.sqlite

# Docker
docker-compose.override.yml
EOF

    cd ..

    echo ""
    echo "🎉 Enterprise microservices repository created!"
    echo ""
    echo "📁 Repository structure:"
    echo "├── services/          # Go microservices"
    echo "│   ├── api-gateway/   # Main API gateway"
    echo "│   ├── auth-service/  # Authentication"
    echo "│   ├── user-service/  # User management"
    echo "│   └── ai-service/    # Python AI/ML service"
    echo "├── web/frontend/      # Python web app with Jinja2"
    echo "├── databases/         # SQL schemas and migrations"
    echo "├── scripts/           # Development and deployment scripts"
    echo "└── docker-compose.yml # Full stack orchestration"
    echo ""
    echo "🚀 Next steps:"
    echo "1. cd $project_name"
    echo "2. ./scripts/dev-setup.sh"
    echo "3. Update .env with your API keys"
    echo "4. docker-compose up"
    echo ""
    echo "🌐 Access points:"
    echo "• Web Frontend: http://localhost:3000"
    echo "• API Gateway: http://localhost:8080"
    echo "• AI Service: http://localhost:8083"
}

# Run the setup
create_microservices_repo "$1"
