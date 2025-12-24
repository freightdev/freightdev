# llama_runner API Documentation

## Overview

llama_runner provides both high-level and low-level APIs for LLM inference. The API is designed for agent integration with explicit control over memory management and execution modes.

## Core API

### LlamaRunner

The main interface for model interaction.

```rust
pub struct LlamaRunner {
    // Private fields
}
```

#### Construction

```rust
impl LlamaRunner {
    pub fn new(json_path: &Path) -> Result<Self>
}
```

**Parameters:**
- `json_path`: Path to model.json configuration file

**Returns:** `Result<LlamaRunner, LlamaError>`

**Example:**
```rust
let runner = LlamaRunner::new(Path::new("models/qwen/model.json"))?;
```

#### Stateless Generation

```rust
pub fn generate_stateless(
    &self, 
    prompt: &str, 
    params: GenerationParams
) -> Result<String>
```

Creates context, generates response, destroys context. Maximum performance for single queries.

**Parameters:**
- `prompt`: Input text to process
- `params`: Generation parameters

**Returns:** `Result<String, LlamaError>`

**Example:**
```rust
let params = GenerationParams {
    max_tokens: 100,
    temperature: 0.1,
    ..Default::default()
};
let response = runner.generate_stateless("What is Rust?", params)?;
```

#### Stateful Generation

```rust
pub fn init_stateful(&mut self, params: GenerationParams) -> Result<()>
pub fn generate_stateful(&mut self, prompt: &str, max_tokens: i32) -> Result<String>
```

Maintains persistent context between calls. Required for conversational agents.

**Initialization:**
```rust
runner.init_stateful(GenerationParams::default())?;
```

**Generation:**
```rust
let response = runner.generate_stateful("Follow-up question", 150)?;
```

#### Context Management

```rust
pub fn clear_context(&mut self) -> Result<()>
pub fn get_context_info(&self) -> Result<ContextInfo>
pub fn gc_context(&mut self, keep_recent: usize) -> Result<()>
pub fn cleanup_stateful(&mut self)
```

**Context Information:**
```rust
let info = runner.get_context_info()?;
println!("Usage: {:.1}% ({}/{})", 
    info.usage_percent, 
    info.used_tokens, 
    info.total_capacity
);
```

**Garbage Collection:**
```rust
// Keep most recent 1000 tokens, clear the rest
runner.gc_context(1000)?;
```

#### Utility Methods

```rust
pub fn model_info(&self) -> &ModelMetadata
pub fn supports_embeddings(&self) -> bool
```

## Data Types

### GenerationParams

```rust
pub struct GenerationParams {
    pub max_tokens: i32,      // Default: 256
    pub temperature: f32,     // Default: 0.1
    pub top_p: f32,          // Default: 0.9
    pub top_k: i32,          // Default: 40
    pub threads: i32,        // Default: 8
    pub batch_threads: i32,  // Default: 4
}
```

### ContextInfo

```rust
pub struct ContextInfo {
    pub used_tokens: usize,
    pub total_capacity: usize,
    pub usage_percent: f32,
}
```

### ModelMetadata

```rust
pub struct ModelMetadata {
    pub name: String,
    pub path: String,
    pub architecture: String,
    pub parameters: String,
    pub quantization: String,
    pub context_length: Option<u32>,
    pub description: Option<String>,
}
```

## Quick API

Simplified interface for common patterns.

### Functions

```rust
pub mod quick {
    pub fn generate_once(
        model_path: &Path, 
        prompt: &str, 
        max_tokens: i32
    ) -> Result<String>
    
    pub fn create_agent_runner(model_path: &Path) -> Result<LlamaRunner>
}
```

### Examples

```rust
// One-shot generation
let response = quick::generate_once(
    Path::new("model.json"),
    "Explain quantum computing",
    200
)?;

// Agent with persistent context
let mut agent = quick::create_agent_runner(Path::new("model.json"))?;
let response = agent.generate_stateful("Hello", 50)?;
```

## Agent Integration API

### MARK System Prompts

Pre-built prompt templates for MARK system agents.

```rust
pub mod prompts::agents {
    pub fn big_bear(cargo_info: &str) -> String
    pub fn cargo_connect(shipment_details: &str) -> String
    pub fn trucker_tales(story_context: &str) -> String
    pub fn legal_logger(legal_question: &str) -> String
    pub fn memory_mark(memory_request: &str) -> String
}
```

### Chat Format Detection

```rust
pub fn detect_chat_format(model_path: &str) -> ChatFormat

pub enum ChatFormat {
    Llama,
    Vicuna,
    Alpaca,
    OpenChat,
}

impl ChatFormat {
    pub fn format_user(&self, input: &str) -> String
    pub fn format_system(&self, content: &str) -> String
}
```

## Error Handling

### LlamaError

```rust
pub enum LlamaError {
    ModelLoadError(String),
    ContextCreationError(String),
    TokenizationError(String),
    GenerationError(String),
    IoError(std::io::Error),
    JsonError(serde_json::Error),
}
```

All API functions return `Result<T, LlamaError>` for proper error handling.

## Low-Level APIs

### Tokenization

```rust
pub fn tokenize(text: &str, vocab: *mut llama_vocab, add_special: bool) -> Vec<llama_token>
pub fn detokenize(vocab: *mut llama_vocab, tokens: &[llama_token]) -> String
pub fn build_batch(tokens: &[llama_token], start_pos: llama_pos) -> TokenBatch
```

### Sampling

```rust
pub fn create_sampler(temperature: f32, top_p: f32, top_k: i32) -> *mut llama_sampler
```

## Usage Patterns

### Pattern 1: Stateless Agent

```rust
use llama_runner::quick;

pub struct SimpleAgent {
    model_path: PathBuf,
}

impl SimpleAgent {
    pub fn query(&self, prompt: &str) -> Result<String> {
        quick::generate_once(&self.model_path, prompt, 200)
    }
}
```

### Pattern 2: Conversational Agent

```rust
use llama_runner::{LlamaRunner, GenerationParams};

pub struct ConversationalAgent {
    runner: LlamaRunner,
}

impl ConversationalAgent {
    pub fn new(model_path: &Path) -> Result<Self> {
        let mut runner = LlamaRunner::new(model_path)?;
        runner.init_stateful(GenerationParams::default())?;
        Ok(Self { runner })
    }
    
    pub fn chat(&mut self, message: &str) -> Result<String> {
        self.runner.generate_stateful(message, 200)
    }
    
    pub fn reset(&mut self) -> Result<()> {
        self.runner.clear_context()
    }
}
```

### Pattern 3: Memory-Managed Agent

```rust
pub struct SmartAgent {
    runner: LlamaRunner,
    memory_threshold: f32,
}

impl SmartAgent {
    pub fn process(&mut self, input: &str) -> Result<String> {
        // Auto-manage memory
        let info = self.runner.get_context_info()?;
        if info.usage_percent > self.memory_threshold {
            self.runner.gc_context(500)?;
        }
        
        self.runner.generate_stateful(input, 200)
    }
}
```

## Thread Safety

**Important:** `LlamaRunner` is **NOT** thread-safe. Use one runner per thread or wrap in appropriate synchronization primitives:

```rust
use std::sync::{Arc, Mutex};

let runner = Arc::new(Mutex::new(
    quick::create_agent_runner(Path::new("model.json"))?
));

// In each thread:
let response = {
    let mut runner = runner.lock().unwrap();
    runner.generate_stateful("Query", 100)?
};
```

## Performance Considerations

### Memory Usage

- Context grows with conversation length
- Monitor with `get_context_info()`
- Use `gc_context()` proactively at 75-80% usage
- Clear context completely when conversations end

### CPU Utilization

- Set `threads` to 50-75% of available cores
- Set `batch_threads` to 25% of available cores
- Adjust based on concurrent agent count

### Model Loading

- Model loading is expensive (1-5 seconds)
- Reuse `LlamaRunner` instances when possible
- Consider model switching vs. multiple instances

## CLI Integration

The package includes a CLI that uses the same API:

```bash
# Stateless generation
llama-runner --model model.json --max 100 --check

# Interactive mode (stateful)
llama-runner --model model.json --threads 8
```

## Examples

### Complete Agent Implementation

```rust
use llama_runner::{LlamaRunner, GenerationParams, Result};
use std::path::Path;

pub struct MarkAgent {
    runner: LlamaRunner,
    agent_name: String,
}

impl MarkAgent {
    pub fn new(model_path: &Path, agent_name: String) -> Result<Self> {
        let mut runner = LlamaRunner::new(model_path)?;
        let params = GenerationParams {
            temperature: 0.1,  // Consistent responses
            max_tokens: 300,
            ..Default::default()
        };
        runner.init_stateful(params)?;
        
        Ok(Self { runner, agent_name })
    }
    
    pub fn process_task(&mut self, task: &str) -> Result<String> {
        let prompt = format!(
            "[INST] You are {}, an agent in the MARK system. Task: {} [/INST]",
            self.agent_name, task
        );
        
        // Check memory usage
        let info = self.runner.get_context_info()?;
        if info.usage_percent > 80.0 {
            self.runner.gc_context(1000)?;
        }
        
        self.runner.generate_stateful(&prompt, 300)
    }
    
    pub fn reset_memory(&mut self) -> Result<()> {
        self.runner.clear_context()
    }
    
    pub fn memory_usage(&self) -> Result<f32> {
        Ok(self.runner.get_context_info()?.usage_percent)
    }
}

// Usage
fn main() -> Result<()> {
    let mut big_bear = MarkAgent::new(
        Path::new("models/qwen/model.json"),
        "Big Bear".to_string()
    )?;
    
    let response = big_bear.process_task(
        "Route this 40ft container from Chicago to Los Angeles"
    )?;
    
    println!("Big Bear: {}", response);
    Ok(())
}
```