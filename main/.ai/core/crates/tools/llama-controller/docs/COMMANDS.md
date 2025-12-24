cargo run --release -- \
  --model=models/llama-model.gguf \
  --threads=12 \
  --batch=4 \
  --max=128


cargo run --release -- --model=models/llama-model.gguf --check


graph TD
UserPrompt --> RustAPI
RustAPI --> Redis[Session: ID123]
RustAPI --> LlamaRunner[model.gguf]
LlamaRunner --> Output

subgraph MemoryEngine
    Redis -->|Temp| Context
    Context --> RustAPI
end

Output --> RustAPI
RustAPI --> DuckDB[Persist Full Log]


Usage: llama-runner [OPTIONS]

Options:
  --model <PATH>       Path to your .gguf/.bin model file (required)
  --threads <N>        Number of CPU threads (default: 8)
  --batch <N>          Threads per batch (default: 4)
  --max <TOKENS>       Max tokens to generate (default: 128)
  --check              Only load the model & report its metadata
  -h, --help           Show this help message
  -V, --version        Show version info
