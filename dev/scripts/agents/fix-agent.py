#!/usr/bin/env python3
# fix-agent.py — AI fixer for broken components

import sys
import os
import openai
import argparse
from pathlib import Path

# Load your OpenAI API key (set this however you prefer)
openai.api_key = os.getenv("OPENAI_API_KEY")

def read_file(path: Path) -> str:
    try:
        return path.read_text()
    except Exception as e:
        print(f"❌ Failed to read {path}: {e}")
        return ""

def send_fix_request(name: str, reason: str, content: str):
    print(f"🧠 Asking OpenAI to fix: {name} — Reason: {reason}")
    prompt = f"""You are an expert UI developer. The component named `{name}` has a problem:

Reason: {reason}

Here is the current broken code:

```tsx
{content}
```

Please fix the code so that it works as expected.

Return only the fixed code, no other text or comments.
"""

    response = openai.ChatCompletion.create(
        model="gpt-4o-mini",
        messages=[