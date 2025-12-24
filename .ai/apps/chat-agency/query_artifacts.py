#!/usr/bin/env python3
"""
Query interface for artifacts (images, audio, files) in exports
"""

import duckdb
import sys
import shutil
from pathlib import Path

class ArtifactQuery:
    def __init__(self, db_path="conversations.duckdb"):
        self.conn = duckdb.connect(db_path, read_only=True)

    def list_by_type(self, file_type=None):
        """List artifacts by type"""
        if file_type:
            results = self.conn.execute("""
                SELECT file_name, file_size, conversation_id, export_file
                FROM artifacts
                WHERE file_type = ?
                ORDER BY file_size DESC
            """, (file_type,)).fetchall()
            print(f"\n{file_type.upper()} FILES ({len(results)} found)")
        else:
            results = self.conn.execute("""
                SELECT file_type, COUNT(*) as count, SUM(file_size) as total_size
                FROM artifacts
                GROUP BY file_type
                ORDER BY count DESC
            """).fetchall()
            print("\nFILE TYPES SUMMARY")
            print("-" * 60)
            for ftype, count, total_size in results:
                size_mb = total_size / (1024 * 1024) if total_size else 0
                print(f"{ftype:12s}: {count:5d} files  ({size_mb:8.2f} MB)")
            return

        print("-" * 80)
        for fname, fsize, conv_id, export in results[:50]:
            size_kb = fsize / 1024 if fsize else 0
            conv_display = conv_id[:20] if conv_id else "N/A"
            print(f"{fname[:40]:40s} {size_kb:8.1f} KB  [{conv_display}]")

        if len(results) > 50:
            print(f"\n... and {len(results) - 50} more")

    def find_by_name(self, pattern):
        """Find artifacts matching a name pattern"""
        results = self.conn.execute("""
            SELECT a.file_name, a.file_type, a.file_size, c.title
            FROM artifacts a
            LEFT JOIN conversations c ON a.conversation_id = c.id
            WHERE a.file_name ILIKE ?
            ORDER BY a.file_size DESC
        """, (f'%{pattern}%',)).fetchall()

        print(f"\n🔍 Files matching '{pattern}' ({len(results)} found)")
        print("-" * 80)

        for fname, ftype, fsize, conv_title in results:
            size_kb = fsize / 1024 if fsize else 0
            title = conv_title[:40] if conv_title else "No conversation"
            print(f"{fname[:35]:35s} [{ftype:8s}] {size_kb:7.1f} KB  | {title}")

    def largest_files(self, limit=20):
        """Show largest files"""
        results = self.conn.execute("""
            SELECT file_name, file_type, file_size, conversation_id
            FROM artifacts
            ORDER BY file_size DESC
            LIMIT ?
        """, (limit,)).fetchall()

        print(f"\n📦 Largest Files (top {limit})")
        print("-" * 80)

        for fname, ftype, fsize, conv_id in results:
            size_mb = fsize / (1024 * 1024) if fsize else 0
            print(f"{fname[:45]:45s} [{ftype:8s}] {size_mb:6.2f} MB")

    def images_by_conversation(self, conversation_id=None):
        """List images grouped by conversation"""
        if conversation_id:
            results = self.conn.execute("""
                SELECT a.file_name, a.file_size, c.title
                FROM artifacts a
                JOIN conversations c ON a.conversation_id = c.id
                WHERE c.id LIKE ? AND a.file_type = 'image'
                ORDER BY a.file_name
            """, (f'%{conversation_id}%',)).fetchall()

            if not results:
                print(f"No images found for conversation: {conversation_id}")
                return

            print(f"\n🖼️  Images in conversation")
            print("-" * 80)
            for fname, fsize, title in results:
                size_kb = fsize / 1024 if fsize else 0
                print(f"{fname[:50]:50s} {size_kb:7.1f} KB")
        else:
            results = self.conn.execute("""
                SELECT c.id, c.title, COUNT(a.id) as image_count, SUM(a.file_size) as total_size
                FROM conversations c
                JOIN artifacts a ON c.id = a.conversation_id
                WHERE a.file_type = 'image'
                GROUP BY c.id, c.title
                ORDER BY image_count DESC
            """).fetchall()

            print(f"\n🖼️  Conversations with Images ({len(results)} found)")
            print("-" * 80)

            for conv_id, title, img_count, total_size in results[:30]:
                size_mb = total_size / (1024 * 1024) if total_size else 0
                print(f"{img_count:3d} images ({size_mb:5.1f} MB) | {title[:50]}")

            if len(results) > 30:
                print(f"\n... and {len(results) - 30} more")

    def export_artifacts_list(self, output_file, file_type=None):
        """Export artifacts list to CSV"""
        where_clause = "WHERE file_type = ?" if file_type else "WHERE 1=1"
        params = [file_type] if file_type else []

        self.conn.execute(f"""
            COPY (
                SELECT
                    a.file_name,
                    a.file_type,
                    a.file_extension,
                    a.file_size,
                    a.file_path,
                    a.extracted_to,
                    c.title as conversation_title,
                    c.created_at as conversation_date
                FROM artifacts a
                LEFT JOIN conversations c ON a.conversation_id = c.id
                {where_clause}
                ORDER BY a.file_size DESC
            ) TO '{output_file}' (HEADER, DELIMITER ',')
        """, params)

        print(f"✅ Exported artifacts list to {output_file}")

    def extract_files(self, file_type, output_dir):
        """Extract files of a certain type to a directory"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        results = self.conn.execute("""
            SELECT file_name, extracted_to
            FROM artifacts
            WHERE file_type = ? AND extracted_to IS NOT NULL
        """, (file_type,)).fetchall()

        if not results:
            print(f"No extracted {file_type} files found. Run indexer with --extract-artifacts flag.")
            return

        print(f"\n📁 Copying {len(results)} {file_type} files to {output_dir}")

        copied = 0
        for fname, extracted_path in results:
            if Path(extracted_path).exists():
                shutil.copy(extracted_path, output_path / fname)
                copied += 1

        print(f"✅ Copied {copied} files successfully")

    def stats(self):
        """Show artifact statistics"""
        print("\n📊 ARTIFACT STATISTICS")
        print("-" * 80)

        # By type
        type_stats = self.conn.execute("""
            SELECT file_type, COUNT(*) as count, SUM(file_size) as total_size
            FROM artifacts
            GROUP BY file_type
            ORDER BY count DESC
        """).fetchall()

        print("\nBy Type:")
        for ftype, count, total_size in type_stats:
            size_mb = total_size / (1024 * 1024) if total_size else 0
            print(f"  {ftype:12s}: {count:5d} files  ({size_mb:8.2f} MB)")

        # By extension
        print("\nTop Extensions:")
        ext_stats = self.conn.execute("""
            SELECT file_extension, COUNT(*) as count
            FROM artifacts
            GROUP BY file_extension
            ORDER BY count DESC
            LIMIT 10
        """).fetchall()

        for ext, count in ext_stats:
            print(f"  .{ext:10s}: {count:5d} files")

        # Total
        total = self.conn.execute("SELECT COUNT(*), SUM(file_size) FROM artifacts").fetchone()
        if total:
            count, size = total
            size_mb = size / (1024 * 1024) if size else 0
            print(f"\nTOTAL: {count:,} files, {size_mb:.2f} MB")

    def close(self):
        self.conn.close()


def main():
    """Command-line interface"""
    import os

    # Default database path (relative to script location)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_db = os.path.join(script_dir, "outputs", "conversations.duckdb")

    if len(sys.argv) < 2:
        print("""
Usage:
  python query_artifacts.py list [type]        - List artifacts by type
  python query_artifacts.py find <pattern>     - Find files by name pattern
  python query_artifacts.py largest [n]        - Show largest files
  python query_artifacts.py images [conv_id]   - List images by conversation
  python query_artifacts.py stats              - Show artifact statistics
  python query_artifacts.py export <file.csv> [type] - Export to CSV

Examples:
  python query_artifacts.py list image
  python query_artifacts.py list audio
  python query_artifacts.py find screenshot
  python query_artifacts.py largest 50
  python query_artifacts.py images
  python query_artifacts.py export artifacts.csv image
        """)
        return

    cmd = sys.argv[1]
    query = ArtifactQuery(default_db)

    try:
        if cmd == 'list':
            file_type = sys.argv[2] if len(sys.argv) > 2 else None
            query.list_by_type(file_type)

        elif cmd == 'find' and len(sys.argv) > 2:
            query.find_by_name(sys.argv[2])

        elif cmd == 'largest':
            limit = int(sys.argv[2]) if len(sys.argv) > 2 else 20
            query.largest_files(limit)

        elif cmd == 'images':
            conv_id = sys.argv[2] if len(sys.argv) > 2 else None
            query.images_by_conversation(conv_id)

        elif cmd == 'stats':
            query.stats()

        elif cmd == 'export' and len(sys.argv) > 2:
            output_file = sys.argv[2]
            file_type = sys.argv[3] if len(sys.argv) > 3 else None
            query.export_artifacts_list(output_file, file_type)

        else:
            print("Unknown command. Use: list, find, largest, images, stats, export")

    finally:
        query.close()


if __name__ == "__main__":
    main()
