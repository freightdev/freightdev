# load_services.py
#!/usr/bin/env python3
import os
import re
import yaml
from config_base import TEMPLATES_DIR, CONFIGS_DIR

def load_services():
    services = []

    # Preload all values files
    all_values = {}
    for file in os.listdir(CONFIGS_DIR):
        if file.endswith(".values.yaml"):
            name = file.replace(".values.yaml", "")
            path = os.path.join(CONFIGS_DIR, file)
            with open(path, "r") as f:
                all_values[name] = yaml.safe_load(f) or {}

    for file in os.listdir(TEMPLATES_DIR):
        if file.endswith(".template.yaml"):
            name = file.replace(".template.yaml", "")
            t_path = os.path.join(TEMPLATES_DIR, file)

            # Get all keys in template
            with open(t_path, "r") as f:
                template = f.read()
            required_keys = set(re.findall(r"\{\{(\w+)\}\}", template))

            # Merge all values files to check keys
            merged_values = {}
            for v in all_values.values():
                merged_values.update(v)

            # Check if all template keys exist in merged values
            has_all_values = all(k in merged_values for k in required_keys)

            services.append({
                "name": name,
                "has_values": has_all_values
            })

    return services

if __name__ == "__main__":
    for svc in load_services():
        print(f"{svc['name']} (values: {'yes' if svc['has_values'] else 'no'})")
