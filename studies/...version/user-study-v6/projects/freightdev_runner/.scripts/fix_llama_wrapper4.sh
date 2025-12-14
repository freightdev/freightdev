#!/bin/bash
# fix_llama_wrapper.sh
# Automatically fixes malloc/realloc casts in llama_wrapper.c

FILE="../libs/include/llama_wrapper.c"
BACKUP="${FILE}.bak"

# Make a backup first
cp "$FILE" "$BACKUP"
echo "Backup saved to $BACKUP"

# Fix malloc casts
sed -i -E 's/\([[:space:]]*sizeof\(([a-zA-Z0-9_]+)\*\)[[:space:]]*malloc\([^\)]+\)\)/(\1*) malloc(sizeof(\1))/g' "$FILE"

# Fix string allocations like strlen(model_path)
sed -i -E 's/\([[:space:]]*strlen\(([a-zA-Z0-9_]+)\)\*[[:space:]]*malloc\([^\)]+\)\)/char* \1 = (char*) malloc(strlen(\1)+1)/g' "$FILE"

# Fix realloc casts
sed -i -E 's/\(([a-zA-Z0-9_]+)\*\)[[:space:]]*realloc\(([a-zA-Z0-9_]+),[[:space:]]*[^)]+\)/(\1*) realloc(\2, sizeof(\1) * N)/g' "$FILE"

echo "malloc/realloc casts fixed in $FILE"
