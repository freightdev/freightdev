#!/usr/bin/env python3
"""
Conversation Analytics
Advanced analysis of conversation patterns, topics, and trends
"""

import duckdb
import json
import os
import sys
from pathlib import Path
from datetime import datetime, timedelta
from collections import Counter, defaultdict
import re

class ConversationAnalytics:
    def __init__(self, db_path="conversations.duckdb"):
        self.db_path = db_path
        self.conn = duckdb.connect(db_path, read_only=True)

    def conversation_stats(self) -> dict:
        """Get comprehensive conversation statistics"""
        stats = {}

        # Overall stats
        total = self.conn.execute("SELECT COUNT(*) FROM conversations").fetchone()[0]
        total_messages = self.conn.execute("SELECT COUNT(*) FROM messages").fetchone()[0]

        stats['total_conversations'] = total
        stats['total_messages'] = total_messages
        stats['avg_messages_per_conversation'] = total_messages / total if total > 0 else 0

        # By source
        by_source = self.conn.execute("""
            SELECT source, COUNT(*) as count, SUM(message_count) as messages
            FROM conversations
            GROUP BY source
        """).fetchall()

        stats['by_source'] = {source: {'conversations': count, 'messages': msgs}
                              for source, count, msgs in by_source}

        # Date ranges
        date_range = self.conn.execute("""
            SELECT MIN(created_at) as earliest, MAX(created_at) as latest
            FROM conversations
            WHERE created_at IS NOT NULL
        """).fetchone()

        if date_range[0]:
            stats['earliest_conversation'] = date_range[0].isoformat()
            stats['latest_conversation'] = date_range[1].isoformat()
            days_span = (date_range[1] - date_range[0]).days
            stats['days_span'] = days_span
            stats['conversations_per_day'] = total / days_span if days_span > 0 else 0

        # Message length distribution
        msg_lengths = self.conn.execute("""
            SELECT AVG(LENGTH(text)) as avg_length,
                   MIN(LENGTH(text)) as min_length,
                   MAX(LENGTH(text)) as max_length
            FROM messages
            WHERE text IS NOT NULL
        """).fetchone()

        stats['message_lengths'] = {
            'avg': msg_lengths[0],
            'min': msg_lengths[1],
            'max': msg_lengths[2]
        }

        # Conversation length distribution
        conv_length_dist = self.conn.execute("""
            SELECT
                CASE
                    WHEN message_count <= 5 THEN '1-5'
                    WHEN message_count <= 10 THEN '6-10'
                    WHEN message_count <= 20 THEN '11-20'
                    WHEN message_count <= 50 THEN '21-50'
                    ELSE '50+'
                END as range,
                COUNT(*) as count
            FROM conversations
            GROUP BY range
            ORDER BY range
        """).fetchall()

        stats['conversation_length_distribution'] = {r: c for r, c in conv_length_dist}

        return stats

    def activity_timeline(self, granularity='month'):
        """Analyze conversation activity over time"""
        if granularity == 'day':
            format_str = '%Y-%m-%d'
        elif granularity == 'week':
            format_str = '%Y-W%W'
        else:  # month
            format_str = '%Y-%m'

        timeline = self.conn.execute(f"""
            SELECT
                strftime(created_at, '{format_str}') as period,
                source,
                COUNT(*) as conversation_count,
                SUM(message_count) as message_count
            FROM conversations
            WHERE created_at IS NOT NULL
            GROUP BY period, source
            ORDER BY period DESC
        """).fetchall()

        # Organize by period
        result = defaultdict(lambda: {'claude': 0, 'openai': 0, 'total': 0})

        for period, source, conv_count, msg_count in timeline:
            result[period][source] = {'conversations': conv_count, 'messages': msg_count}
            result[period]['total'] += conv_count

        return dict(result)

    def topic_extraction(self, top_n=50, min_word_length=4):
        """Extract common topics from conversation titles"""
        titles = self.conn.execute("""
            SELECT title FROM conversations
            WHERE title IS NOT NULL AND title != ''
        """).fetchall()

        # Stop words
        stop_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
            'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
            'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
            'would', 'should', 'could', 'may', 'might', 'can', 'it', 'this',
            'that', 'these', 'those', 'i', 'you', 'he', 'she', 'we', 'they',
            'my', 'your', 'how', 'what', 'when', 'where', 'why', 'which', 'who',
            'help', 'me', 'please', 'need', 'want', 'make', 'using', 'use', 'get'
        }

        words = []
        for (title,) in titles:
            # Extract words (keep hyphenated and underscored words)
            title_words = re.findall(r'\b[\w\-_]+\b', title.lower())
            for word in title_words:
                if (len(word) >= min_word_length and
                    word not in stop_words and
                    not word.isdigit()):
                    words.append(word)

        counter = Counter(words)
        return counter.most_common(top_n)

    def topic_cooccurrence(self, keywords: list, min_cooccurrence=2):
        """Find which keywords co-occur in conversations"""
        cooccurrence = defaultdict(lambda: defaultdict(int))

        for kw1 in keywords:
            for kw2 in keywords:
                if kw1 >= kw2:  # Avoid duplicates
                    continue

                # Count conversations containing both keywords
                count = self.conn.execute("""
                    SELECT COUNT(DISTINCT c.id)
                    FROM conversations c
                    JOIN conversation_fts fts ON c.id = fts.conversation_id
                    WHERE fts.searchable_text ILIKE ?
                      AND fts.searchable_text ILIKE ?
                """, (f'%{kw1}%', f'%{kw2}%')).fetchone()[0]

                if count >= min_cooccurrence:
                    cooccurrence[kw1][kw2] = count

        return dict(cooccurrence)

    def conversation_patterns(self):
        """Analyze common conversation patterns"""
        patterns = {}

        # Questions vs answers ratio
        questions = self.conn.execute("""
            SELECT COUNT(*) FROM messages
            WHERE text LIKE '%?%' AND sender = 'human'
        """).fetchone()[0]

        total_human = self.conn.execute("""
            SELECT COUNT(*) FROM messages WHERE sender = 'human'
        """).fetchone()[0]

        patterns['question_ratio'] = questions / total_human if total_human > 0 else 0

        # Average conversation duration (time between first and last message)
        durations = self.conn.execute("""
            SELECT c.id,
                   MIN(m.created_at) as start_time,
                   MAX(m.created_at) as end_time
            FROM conversations c
            JOIN messages m ON c.id = m.conversation_id
            WHERE m.created_at IS NOT NULL
            GROUP BY c.id
            HAVING COUNT(m.id) > 1
        """).fetchall()

        total_duration = 0
        duration_dist = {'< 1 min': 0, '1-5 min': 0, '5-30 min': 0, '30+ min': 0}

        for conv_id, start, end in durations:
            duration_minutes = (end - start).total_seconds() / 60
            total_duration += duration_minutes

            if duration_minutes < 1:
                duration_dist['< 1 min'] += 1
            elif duration_minutes < 5:
                duration_dist['1-5 min'] += 1
            elif duration_minutes < 30:
                duration_dist['5-30 min'] += 1
            else:
                duration_dist['30+ min'] += 1

        patterns['avg_duration_minutes'] = total_duration / len(durations) if durations else 0
        patterns['duration_distribution'] = duration_dist

        # Code frequency
        code_messages = self.conn.execute("""
            SELECT COUNT(*) FROM messages WHERE text LIKE '%```%'
        """).fetchone()[0]

        patterns['messages_with_code'] = code_messages
        patterns['code_percentage'] = (code_messages / total_messages * 100
                                      if total_messages > 0 else 0)

        return patterns

    def find_similar_conversations(self, conv_id: str, limit=10):
        """Find conversations similar to a given one based on content"""
        # Get the original conversation's text
        original = self.conn.execute("""
            SELECT searchable_text FROM conversation_fts WHERE conversation_id = ?
        """, (conv_id,)).fetchone()

        if not original:
            return []

        # Extract keywords from original
        words = re.findall(r'\b\w+\b', original[0].lower())
        counter = Counter(words)

        # Get top keywords
        top_keywords = [word for word, count in counter.most_common(20)
                       if len(word) > 4]

        if not top_keywords:
            return []

        # Build search pattern
        pattern = '|'.join(top_keywords[:10])

        # Find similar conversations
        similar = self.conn.execute("""
            SELECT c.id, c.title, c.created_at, COUNT(*) as match_score
            FROM conversations c
            JOIN conversation_fts fts ON c.id = fts.conversation_id
            WHERE c.id != ?
              AND fts.searchable_text ~* ?
            GROUP BY c.id, c.title, c.created_at
            ORDER BY match_score DESC
            LIMIT ?
        """, (conv_id, pattern, limit)).fetchall()

        return [{'id': cid, 'title': title, 'created_at': created.isoformat() if created else None,
                 'similarity_score': score} for cid, title, created, score in similar]

    def code_language_stats(self):
        """Analyze programming languages used in code blocks"""
        messages_with_code = self.conn.execute("""
            SELECT text FROM messages WHERE text LIKE '%```%'
        """).fetchall()

        languages = Counter()
        code_pattern = r'```(\w+)?'

        for (text,) in messages_with_code:
            matches = re.findall(code_pattern, text)
            for lang in matches:
                if lang:
                    languages[lang.lower()] += 1
                else:
                    languages['unknown'] += 1

        return dict(languages.most_common(20))

    def export_analytics_report(self, output_file: str):
        """Generate a comprehensive analytics report"""
        report = {
            'generated_at': datetime.now().isoformat(),
            'stats': self.conversation_stats(),
            'timeline': self.activity_timeline('month'),
            'top_topics': dict(self.topic_extraction(50)),
            'patterns': self.conversation_patterns(),
            'programming_languages': self.code_language_stats()
        }

        # Save as JSON
        json_file = output_file if output_file.endswith('.json') else f"{output_file}.json"
        with open(json_file, 'w') as f:
            json.dump(report, f, indent=2, default=str)

        # Also create markdown version
        md_file = json_file.replace('.json', '.md')
        self._create_markdown_report(report, md_file)

        print(f"✅ Analytics report saved:")
        print(f"   JSON: {json_file}")
        print(f"   Markdown: {md_file}")

    def _create_markdown_report(self, report: dict, output_file: str):
        """Create markdown version of analytics report"""
        with open(output_file, 'w') as f:
            f.write("# Conversation Analytics Report\n\n")
            f.write(f"Generated: {report['generated_at']}\n\n")

            # Overall stats
            stats = report['stats']
            f.write("## Overview\n\n")
            f.write(f"- **Total Conversations**: {stats['total_conversations']:,}\n")
            f.write(f"- **Total Messages**: {stats['total_messages']:,}\n")
            f.write(f"- **Average Messages per Conversation**: {stats['avg_messages_per_conversation']:.1f}\n")

            if 'earliest_conversation' in stats:
                f.write(f"- **Date Range**: {stats['earliest_conversation']} to {stats['latest_conversation']}\n")
                f.write(f"- **Days Span**: {stats['days_span']} days\n")
                f.write(f"- **Conversations per Day**: {stats['conversations_per_day']:.2f}\n")

            # By source
            f.write("\n### By Source\n\n")
            for source, data in stats['by_source'].items():
                f.write(f"- **{source.upper()}**: {data['conversations']:,} conversations, {data['messages']:,} messages\n")

            # Conversation length distribution
            f.write("\n### Conversation Length Distribution\n\n")
            for range_label, count in stats['conversation_length_distribution'].items():
                f.write(f"- **{range_label} messages**: {count} conversations\n")

            # Top topics
            f.write("\n## Top Topics\n\n")
            topics = report['top_topics']
            for i, (topic, count) in enumerate(list(topics.items())[:30], 1):
                f.write(f"{i}. **{topic}**: {count} mentions\n")

            # Programming languages
            if report.get('programming_languages'):
                f.write("\n## Programming Languages\n\n")
                for lang, count in report['programming_languages'].items():
                    f.write(f"- **{lang}**: {count} code blocks\n")

            # Patterns
            patterns = report['patterns']
            f.write("\n## Conversation Patterns\n\n")
            f.write(f"- **Question Ratio**: {patterns['question_ratio']:.1%}\n")
            f.write(f"- **Average Duration**: {patterns['avg_duration_minutes']:.1f} minutes\n")
            f.write(f"- **Messages with Code**: {patterns['messages_with_code']} ({patterns['code_percentage']:.1f}%)\n")

            f.write("\n### Duration Distribution\n\n")
            for duration, count in patterns['duration_distribution'].items():
                f.write(f"- **{duration}**: {count} conversations\n")

            # Timeline
            f.write("\n## Activity Timeline (by Month)\n\n")
            timeline = report['timeline']
            for period in sorted(timeline.keys(), reverse=True)[:12]:
                data = timeline[period]
                f.write(f"\n### {period}\n")
                f.write(f"- Total: {data['total']} conversations\n")
                if 'claude' in data:
                    claude = data['claude']
                    f.write(f"- Claude: {claude['conversations']} conversations, {claude['messages']} messages\n")
                if 'openai' in data:
                    openai = data['openai']
                    f.write(f"- OpenAI: {openai['conversations']} conversations, {openai['messages']} messages\n")

    def close(self):
        """Close database connection"""
        self.conn.close()


def main():
    """Command-line interface"""
    import argparse

    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_db = os.path.join(script_dir, "outputs", "conversations.duckdb")

    parser = argparse.ArgumentParser(description='Conversation Analytics')
    parser.add_argument('--db', default=default_db, help='Database path')

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Stats
    stats_parser = subparsers.add_parser('stats', help='Show conversation statistics')

    # Timeline
    timeline_parser = subparsers.add_parser('timeline', help='Show activity timeline')
    timeline_parser.add_argument('--granularity', choices=['day', 'week', 'month'],
                                default='month', help='Time granularity')

    # Topics
    topics_parser = subparsers.add_parser('topics', help='Extract common topics')
    topics_parser.add_argument('--limit', type=int, default=50, help='Number of topics')

    # Patterns
    patterns_parser = subparsers.add_parser('patterns', help='Analyze conversation patterns')

    # Languages
    lang_parser = subparsers.add_parser('languages', help='Programming language statistics')

    # Similar
    similar_parser = subparsers.add_parser('similar', help='Find similar conversations')
    similar_parser.add_argument('conversation_id', help='Conversation ID')
    similar_parser.add_argument('--limit', type=int, default=10, help='Number of results')

    # Report
    report_parser = subparsers.add_parser('report', help='Generate full analytics report')
    report_parser.add_argument('--output', default='analytics_report', help='Output file (without extension)')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    analytics = ConversationAnalytics(db_path=args.db)

    try:
        if args.command == 'stats':
            stats = analytics.conversation_stats()
            print(json.dumps(stats, indent=2, default=str))

        elif args.command == 'timeline':
            timeline = analytics.activity_timeline(args.granularity)
            for period, data in sorted(timeline.items(), reverse=True):
                print(f"\n{period}:")
                print(f"  Total: {data['total']}")
                if 'claude' in data:
                    print(f"  Claude: {data['claude']}")
                if 'openai' in data:
                    print(f"  OpenAI: {data['openai']}")

        elif args.command == 'topics':
            topics = analytics.topic_extraction(args.limit)
            print("\nTop Topics:")
            print("-" * 60)
            for i, (topic, count) in enumerate(topics, 1):
                print(f"{i:3d}. {topic:30s} {count:5d}")

        elif args.command == 'patterns':
            patterns = analytics.conversation_patterns()
            print(json.dumps(patterns, indent=2, default=str))

        elif args.command == 'languages':
            languages = analytics.code_language_stats()
            print("\nProgramming Languages:")
            print("-" * 60)
            for lang, count in languages.items():
                print(f"{lang:20s} {count:5d} code blocks")

        elif args.command == 'similar':
            similar = analytics.find_similar_conversations(args.conversation_id, args.limit)
            print(f"\nConversations similar to {args.conversation_id}:")
            print("-" * 80)
            for conv in similar:
                print(f"[Score: {conv['similarity_score']}] {conv['title']}")
                print(f"  ID: {conv['id']} | Created: {conv['created_at']}\n")

        elif args.command == 'report':
            analytics.export_analytics_report(args.output)

    finally:
        analytics.close()


if __name__ == "__main__":
    main()
