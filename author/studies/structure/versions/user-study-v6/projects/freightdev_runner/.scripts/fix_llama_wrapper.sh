#!/bin/bash

# Path to the C file
C_FILE="../libs/include/llama_wrapper.c"
BACKUP_FILE="${C_FILE}.bak"

# Backup original
cp "$C_FILE" "$BACKUP_FILE"

# Fix malloc casts
sed -i '
s/wrapper->model_path = (malloc(/wrapper->model_path = (char*)malloc(/g
s/llama_token* tokens = (malloc(/llama_token* tokens = (llama_token*)malloc(/g
s/char* text_buffer = malloc(/char* text_buffer = (char*)malloc(/g
s/char* final_text = realloc(/char* final_text = (char*)realloc(/g
s/char* output_buffer = (.*)malloc(/char* output_buffer = (char*)malloc(/g
s/realloc(\(.*\))/realloc(\1)/g
' "$C_FILE"

# Remove or comment out lines with undefined struct members (like vocab)
sed -i '
/wrapper->vocab/d
/ctx->vocab/d
' "$C_FILE"

# Replace final_output typos with final_text
sed -i 's/final_output/final_text/g' "$C_FILE"

# Remove double closing braces at file end
sed -i '$ s/}}$/}/' "$C_FILE"

# Optional: format
clang-format -i "$C_FILE"

