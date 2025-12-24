#!/bin/bash
set -euo pipefail

MODELS_DIR="./models"
TOKEN_FILE="./.env"
mkdir -p "$MODELS_DIR"
mkdir -p "$MODELS_DIR/embeddings"

source "$TOKEN_FILE"
[[ -z "${HF_TOKEN:-}" ]] && { echo "HF_TOKEN not found in $TOKEN_FILE"; exit 1; }

echo "🤖 Available AI models for Jesse's Assistant:"

# Declare arrays for URLs, output filenames, and directories
urls=(
"https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"
"https://huggingface.co/bartowski/CodeLlama-13B-MORepair-GGUF/resolve/main/CodeLlama-13B-MORepair-Q5_K_S.gguf"
"https://huggingface.co/TheBloke/CodeLlama-7B-GGUF/resolve/main/codellama-7b.Q4_K_M.gguf"
"https://huggingface.co/TheBloke/Nous-Hermes-Llama-2-7B-GGUF/resolve/main/nous-hermes-2-llama2-7b.Q4_K_M.gguf"
"https://huggingface.co/TheBloke/OpenChat-3.5-1210-GGUF/resolve/main/openchat-3.5-1210.Q4_K_M.gguf"
"https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
"https://huggingface.co/TheBloke/zephyr-7B-beta-GGUF/resolve/main/zephyr-7b-beta.Q4_K_M.gguf"
"https://huggingface.co/DevQuasar/osmosis-ai.Osmosis-Apply-1.7B-GGUF/resolve/main/osmosis-apply-1.7b.Q4_K_M.gguf"
"https://huggingface.co/tensorblock/Qwen1.5-1.8B-Chat-GGUF/resolve/main/qwen1.5-1.8b-chat.Q4_K_M.gguf"
"https://huggingface.co/tensorblock/Yi-1.5-9B-Chat-GGUF/resolve/main/yi-1.5-9b-chat.Q4_K_M.gguf"
"https://huggingface.co/TheBloke/MythoMax-L2-13B-GGUF/resolve/main/mythomax-l2-13b.Q4_K_M.gguf"
"https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
"https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/model.safetensors?download=true"
)

outs=(
"Llama-3.1-8B-Instruct-Q5_K_M.gguf"
"CodeLlama-13B-Instruct-Q5_K_M.gguf"
"codellama-7b.Q4_K_M.gguf"
"nous-hermes-2-llama2-7b.Q4_K_M.gguf"
"openchat-3.5-1210.Q4_K_M.gguf"
"phi-2.Q4_K_M.gguf"
"zephyr-7b-beta.Q4_K_M.gguf"
"osmosis-apply-1.7b.Q4_K_M.gguf"
"qwen1.5-1.8b-chat.Q4_K_M.gguf"
"yi-1.5-9b-chat.Q4_K_M.gguf"
"mythomax-l2-13b.Q4_K_M.gguf"
"tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
"model.gguf"
)

dirs=(
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR"
"$MODELS_DIR/embeddings"
)

# Display list with numbers
for i in "${!urls[@]}"; do
  echo "[$((i+1))] ${outs[i]}"
done

echo
read -rp "Enter model numbers to download (e.g. 1,3,5-7) or 'all': " selection

# Function to parse selection into array of indices (0-based)
parse_selection() {
  local input=$1
  local result=()
  if [[ "$input" == "all" ]]; then
    for ((i=0; i<${#urls[@]}; i++)); do
      result+=("$i")
    done
  else
    IFS=',' read -ra parts <<< "$input"
    for part in "${parts[@]}"; do
      if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        start=${BASH_REMATCH[1]}
        end=${BASH_REMATCH[2]}
        for ((n=start; n<=end; n++)); do
          result+=($((n-1)))
        done
      elif [[ "$part" =~ ^[0-9]+$ ]]; then
        result+=($((part-1)))
      fi
    done
  fi
  echo "${result[@]}"
}

selected_indices=($(parse_selection "$selection"))

if [ ${#selected_indices[@]} -eq 0 ]; then
  echo "No valid models selected, exiting."
  exit 1
fi

# Prepare aria2 input file
DOWNLOAD_LIST=$(mktemp)
for idx in "${selected_indices[@]}"; do
  echo "${urls[idx]}" >> "$DOWNLOAD_LIST"
  echo "    dir=${dirs[idx]}" >> "$DOWNLOAD_LIST"
  echo "    out=${outs[idx]}" >> "$DOWNLOAD_LIST"
  echo "    header=Authorization: Bearer $HF_TOKEN" >> "$DOWNLOAD_LIST"
  echo >> "$DOWNLOAD_LIST"
done

# Check aria2c installed, install if missing
if ! command -v aria2c &> /dev/null; then
    echo "📦 Installing aria2..."
    if command -v apt &>/dev/null; then
        sudo apt install -y aria2
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm aria2
    elif command -v apk &>/dev/null; then
        sudo apk add aria2
    else
        echo "❌ Please install aria2 manually."
        exit 1
    fi
fi

# Run aria2c to download selected models
aria2c -x 8 -s 8 -j 3 -c \
    --auto-file-renaming=false \
    --max-concurrent-downloads=3 \
    --input-file="$DOWNLOAD_LIST" \
    --continue=true \
    --summary-interval=10

rm "$DOWNLOAD_LIST"

echo "✅ Selected models downloaded!"
echo "📁 Models saved to: $MODELS_DIR"
