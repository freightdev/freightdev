#!/usr/bin/env bash

HEADER="${1:-wrapper.h}"

echo "🔍 Checking FFI safety in $HEADER..."

# 1. Check for extern "C" block
if ! grep -q 'extern "C"' "$HEADER"; then
  echo "❌ Missing extern \"C\" block"
else
  echo "✅ Found extern \"C\" block"
fi

# 2. Check for #pragma once or header guards
if grep -q "#pragma once" "$HEADER"; then
  echo "✅ Found #pragma once"
elif grep -q "#ifndef .*_H" "$HEADER"; then
  echo "✅ Found header guards"
else
  echo "❌ Missing header protection (no #pragma once or guards)"
fi

# 3. Warn if including C++ headers
if grep -E -q '#include\s*<.*\.hpp>' "$HEADER"; then
  echo "⚠️  C++ header (.hpp) detected — bindgen might break"
fi

# 4. Check for conditional macros (optional, warn only)
if grep -q "#ifdef" "$HEADER"; then
  echo "ℹ️  Found conditional compilation (#ifdef) — be sure they’re resolved"
fi

# 5. Check that included headers exist
MISSING=false
grep '#include "' "$HEADER" | sed -E 's/#include "(.*)"/\1/' | while read -r file; do
  if [[ ! -f "$file" && ! -f "llama.cpp/$file" && ! -f "./include/$file" ]]; then
    echo "❌ Missing include file: $file"
    MISSING=true
  fi
done

if [[ "$MISSING" = false ]]; then
  echo "✅ All includes appear to exist"
fi

echo "🧼 FFI header check complete."
