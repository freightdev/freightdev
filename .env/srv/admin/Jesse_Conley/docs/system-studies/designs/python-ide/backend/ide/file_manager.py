import os
import shutil
import mimetypes
import logging
from pathlib import Path
from typing import Dict
from datetime import datetime

logger = logging.getLogger(__name__)

class FileManager:
    def __init__(self, workspace_root: str = "workspace"):
        self.workspace_root = Path(workspace_root).resolve()
        self.workspace_root.mkdir(exist_ok=True)
        self.allowed_path = self.workspace_root

    def _validate_path(self, path: str) -> Path:
        full_path = (self.workspace_root / path.lstrip('/')).resolve()
        if not str(full_path).startswith(str(self.workspace_root)):
            raise ValueError("Path outside workspace not allowed")
        return full_path

    def get_file_tree(self, path: str = "", max_depth: int = 3) -> Dict:
        try:
            full_path = self._validate_path(path)
            if not full_path.exists():
                return {"error": "Path not found"}
            return self._build_tree_node(full_path, 0, max_depth)
        except Exception as e:
            logger.error(f"Error building file tree: {e}")
            return {"error": str(e)}

    def _build_tree_node(self, path: Path, current_depth: int, max_depth: int) -> Dict:
        try:
            stat = path.stat()
            node = {
                "name": path.name,
                "path": str(path.relative_to(self.workspace_root)),
                "type": "directory" if path.is_dir() else "file",
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "children": []
            }

            if path.is_file():
                node.update({
                    "extension": path.suffix,
                    "language": self._detect_language(path),
                    "is_binary": self._is_binary_file(path)
                })

            if path.is_dir() and current_depth < max_depth:
                children = [
                    self._build_tree_node(child, current_depth + 1, max_depth)
                    for child in sorted(path.iterdir())
                    if not child.name.startswith('.')
                ]
                node["children"] = sorted(children, key=lambda x: (x["type"] != "directory", x["name"].lower()))
            return node
        except Exception as e:
            logger.error(f"Error processing {path}: {e}")
            return {"name": path.name, "path": str(path.relative_to(self.workspace_root)), "type": "error", "error": str(e)}

    def read_file(self, path: str, encoding: str = 'utf-8') -> Dict:
        try:
            full_path = self._validate_path(path)
            if not full_path.exists(): return {"error": "File not found"}
            if not full_path.is_file(): return {"error": "Path is not a file"}
            if self._is_binary_file(full_path): return {"error": "Cannot read binary file", "is_binary": True}

            with open(full_path, 'r', encoding=encoding) as f:
                content = f.read()
            stat = full_path.stat()
            return {
                "content": content,
                "path": path,
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "language": self._detect_language(full_path),
                "encoding": encoding,
                "lines": len(content.splitlines())
            }
        except Exception as e:
            logger.error(f"Error reading file {path}: {e}")
            return {"error": str(e)}

    def write_file(self, path: str, content: str, encoding: str = 'utf-8') -> Dict:
        try:
            full_path = self._validate_path(path)
            full_path.parent.mkdir(parents=True, exist_ok=True)
            if full_path.exists():
                backup_path = full_path.with_suffix(full_path.suffix + '.bak')
                shutil.copy2(full_path, backup_path)
            with open(full_path, 'w', encoding=encoding) as f:
                f.write(content)
            stat = full_path.stat()
            return {"success": True, "path": path, "size": stat.st_size, "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(), "lines": len(content.splitlines())}
        except Exception as e:
            logger.error(f"Error writing file {path}: {e}")
            return {"error": str(e)}

    def create_file(self, path: str, content: str = "") -> Dict:
        try:
            full_path = self._validate_path(path)
            if full_path.exists(): return {"error": "File already exists"}
            return self.write_file(path, content)
        except Exception as e:
            logger.error(f"Error creating file {path}: {e}")
            return {"error": str(e)}

    def create_directory(self, path: str) -> Dict:
        try:
            full_path = self._validate_path(path)
            full_path.mkdir(parents=True, exist_ok=True)
            return {"success": True, "path": path, "type": "directory"}
        except Exception as e:
            logger.error(f"Error creating directory {path}: {e}")
            return {"error": str(e)}

    def delete_path(self, path: str) -> Dict:
        try:
            full_path = self._validate_path(path)
            if not full_path.exists(): return {"error": "Path not found"}
            if full_path.is_file(): full_path.unlink()
            elif full_path.is_dir(): shutil.rmtree(full_path)
            return {"success": True, "path": path}
        except Exception as e:
            logger.error(f"Error deleting {path}: {e}")
            return {"error": str(e)}

    def rename_path(self, old_path: str, new_name: str) -> Dict:
        try:
            old_full_path = self._validate_path(old_path)
            new_full_path = old_full_path.parent / new_name
            self._validate_path(str(new_full_path.relative_to(self.workspace_root)))
            if not old_full_path.exists(): return {"error": "Path not found"}
            if new_full_path.exists(): return {"error": "Target path already exists"}
            old_full_path.rename(new_full_path)
            return {"success": True, "old_path": old_path, "new_path": str(new_full_path.relative_to(self.workspace_root))}
        except Exception as e:
            logger.error(f"Error renaming {old_path}: {e}")
            return {"error": str(e)}

    def _detect_language(self, file_path: Path) -> str:
        extension = file_path.suffix.lower()
        language_map = {
            '.py':'python', '.js':'javascript', '.ts':'typescript', '.jsx':'javascriptreact', '.tsx':'typescriptreact',
            '.rs':'rust', '.go':'go', '.java':'java', '.cpp':'cpp', '.cc':'cpp', '.cxx':'cpp', '.c':'c', '.h':'c',
            '.html':'html', '.htm':'html', '.css':'css', '.scss':'scss', '.sass':'sass', '.json':'json', '.xml':'xml',
            '.yaml':'yaml', '.yml':'yaml', '.md':'markdown', '.txt':'plaintext', '.sh':'shellscript', '.bash':'shellscript',
            '.zsh':'shellscript', '.sql':'sql', '.toml':'toml', '.ini':'ini', '.cfg':'ini', '.dockerfile':'dockerfile'
        }
        filename = file_path.name.lower()
        if filename == 'dockerfile': return 'dockerfile'
        elif filename == 'makefile': return 'makefile'
        elif filename.startswith('.env'): return 'properties'
        return language_map.get(extension, 'plaintext')

    def _is_binary_file(self, file_path: Path) -> bool:
        try:
            mime_type, _ = mimetypes.guess_type(str(file_path))
            if mime_type and not mime_type.startswith('text/'): return True
            with open(file_path, 'rb') as f:
                return b'\0' in f.read(8192)
        except Exception:
            return True

# Global instance
file_manager = FileManager()
