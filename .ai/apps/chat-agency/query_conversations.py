#!/usr/bin/env python3
"""
Query interface for indexed conversations
Provides search, filtering, and organization capabilities
"""

import duckdb
import sys
import re
from datetime import datetime, timedelta
from collections import Counter

class ConversationQuery:
    def __init__(self, db_path="conversations.duckdb"):
        self.conn = duckdb.connect(db_path, read_only=True)

    def search(self, query_text, limit=20):
        """Full-text search across all conversations"""
        print(f"\n🔍 Searching for: '{query_text}'")
        print("-" * 80)

        results = self.conn.execute("""
            SELECT
                c.id,
                c.source,
                c.title,
                c.created_at,
                c.message_count,
                LENGTH(fts.searchable_text) as content_length
            FROM conversations c
            JOIN conversation_fts fts ON c.id = fts.conversation_id
            WHERE fts.searchable_text ILIKE ?
            ORDER BY c.created_at DESC
            LIMIT ?
        """, (f'%{query_text}%', limit)).fetchall()

        if not results:
            print("No results found.")
            return

        for i, (conv_id, source, title, created, msg_count, content_len) in enumerate(results, 1):
            date_str = created.strftime('%Y-%m-%d %H:%M') if created else 'Unknown'
            print(f"{i:2d}. [{source:6s}] {title[:60]}")
            print(f"    Created: {date_str} | Messages: {msg_count} | ID: {conv_id[:16]}...")
            print()

        print(f"Found {len(results)} results")

    def search_by_date(self, start_date=None, end_date=None, source=None):
        """Search conversations by date range"""
        conditions = []
        params = []

        if start_date:
            conditions.append("created_at >= ?")
            params.append(start_date)
        if end_date:
            conditions.append("created_at <= ?")
            params.append(end_date)
        if source:
            conditions.append("source = ?")
            params.append(source)

        where_clause = " AND ".join(conditions) if conditions else "1=1"

        results = self.conn.execute(f"""
            SELECT source, title, created_at, message_count, id
            FROM conversations
            WHERE {where_clause}
            ORDER BY created_at DESC
        """, params).fetchall()

        print(f"\n📅 Conversations ({len(results)} found)")
        print("-" * 80)

        for source, title, created, msg_count, conv_id in results:
            date_str = created.strftime('%Y-%m-%d') if created else 'Unknown'
            print(f"[{source:6s}] {date_str} | {title[:55]} ({msg_count} msgs)")

    def get_topics_keywords(self, top_n=30):
        """Extract common keywords/topics from conversation titles"""
        print("\n🏷️  Common Topics (from conversation titles)")
        print("-" * 80)

        # Get all titles
        titles = self.conn.execute("""
            SELECT title FROM conversations WHERE title IS NOT NULL AND title != ''
        """).fetchall()

        # Simple keyword extraction
        words = []
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
                      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
                      'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
                      'would', 'should', 'could', 'may', 'might', 'can', 'it', 'this',
                      'that', 'these', 'those', 'i', 'you', 'he', 'she', 'we', 'they'}

        for (title,) in titles:
            # Extract words (keep hyphenated words together)
            title_words = re.findall(r'\b[\w-]+\b', title.lower())
            for word in title_words:
                if len(word) > 3 and word not in stop_words and not word.isdigit():
                    words.append(word)

        # Count frequencies
        counter = Counter(words)
        for word, count in counter.most_common(top_n):
            print(f"  {word:20s} {count:4d}")

    def categorize_by_topic(self, keyword_map):
        """
        Categorize conversations based on keyword mapping
        keyword_map: dict of {category: [keywords]}
        """
        print("\n📚 Categorizing conversations...")
        print("-" * 80)

        for category, keywords in keyword_map.items():
            # Build LIKE condition for each keyword
            conditions = " OR ".join(["fts.searchable_text ILIKE ?" for _ in keywords])
            params = [f'%{kw}%' for kw in keywords]

            results = self.conn.execute(f"""
                SELECT c.id, c.title, c.source
                FROM conversations c
                JOIN conversation_fts fts ON c.id = fts.conversation_id
                WHERE {conditions}
            """, params).fetchall()

            print(f"\n{category.upper()} ({len(results)} conversations)")
            for conv_id, title, source in results[:10]:  # Show first 10
                print(f"  [{source:6s}] {title[:60]}")
            if len(results) > 10:
                print(f"  ... and {len(results) - 10} more")

    def timeline_analysis(self):
        """Show conversation activity over time"""
        print("\n📈 Timeline Analysis")
        print("-" * 80)

        # Monthly activity
        results = self.conn.execute("""
            SELECT
                strftime(created_at, '%Y-%m') as month,
                source,
                COUNT(*) as count
            FROM conversations
            WHERE created_at IS NOT NULL
            GROUP BY month, source
            ORDER BY month DESC, source
        """).fetchall()

        current_month = None
        for month, source, count in results:
            if month != current_month:
                if current_month is not None:
                    print()
                print(f"{month}:")
                current_month = month
            print(f"  {source:8s}: {'█' * min(count, 50)} {count}")

    def get_conversation_details(self, conv_id):
        """Get full details of a conversation"""
        conv = self.conn.execute("""
            SELECT id, source, title, created_at, updated_at, message_count, summary
            FROM conversations
            WHERE id LIKE ?
        """, (f'%{conv_id}%',)).fetchone()

        if not conv:
            print(f"Conversation not found: {conv_id}")
            return

        conv_id, source, title, created, updated, msg_count, summary = conv

        print(f"\n{'='*80}")
        print(f"CONVERSATION: {title}")
        print(f"{'='*80}")
        print(f"ID: {conv_id}")
        print(f"Source: {source}")
        print(f"Created: {created}")
        print(f"Updated: {updated}")
        print(f"Messages: {msg_count}")
        if summary:
            print(f"Summary: {summary}")
        print(f"\n{'Messages:':-^80}")

        messages = self.conn.execute("""
            SELECT sender, text, created_at
            FROM messages
            WHERE conversation_id = ?
            ORDER BY created_at
        """, (conv_id,)).fetchall()

        for sender, text, created in messages:
            timestamp = created.strftime('%Y-%m-%d %H:%M') if created else ''
            print(f"\n[{sender.upper()}] {timestamp}")
            # Truncate long messages
            if len(text) > 500:
                print(f"{text[:500]}... [truncated]")
            else:
                print(text)

    def export_to_csv(self, output_file, query=None):
        """Export conversations to CSV"""
        where_clause = "WHERE fts.searchable_text ILIKE ?" if query else "WHERE 1=1"
        params = [f'%{query}%'] if query else []

        self.conn.execute(f"""
            COPY (
                SELECT
                    c.id,
                    c.source,
                    c.title,
                    c.created_at,
                    c.message_count,
                    c.summary
                FROM conversations c
                LEFT JOIN conversation_fts fts ON c.id = fts.conversation_id
                {where_clause}
                ORDER BY c.created_at DESC
            ) TO '{output_file}' (HEADER, DELIMITER ',')
        """, params)

        print(f"✅ Exported to {output_file}")

    def close(self):
        self.conn.close()


def main():
    """Interactive query interface"""
    import os

    # Default database path (relative to script location)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_db = os.path.join(script_dir, "outputs", "conversations.duckdb")

    if len(sys.argv) < 2:
        print("""
Usage:
  python query_conversations.py search <query>
  python query_conversations.py topics
  python query_conversations.py timeline
  python query_conversations.py details <conversation_id>
  python query_conversations.py export <output.csv> [query]

Examples:
  python query_conversations.py search "python script"
  python query_conversations.py search "database"
  python query_conversations.py topics
  python query_conversations.py timeline
  python query_conversations.py details ac8fd9f6
  python query_conversations.py export all_conversations.csv
  python query_conversations.py export python_convs.csv "python"
        """)
        return

    cmd = sys.argv[1]
    query = ConversationQuery(default_db)

    try:
        if cmd == 'search' and len(sys.argv) > 2:
            query.search(' '.join(sys.argv[2:]))

        elif cmd == 'topics':
            query.get_topics_keywords()

        elif cmd == 'timeline':
            query.timeline_analysis()

        elif cmd == 'details' and len(sys.argv) > 2:
            query.get_conversation_details(sys.argv[2])

        elif cmd == 'export' and len(sys.argv) > 2:
            output_file = sys.argv[2]
            search_query = ' '.join(sys.argv[3:]) if len(sys.argv) > 3 else None
            query.export_to_csv(output_file, search_query)

        elif cmd == 'categorize':
            # Example categorization
            keyword_map = {
                'programming': ['python', 'javascript', 'code', 'script', 'function', 'api'],
                'data': ['database', 'sql', 'duckdb', 'data', 'query'],
                'web': ['html', 'css', 'react', 'vue', 'web', 'frontend'],
                'devops': ['docker', 'kubernetes', 'deploy', 'server', 'cloud'],
            }
            query.categorize_by_topic(keyword_map)

        else:
            print("Unknown command. Use: search, topics, timeline, details, export, categorize")

    finally:
        query.close()


if __name__ == "__main__":
    main()
