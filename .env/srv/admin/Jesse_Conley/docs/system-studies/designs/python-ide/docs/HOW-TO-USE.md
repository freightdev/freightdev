### **🚀 How to Use**

**1. Prepare your environment:**
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your settings
nano .env

# Make sure you have models directory
mkdir -p models
# Download your model files to models/
```

**2. Build and run:**
```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build

# View logs
docker-compose logs -f ai-assistant
```

**3. GPU version (if you have NVIDIA GPU):**
```bash
# Install nvidia-docker first
# Then uncomment the GPU service in docker-compose.yml

docker-compose up ai-assistant-gpu postgres -d
```

**4. Access your AI Assistant:**
- **Web Interface**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/ping

---

### **🔧 Environment Variables for Docker**

Create a `.env` file:
```bash
# Required
POSTGRES_PASSWORD=your_secure_db_password
SECRET_KEY=your_super_secret_key_for_sessions

# Optional
DEBUG=false
DEFAULT_MODEL=Llama-3.1-8B-Instruct-Q5_K_M.gguf
MODELS_PATH=./models
```

---

### **💡 Production Tips**

**Resource Limits:**
- **CPU**: 8GB+ RAM recommended for 8B models
- **GPU**: 12GB+ VRAM for GPU inference
- **Storage**: 50GB+ for models, data, logs

**Security:**
```bash
# Use secrets for production
echo "your_secure_password" | docker secret create postgres_password -
echo "your_super_secret_key" | docker secret create app_secret_key -
```

**Monitoring:**
```bash
# Monitor resource usage
docker stats

# Check logs
docker-compose logs -f --tail=100

# Backup data
docker run --rm -v ai_data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data
```