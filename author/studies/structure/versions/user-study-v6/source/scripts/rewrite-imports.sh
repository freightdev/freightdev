#!/usr/bin/env bash

ROOT="packages/ui/src/components"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🔍 Scanning for *.tsx files in $ROOT...${NC}"

find "$ROOT" -type f -name "*.tsx" -print0 | while IFS= read -r -d '' file; do
  if grep -q "import { cn } from 'ui/src/libs'" "$file"; then
    sed -i "s|import { cn } from 'ui/src/libs'|import { cn } from '@ui/utils'|g" "$file"
    echo -e "📝 Updated: ${file}"
  fi
done

echo -e "${GREEN}✅ All @ui/libs → @ui/utils rewritten under $ROOT${NC}"
