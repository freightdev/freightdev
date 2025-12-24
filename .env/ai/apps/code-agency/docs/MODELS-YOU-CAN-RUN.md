## Models You Can Run 🤖

### **📁 File Types Supported**

**🦙 GGUF Format (Recommended)**
- `.gguf` files - Modern llama.cpp format
- Quantized models (Q4_K_M, Q5_K_M, Q8_0, etc.)
- Best performance and compatibility
- Examples: `Llama-3.1-8B-Instruct-Q5_K_M.gguf`

**🏗️ Hugging Face Format**
- Transformers library compatible models
- Model folders with `config.json`, `pytorch_model.bin`, etc.
- Safetensors format (`.safetensors`)
- Examples: Any model from Hugging Face Hub

**📦 PyTorch Format**
- `.pt`, `.pth` files (with proper loading code)
- `.bin` files (PyTorch format)

---

### **🎯 Recommended Models by Use Case**

**💬 General Chat (CoDriver + ChatAgent)**
```
Llama-3.1-8B-Instruct-Q5_K_M.gguf        # 5.5GB - Great balance
Llama-3.1-7B-Instruct-Q4_K_M.gguf        # 4.1GB - Lighter option
Mistral-7B-Instruct-v0.3-Q5_K_M.gguf     # 4.9GB - Very capable
Qwen2.5-7B-Instruct-Q5_K_M.gguf          # 5.2GB - Excellent reasoning
```

**👨‍💻 Code Assistant (CodeAgent)**
```
CodeLlama-13B-Instruct-Q5_K_M.gguf       # 9.1GB - Best for coding
CodeLlama-7B-Instruct-Q4_K_M.gguf        # 4.2GB - Good coding, lighter
DeepSeek-Coder-6.7B-Instruct-Q5_K_M.gguf # 4.8GB - Strong coding model
Codestral-22B-v0.1-Q4_K_M.gguf           # 13GB - If you have RAM
```

**🧠 Best All-Around (Does Everything)**
```
Llama-3.1-8B-Instruct-Q5_K_M.gguf        # Great chat + decent coding
Qwen2.5-14B-Instruct-Q4_K_M.gguf         # Excellent at both (8.2GB)
```

---

### **📊 Model Size Guide**

| **RAM Available** | **Recommended Models** | **Notes** |
|---|---|---|
| 8GB | 7B Q4_K_M models | Tight but workable |
| 16GB | 7B Q5_K_M, 13B Q4_K_M | Sweet spot |
| 32GB | 13B Q5_K_M, 22B Q4_K_M | Very capable |
| 64GB+ | 34B+ models | Top tier performance |

---

### **🔥 Top Recommendations by RAM**

**16GB RAM (Most Common)**
```bash
# Best overall - does chat + coding well
Llama-3.1-8B-Instruct-Q5_K_M.gguf        # 5.5GB

# If you want specialized coding
CodeLlama-13B-Instruct-Q4_K_M.gguf       # 7.4GB

# Excellent reasoning
Qwen2.5-7B-Instruct-Q5_K_M.gguf          # 5.2GB
```

**32GB RAM (Recommended Setup)**
```bash
# Best coding model that fits
CodeLlama-13B-Instruct-Q5_K_M.gguf       # 9.1GB

# Or excellent all-around
Qwen2.5-14B-Instruct-Q4_K_M.gguf         # 8.2GB
Llama-3.1-8B-Instruct-Q8_0.gguf          # 8.5GB (higher quality)
```

---

### **📥 Where to Download**

**🤗 Hugging Face (Best Source)**
- Search for models with `GGUF` in the name
- Look for `TheBloke` quantized versions
- Example: `TheBloke/Llama-2-7B-Chat-GGUF`

**🦙 Direct from Model Creators**
- Meta (Llama models)
- Mistral AI (Mistral models)  
- DeepSeek (DeepSeek-Coder)

**📦 Popular GGUF Repositories**
```
microsoft/DialoGPT-medium
TheBloke/Llama-2-7B-Chat-GGUF
TheBloke/CodeLlama-13B-Instruct-GGUF
TheBloke/Mistral-7B-Instruct-v0.1-GGUF
```

---

### **⚙️ Model Loading in Your System**

**Your `download-models.sh` should grab:**
```bash
# Place in your models/ directory
models/
├── Llama-3.1-8B-Instruct-Q5_K_M.gguf       # Main chat model
├── CodeLlama-13B-Instruct-Q4_K_M.gguf      # Code model  
└── embeddings/
    └── all-MiniLM-L6-v2/                   # For embeddings
```

**Loading in Settings:**
1. Go to Settings → Model Settings
2. Select from available models
3. Click "Load Model" 
4. System will use it for all agents

**Agent-Specific Models (Advanced):**
- CoDriver can route to different models per agent
- ChatAgent → General model
- CodeAgent → Code-specialized model
- All configurable in settings

---

### **🎯 My Recommendation for You**

Since you want to replace ChatGPT/Claude and have coding assistance:

**If 16GB RAM:** `Llama-3.1-8B-Instruct-Q5_K_M.gguf`
- Excellent chat, good coding, 5.5GB
- Perfect balance for your use case

**If 32GB+ RAM:** `CodeLlama-13B-Instruct-Q5_K_M.gguf`  
- Outstanding coding, decent chat, 9.1GB
- Best for your IDE integration