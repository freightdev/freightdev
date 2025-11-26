#!/usr/bin/env python3

import sys
import os

print("Hello from Python script in devtools!")
print(f"Script name: {os.environ.get('RUNA_SCRIPT_NAME', 'Not set')}")
print(f"Script directory: {os.environ.get('RUNA_SCRIPT_DIR', 'Not set')}")
print(f"Arguments received: {sys.argv[1:]}")
print("This demonstrates multi-language script support!")