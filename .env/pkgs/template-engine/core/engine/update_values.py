# update_vaules.py
#!/usr/bin/env python3
import sys
import os
import yaml
import subprocess
from config_base import values_path

def update_single_key(service, key, value):
    path = values_path(service)
    if not os.path.isfile(path):
        print(f"Error: {path} not found", file=sys.stderr)
        sys.exit(1)

    with open(path, "r") as f:
        data = yaml.safe_load(f) or {}

    data[key] = value

    with open(path, "w") as f:
        yaml.safe_dump(data, f, sort_keys=False)

    print(f"Updated {key}: {value} in {service}.values.yaml")

def edit_values_file(service):
    path = values_path(service)
    if not os.path.isfile(path):
        # create empty file if missing
        with open(path, "w") as f:
            f.write("# Edit your values here\n")
    editor = os.environ.get("EDITOR", "vim")
    subprocess.run([editor, path])

def main():
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python3 update_values.py <service> -k <key> -v <value>")
        print("  python3 update_values.py <service> edit")
        sys.exit(1)

    service = sys.argv[1]

    # Edit mode
    if sys.argv[2] == "edit":
        edit_values_file(service)
        return

    # Single key/value mode
    if "-k" in sys.argv and "-v" in sys.argv:
        try:
            key_index = sys.argv.index("-k") + 1
            val_index = sys.argv.index("-v") + 1
            key = sys.argv[key_index]
            value = sys.argv[val_index]
        except (ValueError, IndexError):
            print("Error: missing key or value for -k or -v", file=sys.stderr)
            sys.exit(1)

        update_single_key(service, key, value)
        return

    print("Invalid arguments. Use -k/-v or edit.")
    sys.exit(1)

if __name__ == "__main__":
    main()
