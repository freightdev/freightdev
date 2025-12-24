"""TODO"""
import os
from pathlib import Path

import dotenv

# Load environment variables from the .env file
dotenv.load_dotenv()

# Define the root and backend directories
project_root = Path(__file__).resolve().parent
backend_dir = project_root / "backend"
env_file_path = project_root / ".env"


def update_codebase_with_env():
    """
    This function will traverse the project files and update any
    environment variable placeholders in the Python codebase with the
    corresponding values from the .env file.
    """
    # Fetch all environment variables loaded from .env
    env_vars = os.environ

    # Walk through all the Python files in the 'backend' directory
    for root, dirs, files in os.walk(backend_dir):
        # Skip __pycache__ directories to avoid modifying compiled files
        if "__pycache__" in dirs:
            dirs.remove("__pycache__")

        for file in files:
            if file.endswith(".py"):  # Only process Python files
                file_path = Path(root) / file

                # Open the file for reading
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()

                # Replace placeholders with actual environment variable values
                for key, value in env_vars.items():
                    content = content.replace(f"{key}", value)

                # Write the modified content back to the file
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(content)

                print(f"Updated {file_path}")

    print(f"Updated codebase with values from {env_file_path}")


# Run the function
if __name__ == "__main__":
    update_codebase_with_env()
