#!/bin/bash
set -e

# OpenVINO Controller - Modern Model Download Script (2025+)
# Uses OpenVINO's native HuggingFace integration and OVMS CLI

echo "🚀 OpenVINO Controller - Modern Model Setup (2025+)"
echo "===================================================="
echo ""

# Configuration
PROJECT_ROOT="$(pwd)"
MODELS_DIR="$(pwd)/models"
OPENVINO_LINK="$(pwd)/openvino"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Source environments
source_environments() {
    # Custom env
    if [ -f "$PROJECT_ROOT/.env" ]; then
        log_info "Sourcing custom environment..."
        source "$PROJECT_ROOT/.env"
    fi

    # OpenVINO project env
    if [ -f "$PROJECT_ROOT/setup_env.sh" ]; then
        log_info "Sourcing OpenVINO project environment..."
        source "$PROJECT_ROOT/setup_env.sh"
    fi

    # OpenVINO system env
    if [ -f "$OPENVINO_LINK/setupvars.sh" ]; then
        log_info "Sourcing OpenVINO system environment..."
        source "$OPENVINO_LINK/setupvars.sh"
    fi
}

# Modern OpenVINO 2025+ model sources
declare -A MODERN_MODELS=(
    # Official OpenVINO HuggingFace models (2025+)
    ["qwen2-1.7b"]="OpenVINO/Qwen2-1.5B-Instruct-int4-ov"
    ["qwen2-7b"]="OpenVINO/Qwen2-7B-Instruct-int4-ov"
    ["phi3-mini"]="OpenVINO/Phi-3-mini-4k-instruct-int4-ov"
    ["llama3-8b"]="OpenVINO/Llama-3.2-3B-Instruct-int4-ov"
    ["gemma2-2b"]="OpenVINO/gemma-2-2b-it-int4-ov"
    # Vision models
    ["llava-1.6-7b"]="OpenVINO/llava-v1.6-mistral-7b-hf-int4-ov"
    # Embeddings
    ["bge-base"]="OpenVINO/bge-base-en-v1.5-ov"
)

# Download Huggingface Models
download_openvino_model() {
    local model_name=$1
    local hf_model_id=${MODERN_MODELS[$model_name]}

    if [[ -z "$hf_model_id" ]]; then
        log_error "Unknown model: $model_name"
        return 1
    fi

    local model_dir="$MODELS_DIR/$model_name"
    mkdir -p "$model_dir"

    log_info "📥 Downloading $model_name from HuggingFace..."
    log_info "Model ID: $hf_model_id"

    if ! hf download "$hf_model_id" --revision main --local-dir "$model_dir"; then
        log_error "Failed to download $model_name via HuggingFace CLI"
        return 1
    fi

    # Check that at least one XML and one BIN exist
    local xml_count bin_count
    xml_count=$(find "$model_dir" -maxdepth 1 -name "*.xml" | wc -l)
    bin_count=$(find "$model_dir" -maxdepth 1 -name "*.bin" | wc -l)

    if [[ $xml_count -eq 0 || $bin_count -eq 0 ]]; then
        log_error "Download completed but no IR (.xml/.bin) files found for $model_name"
        return 1
    fi

    log_success "$model_name downloaded successfully with $xml_count XML and $bin_count BIN files"
    return 0
}

# Test model with OpenVINO
test_model() {
    local model_name=$1
    local model_path="$MODELS_DIR/$model_name/openvino_model.xml"

    if [[ ! -f "$model_path" ]]; then
        log_warning "Model file not found: $model_path"
        return 1
    fi

    log_info "Testing $model_name with benchmark_app..."

    if timeout 30s "$OPENVINO_BIN/benchmark_app" -m "$model_path" -niter 1 -nstreams 1 &>/dev/null; then
        log_success "$model_name: ✅ OpenVINO test passed"
        return 0
    else
        log_warning "$model_name: ⚠️  OpenVINO test failed/timeout"
        return 1
    fi
}


# Generate modern config
generate_config() {
    local config_file="$MODELS_DIR/models_config.toml"
    log_info "Generating model configuration..."

    cat > "$config_file" << 'EOF'
# OpenVINO Controller Model Configuration (2025+)
# Generated automatically from available models

EOF

    local model_count=0

    # Iterate over all XML files in model directories
    while IFS= read -r -d '' xml_file; do
        local model_dir=$(dirname "$xml_file")
        local base_name=$(basename "$xml_file" .xml)
        local model_name="$(basename "$model_dir")-$base_name"

        # Skip non-model XMLs (tokenizers, detokenizer)
        case "$base_name" in
            tokenizer*|detokenizer*|config*|preprocessor*|processor*|special_tokens_map)
                continue
                ;;
        esac

        # Check corresponding BIN file exists
        local bin_file="$model_dir/$base_name.bin"
        if [[ ! -f "$bin_file" ]]; then
            log_warning "Skipping $xml_file: no matching .bin file"
            continue
        fi

        # Determine tokenizer
        local tokenizer_path=""
        if [[ -f "$model_dir/tokenizer.json" ]]; then
            tokenizer_path="$model_dir/tokenizer.json"
        elif [[ -f "$model_dir/tokenizer_config.json" ]]; then
            tokenizer_path="$model_dir/tokenizer_config.json"
        fi

        # Determine model type
        local model_type="text-generation"
        if [[ "$base_name" == *embed* || "$base_name" == *bge* ]]; then
            model_type="embeddings"
        elif [[ "$base_name" == *llava* || "$base_name" == *vision* ]]; then
            model_type="vision-language"
        fi

        cat >> "$config_file" << EOF
[[models]]
name = "$model_name"
path = "$xml_file"
tokenizer_path = "$tokenizer_path"
device = "AUTO"
model_type = "$model_type"
max_tokens = 2048
context_length = 4096
temperature = 0.7
top_p = 0.9
batch_size = 1
auto_load = false

EOF
        ((model_count++))
        log_info "Added config for: $model_name"

    done < <(find "$MODELS_DIR" -name "*.xml" -print0 2>/dev/null)

    if [[ "$model_count" -eq 0 ]]; then
        echo "# No OpenVINO models found" >> "$config_file"
        log_warning "No models found for configuration"
    else
        log_success "Generated config for $model_count models"
    fi

    log_success "Config saved to: $config_file"
}

# Main execution
main() {
    log_info "Initializing OpenVINO 2025+ model setup..."

    # Source all environments
    source_environments

    # Verify OpenVINO installation
    if [[ ! -f "$OPENVINO_BIN/benchmark_app" ]]; then
        log_error "OpenVINO benchmark_app not found at: $OPENVINO_BIN/benchmark_app"
        exit 1
    fi

    # Create models directory
    mkdir -p "$MODELS_DIR"

    # Interactive model selection
    echo ""
    echo "Available OpenVINO 2025+ Models:"
    echo "================================"
    local i=1
    local model_list=()
    for model_name in "${!MODERN_MODELS[@]}"; do
        echo "$i) $model_name (${MODERN_MODELS[$model_name]})"
        model_list+=("$model_name")
        ((i++))
    done
    echo "$i) Download all models"
    echo "$((i+1))) Skip downloads (test existing)"
    echo ""

    read -p "Select models to download (1-$((i+1)) or comma-separated): " selection

    case "$selection" in
        *,*)
            # Multiple selections
            IFS=',' read -ra SELECTED <<< "$selection"
            for sel in "${SELECTED[@]}"; do
                sel=$(echo "$sel" | xargs) # trim whitespace
                if [[ "$sel" -ge 1 && "$sel" -le "${#model_list[@]}" ]]; then
                    model_name="${model_list[$((sel-1))]}"
                    download_openvino_model "$model_name"
                fi
            done
            ;;
        "$i")
            # Download all
            for model_name in "${!MODERN_MODELS[@]}"; do
                download_openvino_model "$model_name"
            done
            ;;
        "$((i+1))")
            # Skip downloads
            log_info "Skipping downloads, testing existing models..."
            ;;
        *)
            # Single selection
            if [[ "$selection" -ge 1 && "$selection" -le "${#model_list[@]}" ]]; then
                model_name="${model_list[$((selection-1))]}"
                download_openvino_model "$model_name"
            else
                log_error "Invalid selection"
                exit 1
            fi
            ;;
    esac

    # Test all available models
    echo ""
    log_info "Testing available models..."
    for model_name in "${!MODERN_MODELS[@]}"; do
        if [[ -f "$MODELS_DIR/$model_name/openvino_model.xml" ]]; then
            test_model "$model_name"
        fi
    done

    # Generate configuration
    generate_config

    # Final summary
    echo ""
    echo "🎯 Modern OpenVINO Model Setup Complete!"
    echo "========================================"
    log_success "Models directory: $MODELS_DIR"
    log_success "Configuration: $MODELS_DIR/models_config.toml"
    echo ""
    log_info "Copy the [[models]] sections from models_config.toml to your main config"
    echo ""
    log_info "Ready to run: ./target/release/openvino-controller"
}

# Execute main function
main "$@"
