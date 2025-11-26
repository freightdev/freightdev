#!/usr/bin/env bash
set -e

# === Helpers ===
log_info() { echo -e "🔹 $1"; }
log_error() { echo -e "❌ $1" >&2; exit 1; }

# === ARGS ===
MODEL_ID="$1"
BASE_DIR="${HOME}/devbelt/models"
MODELS_JSON="$BASE_DIR/models.json"

[[ -z "$MODEL_ID" ]] && log_error "Usage: download_model.sh <model-id>"
[[ ! -f "$MODELS_JSON" ]] && log_error "Missing $MODELS_JSON"

# === LOOKUP METADATA ===
MODEL_META=$(jq -c ".[] | select(.id == \"$MODEL_ID\")" "$MODELS_JSON")
[[ -z "$MODEL_META" ]] && log_error "Model '$MODEL_ID' not found in $MODELS_JSON"

# === PARSE METADATA ===
NAME=$(echo "$MODEL_META" | jq -r .id)
VARIANT=$(echo "$MODEL_META" | jq -r .variant)
URL=$(echo "$MODEL_META" | jq -r .source)
DEST="$BASE_DIR/$NAME/$VARIANT"

# === ENSURE DIR ===
mkdir -p "$DEST"

# === DOWNLOAD ===
log_info "Downloading $NAME ($VARIANT)..."
wget -q --show-progress -O "$DEST/model.gguf" "$URL" || log_error "Download failed!"

log_info "✔ Model saved to: $DEST/model.gguf"
