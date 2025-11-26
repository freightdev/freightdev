#!/usr/bin/env bash
# fix_llama_wrapper.sh
# Automatically fixes common syntax and allocation issues in llama_wrapper.c

FILE="../libs/include/llama_wrapper.c"
BACKUP="${FILE}.bak"

# Step 0: Backup
if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

cp "$FILE" "$BACKUP"
echo "Backup created at $BACKUP"

# Step 1: Fix malloc casts and sizes
sed -i -E '
s/strlen\(model_path\*\)malloc\(strlen\(model_path\) \+ 1\)/malloc(strlen(model_path) + 1)/g
s/max_tokens \* sizeof\(llama_token\*\)malloc\(max_tokens \* sizeof\(llama_token\)\)/malloc(max_tokens * sizeof(llama_token))/g
s/\(max_text_len\*\)malloc\(max_text_len\)/malloc(max_text_len)/g
s/\(text_buffer\*\) realloc\(text_buffer, sizeof\(text_buffer\) \* N\)/realloc(text_buffer, max_text_len)/g
s/\(tokens\*\) realloc\(tokens, sizeof\(tokens\) \* N\)/realloc(tokens, max_tokens)/g
' "$FILE"

# Step 2: Remove invalid commented casts in model_path assignment
sed -i -E 's/char\* model_path =.*;/char* model_path = NULL;/g' "$FILE"

# Step 3: Fix out-of-place casts in other mallocs
sed -i -E '
s/char\* final_output = \(output_buffer\*\) realloc/output_buffer = realloc/g
s/char\* info = \(info_len\*\)malloc/info = malloc/g
' "$FILE"

# Step 4: Uncomment critical LLaMA API calls (tokenize, detokenize, vocab)
sed -i -E 's@//\s*(int32_t n_tokens = llama_tokenize.*)@\1@g' "$FILE"
sed -i -E 's@//\s*(int32_t text_len = llama_detokenize.*)@\1@g' "$FILE"
sed -i -E 's@//\s*(int32_t vocab_size = llama_vocab_n_tokens.*)@\1@g' "$FILE"
sed -i -E 's@//\s*(if \(llama_vocab_is_eog.*)@\1@g' "$FILE"
sed -i -E 's@//\s*(int32_t token_len = llama_token_to_piece.*)@\1@g' "$FILE"
sed -i -E 's@//\s*(wrapper->vocab = llama_model_get_vocab.*)@\1@g' "$FILE"

# Step 5: Fix NULL pointer returns
sed -i -E 's@//\s*if \(!ctx \|\| !text \|\| !out_tokens \|\| !ctx->is_valid \|\| !ctx->vocab\).*@\tif (!ctx || !text || !out_tokens) { return LLAMA_WRAPPER_ERROR_NULL_POINTER; }@g' "$FILE"
sed -i -E 's@//\s*if \(!ctx \|\| !tokens \|\| !out_text \|\| !ctx->is_valid \|\| !ctx->vocab\).*@\tif (!ctx || !tokens || !out_text) { return LLAMA_WRAPPER_ERROR_NULL_POINTER; }@g' "$FILE"
sed -i -E 's@//\s*if \(!ctx \|\| !out_vocab_size \|\| !ctx->is_valid \|\| !ctx->vocab\).*@\tif (!ctx || !out_vocab_size) { return LLAMA_WRAPPER_ERROR_NULL_POINTER; }@g' "$FILE"

echo "Patch complete. You can now try compiling llama_wrapper.c."
