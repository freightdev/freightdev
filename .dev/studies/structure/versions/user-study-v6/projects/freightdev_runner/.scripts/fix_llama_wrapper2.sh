#!/bin/bash
# Script to patch llama_wrapper.c for C++ compilation with modern llama.cpp

WRAPPER="../libs/include/llama_wrapper.c"

# 1️⃣ Add explicit malloc casts
sed -i -E 's/([a-zA-Z0-9_]+\*) malloc/\1* malloc(\1)/g' $WRAPPER
sed -i -E 's/malloc\(([^)]+)\)/(void*)malloc(\1)/g' $WRAPPER
sed -i -E 's/realloc\(([^,]+), ([^)]+)\)/(void*)realloc(\1, \2)/g' $WRAPPER

# 2️⃣ Replace seed assignment (remove or comment it)
sed -i '/ctx_params\.seed = params->seed;/s/^/\/\//' $WRAPPER

# 3️⃣ Comment out lines using non-existent vocab in wrapper context
sed -i '/ctx->vocab/s/^/\/\//' $WRAPPER
sed -i '/wrapper->vocab/s/^/\/\//' $WRAPPER

# 4️⃣ Comment out perf_data.t_prompt_ms usage
sed -i '/perf_data\.t_prompt_ms/s/^/\/\//' $WRAPPER

# 5️⃣ Remove any other invalid field accesses
sed -i '/ctx->is_valid/ s/ctx->is_valid && //' $WRAPPER

# Optional: force C linkage for C++ compiler
sed -i '1i extern "C" {' $WRAPPER
echo '}' >> $WRAPPER

echo "Patch applied to $WRAPPER. You may still need to manually adjust API calls if fields are removed in latest llama.cpp."
