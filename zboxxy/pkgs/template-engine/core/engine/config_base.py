# config_base.py
#!/usr/bin/env python3
import os

# Base template path
TEMPLATES_DIR = os.path.expanduser("~/WORKSPACE/.../templates")

# Core directory
CORE_DIR = os.path.join(TEMPLATES_DIR, "core")
LOGIC_DIR = os.path.join(CORE_DIR, "logic")

# Source directory
SOURCE_DIR = os.path.join(TEMPLATES_DIR, "src")
CONFIGS_DIR = os.path.join(SOURCE_DIR, "configs")
TEMPLATES_DIR = os.path.join(SOURCE_DIR, "templates")



# Utility function to get template path
def templates_path(service_name):
    return os.path.join(TEMPLATES_DIR, f"{service_name}.template.yaml")

# Utility function to get config path
def values_path(service_name):
    return os.path.join(CONFIGS_DIR, f"{service_name}.values.yaml")
