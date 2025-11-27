# llama_runner

Rust FFI wrapper for llama.cpp optimized for agent integration and pronunciation accuracy.

## Overview

llama_runner provides both stateless and stateful LLM inference capabilities through a clean API designed for AI agent systems. Built specifically for integration with the MARK (Memory Aware Routing Kernel) system.

## Features

- **Stateless Generation**: Create context, generate, destroy for maximum speed
- **Stateful Generation**: Persistent context with manual memory management
- **Pronunciation Optimization**: Enhanced tokenization for proper name handling
- **Agent Integration**: Direct API for AI agent systems
- **Static Linking**: Maximum performance through direct FFI calls
- **Cross-Platform**: Windows, Linux, macOS support

## Quick Start

### Prerequisites

```bash
# Install dependencies
sudo apt install cmake build-essential  # Linux
brew install cmake                       # macOS

# Initialize llama.cpp submodule
git submodule add https://github.com/ggerganov/llama.cpp.git
git submodule update --init --recursive
```

### Build

```bash
cargo build --release
```

### Usage

#### CLI Interface

```bash
# Test model loading
./target/release/llama-runner --model model.json --check

# Interactive mode with pronunciation optimization
./target/release/llama-runner --model model.json --threads 8 --max 128
```

#### API Integration

```rust
use llama_runner::{create_agent_runner, generate_once, GenerationParams};

// One-shot generation (stateless)
let response = generate_once("model.json", "What is 2+2?", 50)?;

// Persistent conversations (stateful) 
let mut runner = create_agent_runner("model.json")?;
let response1 = runner.generate_stateful("First question", 100)?;
let response2 = runner.generate_stateful("Follow up", 100)?;
runner.clear_context()?; // Manual memory control
```

## API Reference

### Core Types

```rust
pub struct LlamaRunner {
    // Internal fields...
}

pub struct GenerationParams {
    pub max_tokens: i32,
    pub temperature: f32,
    pub top_p: f32,
    pub top_k: i32,
    pub threads: i32,
    pub batch_threads: i32,
}

pub struct ContextInfo {
    pub used_tokens: usize,
    pub total_capacity: usize,
    pub usage_percent: f32,
}
```

### Stateless Generation

```rust
impl LlamaRunner {
    pub fn new(json_path: &Path) -> Result<Self>
    pub fn generate_stateless(&self, prompt: &str, params: GenerationParams) -> Result<String>
}
```

### Stateful Generation

```rust
impl LlamaRunner {
    pub fn init_stateful(&mut self, params: GenerationParams) -> Result<()>
    pub fn generate_stateful(&mut self, prompt: &str, max_tokens: i32) -> Result<String>
    pub fn clear_context(&mut self) -> Result<()>
    pub fn get_context_info(&self) -> Result<ContextInfo>
    pub fn gc_context(&mut self, keep_recent: usize) -> Result<()>
}
```

### Quick API

```rust
pub mod quick {
    pub fn generate_once(model_path: &Path, prompt: &str, max_tokens: i32) -> Result<String>
    pub fn create_agent_runner(model_path: &Path) -> Result<LlamaRunner>
}
```

## Model Configuration

Models require a `model.json` metadata file:

```json
{
  "name": "Qwen 1.5 1.8B Chat",
  "path": "qwen1.5-1.8b-chat-q4_k_m.gguf",
  "architecture": "qwen",
  "parameters": "1.8B",
  "quantization": "Q4_K_M",
  "context_length": 4096,
  "description": "Quantized Qwen model for chat applications"
}
```

## Performance Optimization

### CPU Features

Build automatically detects and enables:
- AVX2, FMA, AVX512 (x86_64)
- NEON (ARM64)
- Native optimizations when not cross-compiling

### GPU Acceleration

```bash
# CUDA support
LLAMA_CUDA=1 cargo build --release

# Metal support (macOS)
LLAMA_METAL=1 cargo build --release
```

### Memory Management

```rust
// Check context usage
let info = runner.get_context_info()?;
println!("Memory usage: {}%", info.usage_percent);

// Garbage collect old tokens
if info.usage_percent > 80.0 {
    runner.gc_context(1000)?; // Keep recent 1000 tokens
}

// Full context clear
runner.clear_context()?;
```

## Agent Integration

### MARK System Agents

Built-in prompt templates for MARK system agents:

```rust
use llama_runner::prompts::agents;

// Big Bear - cargo routing
let prompt = agents::big_bear("Cargo: 40ft container, Chicago to LA");

// Cargo Connect - shipment coordination  
let prompt = agents::cargo_connect("Shipment #12345");

// Trucker Tales - industry wisdom
let prompt = agents::trucker_tales("New driver needs backing tips");

// Legal Logger - regulatory guidance
let prompt = agents::legal_logger("Hours of service question");

// Memory Mark - MARK system integration
let prompt = agents::memory_mark("Store conversation context");
```

### Custom Agent Integration

```rust
use llama_runner::{LlamaRunner, GenerationParams};

struct MyAgent {
    runner: LlamaRunner,
}

impl MyAgent {
    fn new(model_path: &Path) -> Result<Self> {
        let mut runner = LlamaRunner::new(model_path)?;
        runner.init_stateful(GenerationParams::default())?;
        Ok(Self { runner })
    }
    
    fn process(&mut self, input: &str) -> Result<String> {
        self.runner.generate_stateful(input, 200)
    }
    
    fn reset_memory(&mut self) -> Result<()> {
        self.runner.clear_context()
    }
}
```

## Pronunciation Features

Enhanced tokenization for proper pronunciation:

- Automatic mapping of technical terms (API -> A-P-I)
- CamelCase word boundary detection
- MARK system terminology optimization
- Quality scoring and testing

### Interactive Testing

```bash
# In interactive mode:
>> /test GitHub
Testing pronunciation of: 'GitHub'
  Processed: 'Git-Hub'  
  Quality score: 95%

>> /stats
Pronunciation Statistics:
  Average quality: 92%
```

## Project Structure

```
llama_runner/
├── build.rs              # Build configuration with optimizations
├── wrapper.h             # C header for bindgen
├── Cargo.toml           # Project dependencies
├── src/
│   ├── lib.rs           # Core library exports
│   ├── main.rs          # CLI entry point
│   ├── api/mod.rs       # Agent API interface
│   ├── bindings/mod.rs  # FFI bindings
│   ├── tokens/mod.rs    # Tokenization and batching
│   ├── loaders/model.rs # Model metadata loading
│   ├── prompts/mod.rs   # Prompt formatting
│   ├── runners/         # Interactive runners
│   └── errors/mod.rs    # Error types
└── bindings/            # Generated FFI bindings
```

## License

MIT License - See LICENSE file for details.

## Contributing

1. Ensure llama.cpp submodule is up to date
2. Run `cargo test` before submitting changes  
3. Update documentation for API changes
4. Test pronunciation features with new models