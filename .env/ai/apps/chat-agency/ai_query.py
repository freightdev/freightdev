#!/usr/bin/env python3
"""
AI Query Interface for Conversation Database
Provides rich querying capabilities for AI assistants to retrieve and organize conversation data
"""

import duckdb
import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional, Any
import re

class AIQuery:
    def __init__(self, db_path="conversations.duckdb", output_dir="outputs/queries"):
        self.db_path = db_path
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.conn = duckdb.connect(db_path, read_only=True)

    def get_conversation_by_id(self, conv_id: str, include_messages: bool = True) -> Optional[Dict]:
        """
        Retrieve a full conversation by ID
        Returns: Dict with conversation metadata and optionally all messages
        """
        # Get conversation metadata
        conv = self.conn.execute("""
            SELECT id, source, title, created_at, updated_at,
                   message_count, summary, export_file
            FROM conversations
            WHERE id LIKE ?
        """, (f'%{conv_id}%',)).fetchone()

        if not conv:
            return None

        conv_id, source, title, created, updated, msg_count, summary, export_file = conv

        result = {
            'id': conv_id,
            'source': source,
            'title': title,
            'created_at': created.isoformat() if created else None,
            'updated_at': updated.isoformat() if updated else None,
            'message_count': msg_count,
            'summary': summary,
            'export_file': export_file,
            'messages': []
        }

        if include_messages:
            messages = self.conn.execute("""
                SELECT id, sender, text, created_at, has_attachments
                FROM messages
                WHERE conversation_id = ?
                ORDER BY created_at
            """, (conv_id,)).fetchall()

            for msg_id, sender, text, created, has_attachments in messages:
                result['messages'].append({
                    'id': msg_id,
                    'sender': sender,
                    'text': text,
                    'created_at': created.isoformat() if created else None,
                    'has_attachments': has_attachments
                })

        return result

    def get_multiple_conversations(self, conv_ids: List[str], include_messages: bool = True) -> List[Dict]:
        """Retrieve multiple conversations by IDs"""
        results = []
        for conv_id in conv_ids:
            conv = self.get_conversation_by_id(conv_id, include_messages)
            if conv:
                results.append(conv)
        return results

    def search_conversations(self,
                           query: Optional[str] = None,
                           source: Optional[str] = None,
                           start_date: Optional[str] = None,
                           end_date: Optional[str] = None,
                           min_messages: Optional[int] = None,
                           max_messages: Optional[int] = None,
                           limit: int = 50,
                           include_messages: bool = False) -> List[Dict]:
        """
        Advanced search with multiple filters

        Args:
            query: Text to search for in conversations
            source: Filter by source ('claude' or 'openai')
            start_date: Filter conversations after this date (YYYY-MM-DD)
            end_date: Filter conversations before this date (YYYY-MM-DD)
            min_messages: Minimum number of messages
            max_messages: Maximum number of messages
            limit: Maximum results to return
            include_messages: Include full message text in results

        Returns:
            List of matching conversations
        """
        conditions = []
        params = []

        # Build WHERE clause
        if query:
            conditions.append("fts.searchable_text ILIKE ?")
            params.append(f'%{query}%')

        if source:
            conditions.append("c.source = ?")
            params.append(source)

        if start_date:
            conditions.append("c.created_at >= ?")
            params.append(start_date)

        if end_date:
            conditions.append("c.created_at <= ?")
            params.append(end_date)

        if min_messages:
            conditions.append("c.message_count >= ?")
            params.append(min_messages)

        if max_messages:
            conditions.append("c.message_count <= ?")
            params.append(max_messages)

        where_clause = " AND ".join(conditions) if conditions else "1=1"

        # Execute search
        sql = f"""
            SELECT c.id, c.source, c.title, c.created_at, c.updated_at,
                   c.message_count, c.summary, c.export_file
            FROM conversations c
            LEFT JOIN conversation_fts fts ON c.id = fts.conversation_id
            WHERE {where_clause}
            ORDER BY c.created_at DESC
            LIMIT ?
        """
        params.append(limit)

        results = self.conn.execute(sql, params).fetchall()

        conversations = []
        for conv_id, source, title, created, updated, msg_count, summary, export_file in results:
            conv_data = {
                'id': conv_id,
                'source': source,
                'title': title,
                'created_at': created.isoformat() if created else None,
                'updated_at': updated.isoformat() if updated else None,
                'message_count': msg_count,
                'summary': summary,
                'export_file': export_file,
                'messages': []
            }

            if include_messages:
                messages = self.conn.execute("""
                    SELECT id, sender, text, created_at, has_attachments
                    FROM messages
                    WHERE conversation_id = ?
                    ORDER BY created_at
                """, (conv_id,)).fetchall()

                for msg_id, sender, text, created, has_attachments in messages:
                    conv_data['messages'].append({
                        'id': msg_id,
                        'sender': sender,
                        'text': text,
                        'created_at': created.isoformat() if created else None,
                        'has_attachments': has_attachments
                    })

            conversations.append(conv_data)

        return conversations

    def get_conversations_by_date_range(self, start_date: str, end_date: str,
                                       source: Optional[str] = None,
                                       include_messages: bool = False) -> List[Dict]:
        """Get all conversations within a date range"""
        return self.search_conversations(
            start_date=start_date,
            end_date=end_date,
            source=source,
            include_messages=include_messages,
            limit=10000  # Large limit for date ranges
        )

    def get_related_conversations(self, conv_id: str, limit: int = 10) -> List[Dict]:
        """
        Find conversations related to a given conversation
        Uses title similarity and date proximity
        """
        # Get the original conversation
        original = self.get_conversation_by_id(conv_id, include_messages=False)
        if not original:
            return []

        # Extract keywords from title
        title = original.get('title', '')
        # Simple keyword extraction (remove common words)
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for'}
        keywords = [w for w in re.findall(r'\w+', title.lower()) if len(w) > 3 and w not in stop_words]

        if not keywords:
            return []

        # Search for conversations with similar keywords
        keyword_pattern = '|'.join(keywords[:5])  # Use top 5 keywords

        results = self.conn.execute("""
            SELECT c.id, c.source, c.title, c.created_at, c.message_count
            FROM conversations c
            JOIN conversation_fts fts ON c.id = fts.conversation_id
            WHERE fts.searchable_text ~* ?
              AND c.id != ?
            ORDER BY c.created_at DESC
            LIMIT ?
        """, (keyword_pattern, original['id'], limit)).fetchall()

        related = []
        for conv_id, source, title, created, msg_count in results:
            related.append({
                'id': conv_id,
                'source': source,
                'title': title,
                'created_at': created.isoformat() if created else None,
                'message_count': msg_count
            })

        return related

    def extract_code_blocks(self, query: Optional[str] = None, language: Optional[str] = None) -> List[Dict]:
        """
        Extract code blocks from conversations
        Searches for markdown code blocks with optional language filter
        """
        # Search for conversations
        convs = self.search_conversations(query=query, include_messages=True, limit=100)

        code_blocks = []
        code_pattern = r'```(\w+)?\n(.*?)```'

        for conv in convs:
            for msg in conv.get('messages', []):
                text = msg.get('text', '')
                matches = re.findall(code_pattern, text, re.DOTALL)

                for lang, code in matches:
                    if language and lang.lower() != language.lower():
                        continue

                    code_blocks.append({
                        'conversation_id': conv['id'],
                        'conversation_title': conv['title'],
                        'message_id': msg['id'],
                        'sender': msg['sender'],
                        'language': lang or 'unknown',
                        'code': code.strip(),
                        'created_at': msg['created_at']
                    })

        return code_blocks

    def save_query_result(self, result: Any, query_name: str, metadata: Optional[Dict] = None) -> str:
        """
        Save query result to outputs/queries/ with metadata

        Args:
            result: The query result data
            query_name: Name for this query (used for filename/directory)
            metadata: Optional metadata about the query

        Returns:
            Path to saved result
        """
        # Create query-specific directory
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        safe_name = re.sub(r'[^\w\-]', '_', query_name.lower())
        query_dir = self.output_dir / safe_name
        query_dir.mkdir(exist_ok=True)

        # Save result as JSON
        result_file = query_dir / f"{timestamp}_result.json"
        with open(result_file, 'w') as f:
            json.dump(result, f, indent=2, default=str)

        # Save metadata
        meta = metadata or {}
        meta.update({
            'query_name': query_name,
            'timestamp': timestamp,
            'result_file': str(result_file),
            'result_count': len(result) if isinstance(result, list) else 1
        })

        meta_file = query_dir / f"{timestamp}_metadata.json"
        with open(meta_file, 'w') as f:
            json.dump(meta, f, indent=2, default=str)

        return str(result_file)

    def get_query_history(self, query_name: Optional[str] = None) -> List[Dict]:
        """
        Read past query metadata to see what was previously queried

        Args:
            query_name: Optional filter for specific query name

        Returns:
            List of past query metadata
        """
        history = []

        # Search through query directories
        search_dirs = [self.output_dir / query_name] if query_name else list(self.output_dir.iterdir())

        for query_dir in search_dirs:
            if not query_dir.is_dir():
                continue

            # Find all metadata files
            for meta_file in sorted(query_dir.glob('*_metadata.json')):
                try:
                    with open(meta_file, 'r') as f:
                        meta = json.load(f)
                        history.append(meta)
                except:
                    continue

        return sorted(history, key=lambda x: x.get('timestamp', ''), reverse=True)

    def format_as_markdown(self, conversations: List[Dict], include_messages: bool = True) -> str:
        """Format conversations as markdown"""
        lines = []
        lines.append(f"# Query Results ({len(conversations)} conversations)\n")

        for i, conv in enumerate(conversations, 1):
            lines.append(f"## {i}. {conv['title']}")
            lines.append(f"- **Source**: {conv['source']}")
            lines.append(f"- **Created**: {conv['created_at']}")
            lines.append(f"- **Messages**: {conv['message_count']}")
            lines.append(f"- **ID**: `{conv['id']}`")

            if conv.get('summary'):
                lines.append(f"- **Summary**: {conv['summary']}")

            if include_messages and conv.get('messages'):
                lines.append("\n### Messages\n")
                for msg in conv['messages']:
                    sender = msg['sender'].upper()
                    timestamp = msg.get('created_at', 'Unknown')
                    lines.append(f"**[{sender}]** {timestamp}")
                    lines.append(f"{msg['text']}\n")

            lines.append("\n---\n")

        return "\n".join(lines)

    def format_as_text(self, conversations: List[Dict], include_messages: bool = True) -> str:
        """Format conversations as plain text"""
        lines = []
        lines.append("=" * 80)
        lines.append(f"QUERY RESULTS: {len(conversations)} conversations")
        lines.append("=" * 80)
        lines.append("")

        for i, conv in enumerate(conversations, 1):
            lines.append(f"{i}. {conv['title']}")
            lines.append(f"   Source: {conv['source']}")
            lines.append(f"   Created: {conv['created_at']}")
            lines.append(f"   Messages: {conv['message_count']}")
            lines.append(f"   ID: {conv['id']}")

            if conv.get('summary'):
                lines.append(f"   Summary: {conv['summary']}")

            if include_messages and conv.get('messages'):
                lines.append("\n   MESSAGES:")
                for msg in conv['messages']:
                    sender = msg['sender'].upper()
                    lines.append(f"\n   [{sender}] {msg.get('created_at', '')}")
                    # Indent message text
                    text_lines = msg['text'].split('\n')
                    for tl in text_lines:
                        lines.append(f"   {tl}")

            lines.append("\n" + "-" * 80 + "\n")

        return "\n".join(lines)

    def estimate_tokens(self, text: str) -> int:
        """
        Rough token estimate (characters / 4)
        For more accurate counting, use tiktoken library
        """
        return len(text) // 4

    def chunk_conversation(self, conv: Dict, max_tokens: int = 4000) -> List[Dict]:
        """
        Split a conversation into chunks that fit within token limit

        Args:
            conv: Conversation dict with messages
            max_tokens: Maximum tokens per chunk

        Returns:
            List of conversation chunks
        """
        messages = conv.get('messages', [])
        if not messages:
            return [conv]

        chunks = []
        current_chunk = {
            **conv,
            'messages': [],
            'chunk_index': 0,
            'is_chunked': False
        }
        current_tokens = self.estimate_tokens(json.dumps({k: v for k, v in conv.items() if k != 'messages'}))

        for msg in messages:
            msg_text = json.dumps(msg)
            msg_tokens = self.estimate_tokens(msg_text)

            if current_tokens + msg_tokens > max_tokens and current_chunk['messages']:
                # Save current chunk and start new one
                current_chunk['is_chunked'] = True
                chunks.append(current_chunk)
                current_chunk = {
                    **conv,
                    'messages': [],
                    'chunk_index': len(chunks),
                    'is_chunked': True
                }
                current_tokens = self.estimate_tokens(json.dumps({k: v for k, v in conv.items() if k != 'messages'}))

            current_chunk['messages'].append(msg)
            current_tokens += msg_tokens

        if current_chunk['messages']:
            if len(chunks) > 0:
                current_chunk['is_chunked'] = True
            chunks.append(current_chunk)

        return chunks if chunks else [conv]

    def close(self):
        """Close database connection"""
        self.conn.close()


def main():
    """Command-line interface"""
    import argparse

    # Default database path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_db = os.path.join(script_dir, "outputs", "conversations.duckdb")
    default_output = os.path.join(script_dir, "outputs", "queries")

    parser = argparse.ArgumentParser(description='AI Query Interface for Conversation Database')
    parser.add_argument('--db', default=default_db, help='Database path')
    parser.add_argument('--output-dir', default=default_output, help='Query output directory')

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Get conversation by ID
    get_parser = subparsers.add_parser('get', help='Get conversation by ID')
    get_parser.add_argument('id', help='Conversation ID (full or partial)')
    get_parser.add_argument('--no-messages', action='store_true', help='Exclude messages')
    get_parser.add_argument('--format', choices=['json', 'markdown', 'text'], default='json')
    get_parser.add_argument('--save', help='Save result with this query name')

    # Search conversations
    search_parser = subparsers.add_parser('search', help='Search conversations')
    search_parser.add_argument('query', nargs='?', help='Search query text')
    search_parser.add_argument('--source', choices=['claude', 'openai'], help='Filter by source')
    search_parser.add_argument('--start-date', help='Start date (YYYY-MM-DD)')
    search_parser.add_argument('--end-date', help='End date (YYYY-MM-DD)')
    search_parser.add_argument('--min-messages', type=int, help='Minimum message count')
    search_parser.add_argument('--max-messages', type=int, help='Maximum message count')
    search_parser.add_argument('--limit', type=int, default=50, help='Result limit')
    search_parser.add_argument('--messages', action='store_true', help='Include full messages')
    search_parser.add_argument('--format', choices=['json', 'markdown', 'text'], default='json')
    search_parser.add_argument('--save', help='Save result with this query name')

    # Get related conversations
    related_parser = subparsers.add_parser('related', help='Find related conversations')
    related_parser.add_argument('id', help='Conversation ID')
    related_parser.add_argument('--limit', type=int, default=10, help='Number of results')
    related_parser.add_argument('--format', choices=['json', 'markdown', 'text'], default='json')

    # Extract code
    code_parser = subparsers.add_parser('extract-code', help='Extract code blocks')
    code_parser.add_argument('--query', help='Filter conversations by query')
    code_parser.add_argument('--language', help='Filter by language (python, rust, etc.)')
    code_parser.add_argument('--format', choices=['json', 'markdown', 'text'], default='json')
    code_parser.add_argument('--save', help='Save result with this query name')

    # Query history
    history_parser = subparsers.add_parser('history', help='View query history')
    history_parser.add_argument('--query-name', help='Filter by query name')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    query = AIQuery(db_path=args.db, output_dir=args.output_dir)

    try:
        if args.command == 'get':
            result = query.get_conversation_by_id(args.id, include_messages=not args.no_messages)
            if not result:
                print(f"Conversation not found: {args.id}")
                return

            # Format output
            if args.format == 'json':
                output = json.dumps(result, indent=2)
            elif args.format == 'markdown':
                output = query.format_as_markdown([result], include_messages=not args.no_messages)
            else:
                output = query.format_as_text([result], include_messages=not args.no_messages)

            print(output)

            if args.save:
                path = query.save_query_result(result, args.save, {
                    'command': 'get',
                    'conversation_id': args.id
                })
                print(f"\n✅ Saved to: {path}")

        elif args.command == 'search':
            results = query.search_conversations(
                query=args.query,
                source=args.source,
                start_date=args.start_date,
                end_date=args.end_date,
                min_messages=args.min_messages,
                max_messages=args.max_messages,
                limit=args.limit,
                include_messages=args.messages
            )

            # Format output
            if args.format == 'json':
                output = json.dumps(results, indent=2)
            elif args.format == 'markdown':
                output = query.format_as_markdown(results, include_messages=args.messages)
            else:
                output = query.format_as_text(results, include_messages=args.messages)

            print(output)

            if args.save:
                path = query.save_query_result(results, args.save, {
                    'command': 'search',
                    'query': args.query,
                    'filters': {
                        'source': args.source,
                        'start_date': args.start_date,
                        'end_date': args.end_date,
                        'min_messages': args.min_messages,
                        'max_messages': args.max_messages
                    }
                })
                print(f"\n✅ Saved to: {path}")

        elif args.command == 'related':
            results = query.get_related_conversations(args.id, limit=args.limit)

            if args.format == 'json':
                output = json.dumps(results, indent=2)
            else:
                output = f"Related conversations for {args.id}:\n\n"
                for i, conv in enumerate(results, 1):
                    output += f"{i}. [{conv['source']}] {conv['title']}\n"
                    output += f"   ID: {conv['id']}\n"
                    output += f"   Created: {conv['created_at']}\n\n"

            print(output)

        elif args.command == 'extract-code':
            results = query.extract_code_blocks(query=args.query, language=args.language)

            if args.format == 'json':
                output = json.dumps(results, indent=2)
            elif args.format == 'markdown':
                output = f"# Code Blocks ({len(results)} found)\n\n"
                for i, block in enumerate(results, 1):
                    output += f"## {i}. From: {block['conversation_title']}\n"
                    output += f"**Language**: {block['language']}\n\n"
                    output += f"```{block['language']}\n{block['code']}\n```\n\n"
            else:
                output = f"Found {len(results)} code blocks\n\n"
                for i, block in enumerate(results, 1):
                    output += f"{i}. [{block['language']}] {block['conversation_title']}\n"
                    output += f"{block['code'][:200]}...\n\n"

            print(output)

            if args.save:
                path = query.save_query_result(results, args.save, {
                    'command': 'extract-code',
                    'query': args.query,
                    'language': args.language
                })
                print(f"\n✅ Saved to: {path}")

        elif args.command == 'history':
            history = query.get_query_history(query_name=args.query_name)
            print(f"\n📝 Query History ({len(history)} queries)\n")
            print("-" * 80)

            for entry in history:
                print(f"Query: {entry.get('query_name')}")
                print(f"Time: {entry.get('timestamp')}")
                print(f"Results: {entry.get('result_count')} items")
                print(f"File: {entry.get('result_file')}")
                print("-" * 80)

    finally:
        query.close()


if __name__ == "__main__":
    main()
