"""TODO"""
import os
from pathlib import Path
import ast

# Define the root directory where your codebase is located
project_root = Path(__file__).resolve().parent
backend_dir = project_root / "backend"


def add_docstrings_to_file(file_path: Path):
    """
    This function adds missing docstrings to a Python file.
    - Adds a module-level docstring if missing.
    - Adds a class-level docstring to classes that are missing one.
    """
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Parse the file content using the Abstract Syntax Tree (AST)
    tree = ast.parse(content)
    classes = [node for node in tree.body if isinstance(node, ast.ClassDef)]

    # Check if a module-level docstring is missing and add it
    if not content.strip().startswith('"""'):
        module_docstring = '"""Module docstring goes here."""\n\n'
        content = module_docstring + content.lstrip()

    # Check for each class and add a docstring if missing
    for class_node in classes:
        # Check if the class already has a docstring
        if not ast.get_docstring(class_node):
            class_line = content.splitlines()[class_node.lineno]
            indent = len(class_line) - len(class_line.lstrip())
            class_docstring = (
                f'{" " * indent}"""Docstring {class_node.name} goes here."""\n'
            )

            # Insert the docstring just after the class definition
            content = (
                content[:class_node.lineno + len(class_line)] +
                class_docstring +
                content[class_node.lineno + len(class_line):]
            )

    # Save the modified content back to the file
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Updated docstrings in: {file_path}")


def update_codebase_with_docstrings():
    """
    This function will traverse the Python codebase in the backend directory
    and add missing docstrings to the top of files and under each class.
    """
    # Walk through all the Python files in the 'backend' directory
    for root, dirs, files in os.walk(backend_dir):
        # Skip __pycache__ directories to avoid modifying compiled files
        if "__pycache__" in dirs:
            dirs.remove("__pycache__")

        for file in files:
            if file.endswith(".py"):  # Only process Python files
                file_path = Path(root) / file
                add_docstrings_to_file(file_path)

    print("Updated codebase with missing docstrings.")


# Run the function
if __name__ == "__main__":
    update_codebase_with_docstrings()
