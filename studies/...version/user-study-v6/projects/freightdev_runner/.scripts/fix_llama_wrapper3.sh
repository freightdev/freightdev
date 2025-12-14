#!/bin/bash

# Fix llama_wrapper.c to compile under C++ with proper casts

C_FILE="../libs/include/llama_wrapper.c"
BACKUP_FILE="${C_FILE}.bak"

# Backup original file
cp "$C_FILE" "$BACKUP_FILE"

# Replace all (void*)malloc(...) with proper typed casts
sed -i -E '
s/\(void\*\)malloc\(([^)]+)\)/(\1*)malloc(\1)/g
s/\(void\*\)realloc\(([^,]+), ([^)]+)\)/(\1*)realloc(\1, \2)/g
' "$C_FILE"

# Ensure all header includes are compatible with C++
sed -i -E '
s/#include <string.h>/#include <cstring>/g
s/#include <stdlib.h>/#include <cstdlib>/g
' "$C_FILE"

echo "llama_wrapper.c fixed for C++ compilation. Original backed up as $BACKUP_FILE"
