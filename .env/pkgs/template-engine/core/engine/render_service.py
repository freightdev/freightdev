# render_service.py
#!/usr/bin/env python3
import re
import yaml
import os
import sys
from config_base import templates_path, values_path

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "out")
os.makedirs(OUT_DIR, exist_ok=True)

def load_values(services):
    merged = {}
    for svc in services:
        path = values_path(svc)
        if not os.path.isfile(path):
            print(f"Error: Values file '{path}' not found.", file=sys.stderr)
            sys.exit(1)
        with open(path, "r") as f:
            data = yaml.safe_load(f) or {}
            merged.update(data)
    return merged

def render_service(template_service, value_services=None):
    t_path = templates_path(template_service)
    if not os.path.isfile(t_path):
        raise FileNotFoundError(f"Template file '{t_path}' not found.")

    with open(t_path, "r") as f:
        template = f.read()

    if value_services is None:
        value_services = [template_service]

    values = load_values(value_services)

    required_keys = set(re.findall(r"\{\{(\w+)\}\}", template))
    missing_keys = [k for k in required_keys if k not in values]

    if missing_keys:
        print("Error: Missing values for keys:")
        for k in missing_keys:
            print(f" - {k}")
        if len(value_services) == 1:
            print("Tip: Pass additional values files using -v flag, e.g.: -v service1|service2")
        sys.exit(1)

    def replace_var(match):
        key = match.group(1)
        return str(values.get(key, match.group(0)))

    return re.sub(r"\{\{(\w+)\}\}", replace_var, template)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./render_service.py <service.name> [-v service1|service2] [-o [filename]]", file=sys.stderr)
        sys.exit(1)

    template_service = sys.argv[1]

    value_services = None
    output_file = None

    if "-v" in sys.argv:
        idx = sys.argv.index("-v") + 1
        if idx >= len(sys.argv):
            print("Error: -v flag requires a value, e.g.: -v service1|service2", file=sys.stderr)
            sys.exit(1)
        value_services = sys.argv[idx].split("|")

    if "-o" in sys.argv:
        idx = sys.argv.index("-o") + 1
        # If user provides a filename after -o, use it; otherwise default
        if idx < len(sys.argv) and not sys.argv[idx].startswith("-"):
            output_file = sys.argv[idx]
        else:
            output_file = f"{template_service}.service.yaml"
        output_file = os.path.join(OUT_DIR, output_file)

    try:
        rendered = render_service(template_service, value_services)
        if output_file:
            with open(output_file, "w") as f:
                f.write(rendered)
            print(f"Rendered output written to {output_file}")
        else:
            print(rendered)
    except Exception as e:
        print(f"Error rendering service: {e}", file=sys.stderr)
        sys.exit(1)
