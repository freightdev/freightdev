#!/usr/bin/env python3
"""
Conversation Export Indexer
Indexes Claude AI and OpenAI conversation exports into DuckDB for analysis
"""

import duckdb
import json
import os
from pathlib import Path
from datetime import datetime
import zipfile
import tempfile
import shutil
import re

try:
    import toml
    HAS_TOML = True
except ImportError:
    HAS_TOML = False

class ConversationIndexer:
    def __init__(self, db_path="conversations.duckdb", extract_artifacts=False, artifacts_dir="./artifacts", config=None):
        self.db_path = db_path
        self.extract_artifacts = extract_artifacts
        self.artifacts_dir = Path(artifacts_dir)
        if extract_artifacts:
            self.artifacts_dir.mkdir(exist_ok=True)
        self.config = config or {}
        self.conn = duckdb.connect(db_path)
        self._create_schema()

    def _create_schema(self):
        """Create normalized schema for both Claude and OpenAI conversations"""

        # Main conversations table
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS conversations (
                id VARCHAR PRIMARY KEY,
                source VARCHAR NOT NULL,  -- 'claude' or 'openai'
                title VARCHAR,
                created_at TIMESTAMP,
                updated_at TIMESTAMP,
                is_starred BOOLEAN DEFAULT FALSE,
                is_archived BOOLEAN DEFAULT FALSE,
                summary TEXT,
                export_file VARCHAR,
                message_count INTEGER,
                raw_data JSON
            )
        """)

        # Messages table
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id VARCHAR PRIMARY KEY,
                conversation_id VARCHAR NOT NULL,
                sender VARCHAR,  -- 'human', 'assistant', 'system'
                text TEXT,
                created_at TIMESTAMP,
                has_attachments BOOLEAN DEFAULT FALSE,
                raw_data JSON,
                FOREIGN KEY (conversation_id) REFERENCES conversations(id)
            )
        """)

        # Create full-text search indexes
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS conversation_fts (
                conversation_id VARCHAR PRIMARY KEY,
                searchable_text TEXT
            )
        """)

        # Topics/tags table (for categorization)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS conversation_topics (
                conversation_id VARCHAR,
                topic VARCHAR,
                confidence FLOAT DEFAULT 1.0,
                PRIMARY KEY (conversation_id, topic),
                FOREIGN KEY (conversation_id) REFERENCES conversations(id)
            )
        """)

        # Artifacts table (images, audio, files, etc.)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS artifacts (
                id VARCHAR PRIMARY KEY,
                conversation_id VARCHAR,
                file_name VARCHAR,
                file_path VARCHAR,
                file_type VARCHAR,  -- 'image', 'audio', 'document', 'other'
                file_extension VARCHAR,
                file_size INTEGER,
                extracted_to VARCHAR,
                export_file VARCHAR,
                created_at TIMESTAMP,
                FOREIGN KEY (conversation_id) REFERENCES conversations(id)
            )
        """)

        print("✓ Database schema created")

    def index_claude_export(self, export_path):
        """Index a Claude AI export zip file"""
        print(f"\nIndexing Claude export: {export_path}")

        # First, index artifacts
        artifact_count = 0
        with zipfile.ZipFile(export_path, 'r') as zip_ref:
            for file_info in zip_ref.filelist:
                if not file_info.filename.endswith('/'):
                    self._index_artifact(export_path, file_info, None,
                                       os.path.basename(export_path), None)
                    artifact_count += 1

        if artifact_count > 0:
            print(f"  ✓ Indexed {artifact_count} artifacts")

        with tempfile.TemporaryDirectory() as tmpdir:
            # Extract zip
            with zipfile.ZipFile(export_path, 'r') as zip_ref:
                zip_ref.extractall(tmpdir)

            # Load conversations.json
            conv_file = os.path.join(tmpdir, 'conversations.json')
            with open(conv_file, 'r') as f:
                conversations = json.load(f)

            count = 0
            for conv in conversations:
                conv_id = conv.get('uuid')
                if not conv_id:
                    continue

                # Parse timestamp
                created_at = self._parse_timestamp(conv.get('created_at'))
                updated_at = self._parse_timestamp(conv.get('updated_at'))

                # Insert conversation
                self.conn.execute("""
                    INSERT OR REPLACE INTO conversations VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    conv_id,
                    'claude',
                    conv.get('name', ''),
                    created_at,
                    updated_at,
                    False,  # is_starred
                    False,  # is_archived
                    conv.get('summary', ''),
                    os.path.basename(export_path),
                    len(conv.get('chat_messages', [])),
                    json.dumps(conv)
                ))

                # Insert messages
                searchable_parts = []
                for msg in conv.get('chat_messages', []):
                    msg_id = msg.get('uuid')
                    if not msg_id:
                        continue

                    text = msg.get('text', '')
                    searchable_parts.append(text)

                    self.conn.execute("""
                        INSERT OR REPLACE INTO messages VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, (
                        msg_id,
                        conv_id,
                        msg.get('sender', 'unknown'),
                        text,
                        self._parse_timestamp(msg.get('created_at')),
                        len(msg.get('attachments', [])) > 0 or len(msg.get('files', [])) > 0,
                        json.dumps(msg)
                    ))

                # Build searchable text
                if searchable_parts:
                    searchable = f"{conv.get('name', '')} {conv.get('summary', '')} " + " ".join(searchable_parts)
                    self.conn.execute("""
                        INSERT OR REPLACE INTO conversation_fts VALUES (?, ?)
                    """, (conv_id, searchable))

                count += 1

            print(f"  ✓ Indexed {count} conversations")

    def index_openai_export(self, export_path):
        """Index an OpenAI export zip file"""
        print(f"\nIndexing OpenAI export: {export_path}")

        # First, index artifacts
        artifact_count = 0
        with zipfile.ZipFile(export_path, 'r') as zip_ref:
            for file_info in zip_ref.filelist:
                if not file_info.filename.endswith('/'):
                    self._index_artifact(export_path, file_info, None,
                                       os.path.basename(export_path), None)
                    artifact_count += 1

        if artifact_count > 0:
            print(f"  ✓ Indexed {artifact_count} artifacts")

        with tempfile.TemporaryDirectory() as tmpdir:
            # Extract zip
            with zipfile.ZipFile(export_path, 'r') as zip_ref:
                zip_ref.extractall(tmpdir)

            # Load conversations.json
            conv_file = os.path.join(tmpdir, 'conversations.json')
            with open(conv_file, 'r') as f:
                conversations = json.load(f)

            count = 0
            for conv in conversations:
                conv_id = conv.get('conversation_id') or conv.get('id')
                if not conv_id:
                    continue

                # Parse timestamps (OpenAI uses Unix timestamps, sometimes in milliseconds)
                create_time = conv.get('create_time', 0)
                update_time = conv.get('update_time', 0)

                # Handle timestamps in milliseconds (> year 3000 when interpreted as seconds)
                if create_time and create_time > 32503680000:  # Jan 1, 3000
                    create_time = create_time / 1000
                if update_time and update_time > 32503680000:
                    update_time = update_time / 1000

                created_at = datetime.fromtimestamp(create_time) if create_time else None
                updated_at = datetime.fromtimestamp(update_time) if update_time else None

                # Extract messages from mapping
                mapping = conv.get('mapping', {})
                messages_data = []
                for msg_id, msg_entry in mapping.items():
                    msg = msg_entry.get('message')
                    if msg and msg.get('content'):
                        messages_data.append((msg_id, msg))

                # Insert conversation
                self.conn.execute("""
                    INSERT OR REPLACE INTO conversations VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    conv_id,
                    'openai',
                    conv.get('title', ''),
                    created_at,
                    updated_at,
                    conv.get('is_starred') or False,
                    conv.get('is_archived') or False,
                    '',  # no summary in OpenAI
                    os.path.basename(export_path),
                    len(messages_data),
                    json.dumps(conv)
                ))

                # Insert messages
                searchable_parts = []
                for msg_id, msg in messages_data:
                    # Extract text from parts
                    parts = msg.get('content', {}).get('parts', [])
                    text = ' '.join(str(p) for p in parts if p)
                    searchable_parts.append(text)

                    author = msg.get('author', {})
                    sender = author.get('role', 'unknown')

                    # Map OpenAI roles to our schema
                    if sender == 'user':
                        sender = 'human'

                    created = msg.get('create_time')
                    if created and created > 32503680000:  # Handle milliseconds
                        created = created / 1000
                    created_at = datetime.fromtimestamp(created) if created else None

                    self.conn.execute("""
                        INSERT OR REPLACE INTO messages VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, (
                        msg_id,
                        conv_id,
                        sender,
                        text,
                        created_at,
                        False,  # attachments - would need deeper inspection
                        json.dumps(msg)
                    ))

                # Build searchable text
                if searchable_parts:
                    searchable = f"{conv.get('title', '')} " + " ".join(searchable_parts)
                    self.conn.execute("""
                        INSERT OR REPLACE INTO conversation_fts VALUES (?, ?)
                    """, (conv_id, searchable))

                count += 1

            print(f"  ✓ Indexed {count} conversations")

    def _parse_timestamp(self, ts_str):
        """Parse ISO timestamp from Claude exports"""
        if not ts_str:
            return None
        try:
            return datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
        except:
            return None

    def _classify_file_type(self, filename):
        """Classify file by extension"""
        ext = Path(filename).suffix.lower().lstrip('.')
        if ext in ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg']:
            return 'image'
        elif ext in ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac']:
            return 'audio'
        elif ext in ['mp4', 'avi', 'mov', 'mkv', 'webm']:
            return 'video'
        elif ext in ['pdf', 'doc', 'docx', 'txt', 'md', 'rtf']:
            return 'document'
        elif ext in ['zip', 'tar', 'gz', 'rar', '7z']:
            return 'archive'
        elif ext in ['json', 'xml', 'csv', 'yaml', 'yml']:
            return 'data'
        elif ext in ['py', 'js', 'java', 'cpp', 'c', 'go', 'rs', 'html', 'css']:
            return 'code'
        else:
            return 'other'

    def _index_artifact(self, zip_path, file_info, conversation_id, export_file, tmpdir):
        """Index an artifact file from the export"""
        filename = file_info.filename
        file_size = file_info.file_size

        # Skip directories and metadata files
        if filename.endswith('/') or filename in ['user.json', 'conversations.json',
                                                    'message_feedback.json', 'group_chats.json',
                                                    'sora.json', 'shopping.json', 'chat.html',
                                                    'users.json', 'projects.json',
                                                    'shared_conversations.json']:
            return

        file_type = self._classify_file_type(filename)
        file_ext = Path(filename).suffix.lower().lstrip('.')

        # Generate unique ID for artifact
        artifact_id = f"{Path(export_file).stem}_{filename.replace('/', '_')}"

        # Optionally extract the file
        extracted_to = None
        if self.extract_artifacts:
            # Create subdirectory for this export
            export_artifacts_dir = self.artifacts_dir / Path(export_file).stem
            export_artifacts_dir.mkdir(exist_ok=True)

            # Extract file
            extracted_path = export_artifacts_dir / Path(filename).name
            try:
                with zipfile.ZipFile(zip_path, 'r') as zf:
                    with zf.open(filename) as source, open(extracted_path, 'wb') as target:
                        shutil.copyfileobj(source, target)
                extracted_to = str(extracted_path)
            except:
                pass  # Skip files that can't be extracted

        # Insert into artifacts table
        self.conn.execute("""
            INSERT OR REPLACE INTO artifacts VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            artifact_id,
            conversation_id,
            Path(filename).name,
            filename,
            file_type,
            file_ext,
            file_size,
            extracted_to,
            export_file,
            None  # created_at - we don't have this info from zip
        ))

        return artifact_id

    def index_all_exports(self, exports_dir):
        """Index all exports in the directory"""
        exports_path = Path(exports_dir).expanduser()

        # Index Claude exports
        claude_dir = exports_path / 'claude-ai'
        if claude_dir.exists():
            for zip_file in claude_dir.glob('*.zip'):
                self.index_claude_export(str(zip_file))

        # Index OpenAI exports
        openai_dir = exports_path / 'openai-ai'
        if openai_dir.exists():
            for zip_file in openai_dir.glob('*.zip'):
                self.index_openai_export(str(zip_file))

        print("\n" + "="*60)
        self.print_stats()

    def print_stats(self):
        """Print database statistics"""
        stats = self.conn.execute("""
            SELECT
                source,
                COUNT(*) as conversation_count,
                SUM(message_count) as total_messages,
                MIN(created_at) as earliest,
                MAX(created_at) as latest
            FROM conversations
            GROUP BY source
            ORDER BY source
        """).fetchall()

        print("\n📊 INDEX STATISTICS:")
        print("-" * 60)
        for source, conv_count, msg_count, earliest, latest in stats:
            print(f"\n{source.upper()}:")
            print(f"  Conversations: {conv_count:,}")
            print(f"  Messages: {msg_count:,}")
            if earliest:
                print(f"  Date range: {earliest.date()} to {latest.date()}")

        total_convs = self.conn.execute("SELECT COUNT(*) FROM conversations").fetchone()[0]
        total_msgs = self.conn.execute("SELECT COUNT(*) FROM messages").fetchone()[0]
        print(f"\nTOTAL: {total_convs:,} conversations, {total_msgs:,} messages")

        # Artifact statistics
        artifact_stats = self.conn.execute("""
            SELECT file_type, COUNT(*) as count, SUM(file_size) as total_size
            FROM artifacts
            GROUP BY file_type
            ORDER BY count DESC
        """).fetchall()

        if artifact_stats:
            print("\n📎 ARTIFACTS:")
            for file_type, count, total_size in artifact_stats:
                size_mb = total_size / (1024 * 1024) if total_size else 0
                print(f"  {file_type:10s}: {count:4d} files ({size_mb:7.2f} MB)")

            total_artifacts = self.conn.execute("SELECT COUNT(*) FROM artifacts").fetchone()[0]
            total_size = self.conn.execute("SELECT SUM(file_size) FROM artifacts").fetchone()[0]
            total_size_mb = total_size / (1024 * 1024) if total_size else 0
            print(f"  {'TOTAL':10s}: {total_artifacts:4d} files ({total_size_mb:7.2f} MB)")

        print("-" * 60)

    def close(self):
        self.conn.close()


def load_config(config_path):
    """Load configuration from TOML file"""
    if not HAS_TOML:
        print("⚠️  Warning: toml package not installed. Using defaults.")
        print("   Install with: pip install toml")
        return {}

    if not os.path.exists(config_path):
        return {}

    with open(config_path, 'r') as f:
        return toml.load(f)


if __name__ == "__main__":
    import sys
    import os

    # Get script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Load config
    config_path = os.path.join(script_dir, "config.toml")
    config = load_config(config_path)

    # Get paths from config or use defaults
    paths = config.get('paths', {})
    exports_dir = os.path.join(script_dir, paths.get('exports_dir', 'ai-exports'))
    output_dir = os.path.join(script_dir, paths.get('output_dir', 'outputs'))
    db_name = paths.get('database_name', 'conversations.duckdb')

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    # Database path
    db_path = os.path.join(output_dir, db_name)

    # Get indexing options
    indexing = config.get('indexing', {})
    extract_artifacts = indexing.get('extract_artifacts', False)
    artifacts_dir = os.path.join(output_dir, indexing.get('artifacts_dir', 'extracted_artifacts'))

    # Allow command line override of exports directory
    if len(sys.argv) > 1:
        exports_dir = sys.argv[1]

    print("🔍 Conversation Export Indexer")
    print("="*60)
    print(f"Config: {config_path if os.path.exists(config_path) else 'Not found (using defaults)'}")
    print(f"Exports: {exports_dir}")
    print(f"Database: {db_path}")
    print(f"Extract artifacts: {extract_artifacts}")
    if extract_artifacts:
        print(f"Artifacts dir: {artifacts_dir}")
    print("="*60)

    indexer = ConversationIndexer(
        db_path=db_path,
        extract_artifacts=extract_artifacts,
        artifacts_dir=artifacts_dir,
        config=config
    )
    indexer.index_all_exports(exports_dir)
    indexer.close()

    print(f"\n✅ Indexing complete! Database: {db_path}")
