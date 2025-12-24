#!/usr/bin/env python3
"""
Code Indexer - Creates SQLite FTS5 index for fast code search
Better than DuckDB for this use case - lighter weight, optimized for search
"""

import sqlite3
import os
import sys
from pathlib import Path
import mimetypes
from datetime import datetime

DB_PATH = "/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/data/code_index.db"

# Directories to index
INDEX_ROOTS = [
    "/home/admin/WORKSPACE/projects/ACTIVE/codriver",
    "/home/admin/WORKSPACE/services",
    "/home/admin/WORKSPACE/websites",
]

# Exclude patterns
EXCLUDE_DIRS = {
    "node_modules", "target", ".git", "dist", "build",
    "__pycache__", ".next", ".venv", "venv", "coverage"
}

EXCLUDE_EXTS = {
    ".pyc", ".so", ".dylib", ".o", ".a", ".class",
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg",
    ".woff", ".woff2", ".ttf", ".eot"
}

def should_index(file_path):
    """Check if file should be indexed"""
    path = Path(file_path)

    # Check excluded directories
    for part in path.parts:
        if part in EXCLUDE_DIRS:
            return False

    # Check excluded extensions
    if path.suffix in EXCLUDE_EXTS:
        return False

    # Check if text file
    mime_type, _ = mimetypes.guess_type(str(path))
    if mime_type and not mime_type.startswith('text'):
        return False

    # Check file size (skip files > 1MB)
    try:
        if path.stat().st_size > 1_000_000:
            return False
    except:
        return False

    return True

def create_index():
    """Create SQLite FTS5 index"""
    # Ensure directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Drop existing table
    cur.execute("DROP TABLE IF EXISTS code_files")

    # Create FTS5 table
    cur.execute("""
        CREATE VIRTUAL TABLE code_files USING fts5(
            file_path UNINDEXED,
            content,
            language UNINDEXED,
            size UNINDEXED,
            modified UNINDEXED,
            tokenize='porter ascii'
        )
    """)

    print(f"🔍 Indexing code files...")
    indexed = 0
    skipped = 0

    for root in INDEX_ROOTS:
        for file_path in Path(root).rglob('*'):
            if not file_path.is_file():
                continue

            if not should_index(file_path):
                skipped += 1
                continue

            try:
                # Read file content
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()

                # Determine language
                ext_map = {
                    '.rs': 'rust', '.go': 'go', '.py': 'python',
                    '.js': 'javascript', '.ts': 'typescript',
                    '.md': 'markdown', '.yaml': 'yaml', '.yml': 'yaml',
                    '.toml': 'toml', '.json': 'json', '.sh': 'bash'
                }
                language = ext_map.get(file_path.suffix, 'unknown')

                # Get file stats
                stat = file_path.stat()

                # Insert into index
                cur.execute("""
                    INSERT INTO code_files (file_path, content, language, size, modified)
                    VALUES (?, ?, ?, ?, ?)
                """, (
                    str(file_path),
                    content,
                    language,
                    stat.st_size,
                    datetime.fromtimestamp(stat.st_mtime).isoformat()
                ))

                indexed += 1
                if indexed % 100 == 0:
                    print(f"  Indexed {indexed} files...", end='\r')

            except Exception as e:
                print(f"❌ Error indexing {file_path}: {e}")
                continue

    conn.commit()
    conn.close()

    print(f"\n✅ Indexed {indexed} files (skipped {skipped})")
    print(f"📁 Database: {DB_PATH}")
    print(f"📊 Size: {Path(DB_PATH).stat().st_size / 1024 / 1024:.2f} MB")

def search(query, limit=20):
    """Search the index"""
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
        SELECT file_path, snippet(code_files, 1, '→ ', ' ←', '...', 30) as snippet, language
        FROM code_files
        WHERE code_files MATCH ?
        ORDER BY rank
        LIMIT ?
    """, (query, limit))

    results = cur.fetchall()
    conn.close()

    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Build index:  python code-indexer.py build")
        print("  Search:       python code-indexer.py search 'your query'")
        sys.exit(1)

    command = sys.argv[1]

    if command == "build":
        create_index()
    elif command == "search":
        if len(sys.argv) < 3:
            print("❌ Please provide search query")
            sys.exit(1)

        query = " ".join(sys.argv[2:])
        print(f"🔍 Searching for: {query}\n")

        results = search(query)
        if not results:
            print("No results found")
        else:
            for i, (path, snippet, lang) in enumerate(results, 1):
                print(f"{i}. [{lang}] {path}")
                print(f"   {snippet}")
                print()
    else:
        print(f"❌ Unknown command: {command}")
