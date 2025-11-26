#!/usr/bin/env zsh

#! ╔════════════════════════════════════════════════════════════╗
#? llama-controller.zsh - Pure ZSH Controller for llama_runner
#! ╚════════════════════════════════════════════════════════════╝

# Configuration
LLAMA_RUNNER_PATH="${LLAMA_RUNNER_PATH:-./target/release/llama-runner}"
MODELS_DIR="${MODELS_DIR:-./src/models}"
LOG_DIR="${LOG_DIR:-./logs}"
TEMP_DIR="${TEMP_DIR:-/tmp/llama_controller}"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$TEMP_DIR"

# Logging functions
log_info() {
    echo "[INFO $(date '+%H:%M:%S')] $1" | tee -a "$LOG_DIR/controller.log"
}

log_error() {
    echo "[ERROR $(date '+%H:%M:%S')] $1" | tee -a "$LOG_DIR/controller.log" >&2
}

log_debug() {
    [[ -n "$DEBUG" ]] && echo "[DEBUG $(date '+%H:%M:%S')] $1" | tee -a "$LOG_DIR/controller.log"
}

# Model discovery and validation
discover_models() {
    local models=()
    
    for model_dir in "$MODELS_DIR"/*; do
        [[ -d "$model_dir" ]] || continue
        
        local model_json="$model_dir/model.json"
        if [[ -f "$model_json" ]]; then
            local name=$(basename "$model_dir")
            models+=("$name:$model_json")
            log_debug "Found model: $name -> $model_json"
        fi
    done
    
    echo "${models[@]}"
}

# Model validation
validate_model() {
    local model_json="$1"
    
    if [[ ! -f "$model_json" ]]; then
        log_error "Model JSON not found: $model_json"
        return 1
    fi
    
    # Basic JSON validation (check for required fields)
    if ! grep -q '"name"' "$model_json" || ! grep -q '"path"' "$model_json"; then
        log_error "Invalid model JSON: missing required fields"
        return 1
    fi
    
    # Check if binary exists
    local model_path=$(grep '"path"' "$model_json" | sed 's/.*"path".*"\([^"]*\)".*/\1/')
    if [[ ! -f "$model_path" ]]; then
        log_error "Model binary not found: $model_path"
        return 1
    fi
    
    return 0
}

# Core generation functions
generate_stateless() {
    local model="$1"
    local prompt="$2"
    local max_tokens="${3:-256}"
    local temperature="${4:-0.1}"
    local threads="${5:-8}"
    
    local temp_file="$TEMP_DIR/stateless_$$"
    local error_file="$TEMP_DIR/error_$$"
    
    log_info "Stateless generation: model=$model, tokens=$max_tokens, temp=$temperature"
    
    # Create temporary prompt file to handle special characters
    echo "$prompt" > "$temp_file.prompt"
    
    # Run llama_runner with timeout
    timeout 300 "$LLAMA_RUNNER_PATH" \
        --model "$model" \
        --max "$max_tokens" \
        --threads "$threads" \
        2> "$error_file" < "$temp_file.prompt" > "$temp_file.output"
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        cat "$temp_file.output"
        rm -f "$temp_file".*
        return 0
    else
        log_error "Generation failed with code $exit_code"
        [[ -f "$error_file" ]] && log_error "Error: $(cat "$error_file")"
        rm -f "$temp_file".*
        return $exit_code
    fi
}

# Interactive session management
start_interactive() {
    local model="$1"
    local threads="${2:-8}"
    local max_tokens="${3:-256}"
    
    log_info "Starting interactive session: model=$model"
    
    "$LLAMA_RUNNER_PATH" \
        --model "$model" \
        --threads "$threads" \
        --max "$max_tokens"
}

# Model testing
test_model() {
    local model="$1"
    
    log_info "Testing model: $model"
    
    "$LLAMA_RUNNER_PATH" --model "$model" --check
    return $?
}

# Batch processing
batch_generate() {
    local model="$1"
    local input_file="$2"
    local output_file="$3"
    local max_tokens="${4:-100}"
    
    if [[ ! -f "$input_file" ]]; then
        log_error "Input file not found: $input_file"
        return 1
    fi
    
    log_info "Batch processing: $input_file -> $output_file"
    
    local line_count=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        ((line_count++))
        log_debug "Processing line $line_count: ${line:0:50}..."
        
        local response=$(generate_stateless "$model" "$line" "$max_tokens")
        
        if [[ $? -eq 0 ]]; then
            echo "PROMPT: $line" >> "$output_file"
            echo "RESPONSE: $response" >> "$output_file"
            echo "---" >> "$output_file"
        else
            log_error "Failed to process line $line_count"
            echo "PROMPT: $line" >> "$output_file"
            echo "RESPONSE: ERROR" >> "$output_file"
            echo "---" >> "$output_file"
        fi
    done < "$input_file"
    
    log_info "Processed $line_count prompts"
}

# Agent interface functions
agent_query() {
    local agent_name="$1"
    local model="$2"
    local query="$3"
    local max_tokens="${4:-200}"
    
    # Create agent-specific prompt template
    local prompt="[INST] You are $agent_name, an agent in the MARK system. Task: $query [/INST]"
    
    log_info "Agent query: $agent_name -> $query"
    
    generate_stateless "$model" "$prompt" "$max_tokens"
}

# System status and health checks
controller_status() {
    echo "=== llama_controller Status ==="
    echo "Controller PID: $$"
    echo "Timestamp: $(date)"
    echo "Runner Path: $LLAMA_RUNNER_PATH"
    echo "Models Directory: $MODELS_DIR"
    echo "Log Directory: $LOG_DIR"
    echo
    
    echo "=== Available Models ==="
    local models=($(discover_models))
    
    if [[ ${#models[@]} -eq 0 ]]; then
        echo "No models found"
    else
        for model_info in "${models[@]}"; do
            local name="${model_info%:*}"
            local path="${model_info#*:}"
            
            printf "%-20s %s" "$name" "$path"
            
            if validate_model "$path" 2>/dev/null; then
                echo " [VALID]"
            else
                echo " [INVALID]"
            fi
        done
    fi
    
    echo
    echo "=== System Resources ==="
    echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Disk Space: $(df -h . | tail -1 | awk '{print $4 " available"}')"
}

# Configuration management
show_config() {
    echo "=== Current Configuration ==="
    echo "LLAMA_RUNNER_PATH=$LLAMA_RUNNER_PATH"
    echo "MODELS_DIR=$MODELS_DIR"
    echo "LOG_DIR=$LOG_DIR"
    echo "TEMP_DIR=$TEMP_DIR"
    echo "DEBUG=$DEBUG"
}

set_config() {
    local key="$1"
    local value="$2"
    
    case "$key" in
        runner_path)
            export LLAMA_RUNNER_PATH="$value"
            log_info "Set runner path: $value"
            ;;
        models_dir)
            export MODELS_DIR="$value"
            log_info "Set models directory: $value"
            ;;
        log_dir)
            export LOG_DIR="$value"
            mkdir -p "$LOG_DIR"
            log_info "Set log directory: $value"
            ;;
        debug)
            export DEBUG="$value"
            log_info "Set debug mode: $value"
            ;;
        *)
            log_error "Unknown config key: $key"
            return 1
            ;;
    esac
}

# Main command dispatcher
main() {
    local command="$1"
    shift
    
    case "$command" in
        generate)
            local model="$1"
            local prompt="$2"
            local max_tokens="$3"
            generate_stateless "$model" "$prompt" "$max_tokens"
            ;;
        interactive)
            local model="$1"
            local threads="$2"
            local max_tokens="$3"
            start_interactive "$model" "$threads" "$max_tokens"
            ;;
        test)
            local model="$1"
            test_model "$model"
            ;;
        batch)
            local model="$1"
            local input="$2"
            local output="$3"
            local max_tokens="$4"
            batch_generate "$model" "$input" "$output" "$max_tokens"
            ;;
        agent)
            local agent_name="$1"
            local model="$2"
            local query="$3"
            local max_tokens="$4"
            agent_query "$agent_name" "$model" "$query" "$max_tokens"
            ;;
        status)
            controller_status
            ;;
        config)
            if [[ $# -eq 0 ]]; then
                show_config
            else
                set_config "$1" "$2"
            fi
            ;;
        models)
            echo "Available models:"
            local models=($(discover_models))
            for model_info in "${models[@]}"; do
                echo "  ${model_info%:*}"
            done
            ;;
        validate)
            local model="$1"
            if validate_model "$model"; then
                echo "Model valid: $model"
            else
                echo "Model invalid: $model"
                return 1
            fi
            ;;
        help|*)
            cat << 'EOF'
llama-controller.zsh - Pure ZSH Controller for llama_runner

USAGE:
  llama-controller.zsh <command> [options]

COMMANDS:
  generate <model> <prompt> [max_tokens]     Generate response (stateless)
  interactive <model> [threads] [max_tokens] Start interactive session
  test <model>                              Test model loading
  batch <model> <input_file> <output_file>  Batch process prompts
  agent <name> <model> <query> [max_tokens] Agent-specific query
  status                                    Show system status
  config [key] [value]                      Show/set configuration
  models                                    List available models
  validate <model_json>                     Validate model configuration
  help                                      Show this help

EXAMPLES:
  llama-controller.zsh generate qwen1.5-1.8b-chat "Hello world" 50
  llama-controller.zsh interactive qwen1.5-1.8b-chat 8 200
  llama-controller.zsh agent big_bear qwen1.5-1.8b-chat "Route cargo from Chicago to LA"
  llama-controller.zsh batch qwen1.5-1.8b-chat prompts.txt responses.txt 100
  llama-controller.zsh test qwen1.5-1.8b-chat
  llama-controller.zsh status

ENVIRONMENT VARIABLES:
  LLAMA_RUNNER_PATH   Path to llama-runner binary
  MODELS_DIR          Directory containing model.json files
  LOG_DIR             Directory for log files
  DEBUG               Enable debug logging
EOF
            ;;
    esac
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi