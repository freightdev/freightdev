# llama_runner Technical Manual

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Installation and Setup](#installation-and-setup)
3. [Model Configuration](#model-configuration)
4. [API Reference](#api-reference)
5. [Agent Integration Patterns](#agent-integration-patterns)
6. [Performance Optimization](#performance-optimization)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Usage](#advanced-usage)

## Architecture Overview

### Core Components

llama_runner consists of several modular components:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CLI Interface │    │   Agent API      │    │  Interactive    │
│   (main.rs)     │    │   (api/mod.rs)   │    │  Runner         │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │            Core Library (lib.rs)                │
         └─────────────────────────────────────────────────┘
                                 │
    ┌────────────┬────────────────┼────────────────┬────────────┐
    │            │                │                │            │
┌───▼───┐  ┌────▼────┐  ┌────────▼────────┐  ┌───▼───┐  ┌────▼────┐
│Tokens │  │ Loaders │  │    Bindings     │  │Prompts│  │ Errors  │
│       │  │         │  │   (llama.cpp    │  │       │  │         │
│       │  │         │  │     FFI)        │  │       │  │         │
└───────┘  └─────────┘  └─────────────────┘  └───────┘  └─────────┘
```

### Execution Modes

1. **Stateless Mode**: Create context → Generate → Destroy context
2. **Stateful Mode**: Persistent context with manual memory management
3. **Interactive Mode**: REPL interface with pronunciation optimization

## Installation and Setup

### Prerequisites

Install system dependencies:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install cmake build-essential pkg-config

# macOS
brew install cmake

# Windows (using MSVC)
# Install Visual Studio with C++ tools
# Or use vcpkg: vcpkg install cmake
```

### Project Setup

1. **Initialize llama.cpp submodule:**
```bash
git submodule add https://github.com/ggerganov/llama.cpp.git
git submodule update --init --recursive
```

2. **Build the project:**
```bash
cargo build --release
```

3. **Verify installation:**
```bash
./target/release/llama-runner --help
```

### GPU Acceleration (Optional)

Enable GPU support during build:

```bash
# NVIDIA CUDA
LLAMA_CUDA=1 cargo build --release

# Apple Metal (macOS)
LLAMA_METAL=1 cargo build --release

# OpenBLAS
LLAMA_BLAS=1 cargo build --release
```

## Model Configuration

### Model Metadata Format

Each model requires a `model.json` configuration file:

```json
{
  "name": "Qwen 1.5 1.8B Chat",
  "path": "models/qwen1.5-1.8b-chat-q4_k_m.gguf",
  "architecture": "qwen",
  "parameters": "1.8B",
  "quantization": "Q4_K_M",
  "context_length": 4096,
  "description": "Quantized Qwen model optimized for chat"
}
```

### Supported Model Formats

- **GGUF**: Required format (llama.cpp native)
- **Quantization**: Q4_K_M, Q5_K_M, Q6_K, Q8_0, F16, F32
- **Architectures**: Llama, Qwen, Mistral, CodeLlama, Vicuna, etc.

### Model Organization

Recommended directory structure:
```
src/models/
├── qwen1.5-1.8b-chat/
│   ├── model.json
│   └── Q4_K_M/
│       └── qwen1.5-1.8b-chat-q4_k_m.gguf
├── codellama-7b/
│   ├── model.json
│   └── Q4_K_M/
│       └── codellama-7b-q4_k_m.gguf
```

## API Reference

### Core Types

```rust
pub struct LlamaRunner {
    // Manages model, context, and sampler lifecycle
}

pub struct GenerationParams {
    pub max_tokens: i32,      // Maximum tokens to generate
    pub temperature: f32,     // Randomness (0.0 = deterministic)
    pub top_p: f32,          // Nucleus sampling
    pub top_k: i32,          // Top-k sampling
    pub threads: i32,        // CPU threads for inference
    pub batch_threads: i32,  // CPU threads for batch processing
}

pub struct ContextInfo {
    pub used_tokens: usize,     // Current context usage
    pub total_capacity: usize,  // Maximum context size
    pub usage_percent: f32,     // Usage percentage
}
```

### Stateless Generation

Use for maximum performance when no conversation memory is needed:

```rust
use llama_runner::{LlamaRunner, GenerationParams};
use std::path::Path;

let runner = LlamaRunner::new(Path::new("model.json"))?;
let params = GenerationParams {
    max_tokens: 100,
    temperature: 0.1,
    ..Default::default()
};

let response = runner.generate_stateless("What is Rust?", params)?;
```

### Stateful Generation

Use for conversations requiring memory:

```rust
let mut runner = LlamaRunner::new(Path::new("model.json"))?;
runner.init_stateful(GenerationParams::default())?;

// Multi-turn conversation
let response1 = runner.generate_stateful("My name is Alice", 50)?;
let response2 = runner.generate_stateful("What's my name?", 50)?;

// Manual memory management
let info = runner.get_context_info()?;
if info.usage_percent > 80.0 {
    runner.gc_context(1000)?; // Keep recent 1000 tokens
}
```

### Quick API

Simplified interface for common use cases:

```rust
use llama_runner::quick;

// One-shot generation
let response = quick::generate_once(
    Path::new("model.json"), 
    "Explain photosynthesis", 
    200
)?;

// Persistent agent runner
let mut agent = quick::create_agent_runner(Path::new("model.json"))?;
```

## Agent Integration Patterns

### Pattern 1: Stateless Agent

For agents that don't need conversation memory:

```rust
pub struct StatelessAgent {
    model_path: PathBuf,
}

impl StatelessAgent {
    pub fn new(model_path: PathBuf) -> Self {
        Self { model_path }
    }
    
    pub fn process(&self, query: &str) -> Result<String> {
        quick::generate_once(&self.model_path, query, 200)
    }
}
```

### Pattern 2: Stateful Agent

For agents that maintain conversation context:

```rust
pub struct StatefulAgent {
    runner: LlamaRunner,
    context_limit: f32,
}

impl StatefulAgent {
    pub fn new(model_path: &Path) -> Result<Self> {
        let mut runner = LlamaRunner::new(model_path)?;
        runner.init_stateful(GenerationParams::default())?;
        
        Ok(Self { 
            runner, 
            context_limit: 75.0 
        })
    }
    
    pub fn process(&mut self, query: &str) -> Result<String> {
        // Auto-manage memory
        let info = self.runner.get_context_info()?;
        if info.usage_percent > self.context_limit {
            self.runner.gc_context(500)?;
        }
        
        self.runner.generate_stateful(query, 200)
    }
    
    pub fn reset(&mut self) -> Result<()> {
        self.runner.clear_context()
    }
}
```

### Pattern 3: MARK System Integration

For your specific agent ecosystem:

```rust
use llama_runner::prompts::agents;

pub struct MarkAgent {
    runner: LlamaRunner,
    agent_type: AgentType,
}

pub enum AgentType {
    BigBear,
    CargoConnect,
    TruckerTales,
    LegalLogger,
    MemoryMark,
}

impl MarkAgent {
    pub fn process_task(&mut self, input: &str) -> Result<String> {
        let prompt = match self.agent_type {
            AgentType::BigBear => agents::big_bear(input),
            AgentType::CargoConnect => agents::cargo_connect(input),
            AgentType::TruckerTales => agents::trucker_tales(input),
            AgentType::LegalLogger => agents::legal_logger(input),
            AgentType::MemoryMark => agents::memory_mark(input),
        };
        
        self.runner.generate_stateful(&prompt, 300)
    }
}
```

## Performance Optimization

### CPU Optimization

The build system automatically detects and enables:
- AVX2, FMA, AVX512 (x86_64)
- NEON (ARM64)
- Native CPU optimizations

### Memory Management Strategies

1. **Context Window Management:**
```rust
// Monitor usage
let info = runner.get_context_info()?;
println!("Memory usage: {:.1}%", info.usage_percent);

// Proactive cleanup at 80% usage
if info.usage_percent > 80.0 {
    runner.gc_context(info.total_capacity / 2)?;
}
```

2. **Batch Processing:**
```rust
// Process multiple prompts efficiently
let prompts = vec!["Query 1", "Query 2", "Query 3"];
let mut responses = Vec::new();

for prompt in prompts {
    let response = runner.generate_stateful(prompt, 100)?;
    responses.push(response);
}
```

### Threading Configuration

Optimal thread settings depend on your hardware:

```rust
let params = GenerationParams {
    threads: num_cpus::get() as i32 / 2,      // Half of available cores
    batch_threads: num_cpus::get() as i32 / 4, // Quarter for batch processing
    ..Default::default()
};
```

## Troubleshooting

### Common Build Issues

1. **Missing CMake:**
```
error: CMake must be installed to build llama.cpp
```
Solution: Install CMake and C++ compiler

2. **Bindgen Failures:**
```
error: Unable to find libclang
```
Solution: Install clang development headers
```bash
sudo apt install libclang-dev  # Ubuntu
brew install llvm              # macOS
```

3. **Link Errors:**
```
error: linking with `cc` failed
```
Solution: Ensure C++ standard library is available
```bash
sudo apt install libstdc++-dev
```

### Runtime Issues

1. **Model Loading Failures:**
```rust
// Check model file exists and is valid GGUF format
let metadata = load_model(Path::new("model.json"))?;
match validate_model(&metadata) {
    Ok(_) => println!("Model validation passed"),
    Err(e) => println!("Model validation failed: {}", e),
}
```

2. **Memory Issues:**
```rust
// Monitor context usage
let info = runner.get_context_info()?;
if info.usage_percent > 90.0 {
    println!("Warning: High memory usage");
    runner.clear_context()?;
}
```

3. **Generation Quality Issues:**
Adjust generation parameters:
```rust
let params = GenerationParams {
    temperature: 0.1,  // Lower = more consistent
    top_p: 0.9,        // Higher = more diverse
    top_k: 40,         // Moderate = balanced
    ..Default::default()
};
```

### Debug Mode

Enable verbose logging:
```bash
RUST_LOG=debug cargo run -- --model model.json --check
```

## Advanced Usage

### Custom Sampling Strategies

```rust
use llama_runner::tokens::create_sampler;

// Create custom sampler with specific parameters
let sampler = create_sampler(0.05, 0.95, 30); // Very conservative
```

### Batch Token Processing

```rust
use llama_runner::tokens::{tokenize, build_batch};

// Process tokens in batches for efficiency
let tokens = tokenize("Large input text", vocab, false);
let batch = build_batch(&tokens, 0);
```

### Model Switching

```rust
// Runtime model switching for different tasks
struct MultiModelAgent {
    chat_runner: LlamaRunner,
    code_runner: LlamaRunner,
}

impl MultiModelAgent {
    pub fn chat(&mut self, query: &str) -> Result<String> {
        self.chat_runner.generate_stateful(query, 200)
    }
    
    pub fn code(&mut self, query: &str) -> Result<String> {
        let prompt = format!("```rust\n// {}\n", query);
        self.code_runner.generate_stateful(&prompt, 500)
    }
}
```

### Pronunciation Customization

```rust
// Add custom pronunciation mappings
let mut mappings = HashMap::new();
mappings.insert("MyCompany".to_string(), "My Company".to_string());
mappings.insert("API_KEY".to_string(), "A-P-I Key".to_string());

// Apply preprocessing before generation
fn preprocess_prompt(text: &str, mappings: &HashMap<String, String>) -> String {
    let mut result = text.to_string();
    for (original, replacement) in mappings {
        result = result.replace(original, replacement);
    }
    result
}
```

### Integration with External Systems

```rust
// HTTP API wrapper
use warp::Filter;

#[tokio::main]
async fn main() {
    let runner = Arc::new(Mutex::new(
        quick::create_agent_runner(Path::new("model.json")).unwrap()
    ));
    
    let generate = warp::path("generate")
        .and(warp::post())
        .and(warp::body::json())
        .map(move |prompt: String| {
            let mut runner = runner.lock().unwrap();
            match runner.generate_stateful(&prompt, 200) {
                Ok(response) => warp::reply::json(&response),
                Err(e) => warp::reply::json(&format!("Error: {}", e)),
            }
        });
    
    warp::serve(generate).run(([127, 0, 0, 1], 3030)).await;
}
```

This manual covers the complete technical implementation of llama_runner for production deployment in your MARK agent ecosystem.