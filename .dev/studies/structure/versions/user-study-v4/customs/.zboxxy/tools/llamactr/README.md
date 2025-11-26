This gives you complete command-line control over the Rust binary:

**Core Functions:**
- `generate` - Single stateless generation calls
- `interactive` - Launch the full interactive session  
- `batch` - Process multiple prompts from file
- `agent` - Agent-specific queries with MARK system formatting

**Management Features:**
- Auto-discovery of models in your `src/models/` directory
- Model validation before use
- System status and resource monitoring
- Configuration management via environment variables

**Agent Integration:**
```zsh
# Your agents can call it like this:
llama-controller.zsh agent big_bear qwen1.5-1.8b-chat "Route this cargo from Chicago to LA"
llama-controller.zsh agent cargo_connect qwen1.5-1.8b-chat "Process shipment #12345"
```

**Batch Operations:**
```zsh
# Process multiple queries
llama-controller.zsh batch qwen1.5-1.8b-chat input_prompts.txt results.txt 150
```

The controller handles timeouts, error logging, temp file cleanup, and provides a clean interface between your ZSH environment routing and the Rust llama_runner binary. Your agents just need to call this controller instead of dealing with the Rust binary directly.