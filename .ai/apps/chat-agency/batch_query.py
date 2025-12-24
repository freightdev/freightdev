#!/usr/bin/env python3
"""
Batch Query Processor
Process multiple queries at once and organize results by project
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime
from ai_query import AIQuery
import re

class BatchQueryProcessor:
    def __init__(self, db_path="conversations.duckdb", output_dir="outputs/queries"):
        self.query = AIQuery(db_path=db_path, output_dir=output_dir)
        self.batch_dir = Path(output_dir) / "batch_results"
        self.batch_dir.mkdir(parents=True, exist_ok=True)

    def process_batch_file(self, batch_file: str):
        """
        Process a batch query file (JSON or YAML format)

        Format:
        {
            "project_name": "fed_trucking",
            "queries": [
                {
                    "name": "flutter_knowledge",
                    "search": "flutter",
                    "include_messages": true,
                    "filters": {
                        "source": "claude",
                        "min_messages": 5
                    }
                },
                ...
            ]
        }
        """
        with open(batch_file, 'r') as f:
            if batch_file.endswith('.json'):
                batch_config = json.load(f)
            else:
                print("Only JSON batch files supported for now")
                return

        project_name = batch_config.get('project_name', 'unnamed_project')
        queries = batch_config.get('queries', [])

        print(f"\n{'='*80}")
        print(f"BATCH PROCESSING: {project_name}")
        print(f"Total queries: {len(queries)}")
        print(f"{'='*80}\n")

        results = []
        for i, query_config in enumerate(queries, 1):
            print(f"\n[{i}/{len(queries)}] Processing: {query_config.get('name', 'unnamed')}")
            result = self._process_single_query(project_name, query_config)
            results.append(result)

        # Save batch summary
        self._save_batch_summary(project_name, results)

        print(f"\n{'='*80}")
        print(f"✅ Batch processing complete!")
        print(f"Results saved to: {self.batch_dir / project_name}")
        print(f"{'='*80}\n")

    def _process_single_query(self, project_name: str, config: dict) -> dict:
        """Process a single query from batch config"""
        query_name = config.get('name', 'unnamed')
        search_text = config.get('search')
        filters = config.get('filters', {})
        include_messages = config.get('include_messages', False)
        extract_code = config.get('extract_code', False)
        code_language = config.get('code_language')

        result_summary = {
            'query_name': query_name,
            'search': search_text,
            'status': 'pending'
        }

        try:
            if extract_code:
                # Extract code blocks
                results = self.query.extract_code_blocks(
                    query=search_text,
                    language=code_language
                )
                result_type = 'code_blocks'
            else:
                # Search conversations
                results = self.query.search_conversations(
                    query=search_text,
                    source=filters.get('source'),
                    start_date=filters.get('start_date'),
                    end_date=filters.get('end_date'),
                    min_messages=filters.get('min_messages'),
                    max_messages=filters.get('max_messages'),
                    limit=filters.get('limit', 50),
                    include_messages=include_messages
                )
                result_type = 'conversations'

            # Save to project-specific directory
            project_dir = self.batch_dir / project_name / query_name
            project_dir.mkdir(parents=True, exist_ok=True)

            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            result_file = project_dir / f"{timestamp}_result.json"

            with open(result_file, 'w') as f:
                json.dump(results, f, indent=2, default=str)

            # Save metadata
            metadata = {
                'project_name': project_name,
                'query_name': query_name,
                'search': search_text,
                'filters': filters,
                'timestamp': timestamp,
                'result_type': result_type,
                'result_count': len(results),
                'result_file': str(result_file)
            }

            meta_file = project_dir / f"{timestamp}_metadata.json"
            with open(meta_file, 'w') as f:
                json.dump(metadata, f, indent=2, default=str)

            result_summary.update({
                'status': 'success',
                'result_count': len(results),
                'result_file': str(result_file)
            })

            print(f"  ✓ Found {len(results)} results")

        except Exception as e:
            result_summary.update({
                'status': 'error',
                'error': str(e)
            })
            print(f"  ✗ Error: {e}")

        return result_summary

    def _save_batch_summary(self, project_name: str, results: list):
        """Save summary of batch processing"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        summary_file = self.batch_dir / project_name / f"{timestamp}_batch_summary.json"

        summary = {
            'project_name': project_name,
            'timestamp': timestamp,
            'total_queries': len(results),
            'successful': sum(1 for r in results if r['status'] == 'success'),
            'failed': sum(1 for r in results if r['status'] == 'error'),
            'results': results
        }

        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2, default=str)

        # Also create a markdown summary
        md_file = self.batch_dir / project_name / f"{timestamp}_batch_summary.md"
        with open(md_file, 'w') as f:
            f.write(f"# Batch Query Summary: {project_name}\n\n")
            f.write(f"**Timestamp**: {timestamp}\n\n")
            f.write(f"**Total Queries**: {len(results)}\n")
            f.write(f"**Successful**: {summary['successful']}\n")
            f.write(f"**Failed**: {summary['failed']}\n\n")
            f.write("## Results\n\n")

            for result in results:
                status_icon = "✅" if result['status'] == 'success' else "❌"
                f.write(f"### {status_icon} {result['query_name']}\n\n")
                f.write(f"- **Search**: {result.get('search', 'N/A')}\n")
                f.write(f"- **Status**: {result['status']}\n")

                if result['status'] == 'success':
                    f.write(f"- **Results**: {result['result_count']}\n")
                    f.write(f"- **File**: `{result['result_file']}`\n")
                else:
                    f.write(f"- **Error**: {result.get('error', 'Unknown')}\n")

                f.write("\n")

    def create_project_index(self, project_name: str):
        """Create an index of all queries for a project"""
        project_dir = self.batch_dir / project_name

        if not project_dir.exists():
            print(f"Project not found: {project_name}")
            return

        index = {
            'project_name': project_name,
            'queries': {}
        }

        # Scan all query subdirectories
        for query_dir in project_dir.iterdir():
            if not query_dir.is_dir():
                continue

            query_name = query_dir.name
            query_results = []

            # Find all result files
            for result_file in sorted(query_dir.glob('*_result.json')):
                timestamp = result_file.stem.replace('_result', '')
                meta_file = query_dir / f"{timestamp}_metadata.json"

                meta = {}
                if meta_file.exists():
                    with open(meta_file, 'r') as f:
                        meta = json.load(f)

                query_results.append({
                    'timestamp': timestamp,
                    'result_file': str(result_file),
                    'result_count': meta.get('result_count', 0),
                    'search': meta.get('search')
                })

            index['queries'][query_name] = query_results

        # Save index
        index_file = project_dir / "project_index.json"
        with open(index_file, 'w') as f:
            json.dump(index, f, indent=2)

        print(f"✅ Created project index: {index_file}")
        return index

    def merge_query_results(self, project_name: str, query_names: list, output_name: str):
        """Merge multiple query results into one file"""
        project_dir = self.batch_dir / project_name
        merged_results = []

        for query_name in query_names:
            query_dir = project_dir / query_name
            if not query_dir.exists():
                print(f"⚠️  Query not found: {query_name}")
                continue

            # Get latest result
            result_files = sorted(query_dir.glob('*_result.json'), reverse=True)
            if result_files:
                with open(result_files[0], 'r') as f:
                    results = json.load(f)
                    merged_results.extend(results)
                print(f"  ✓ Merged {len(results)} results from {query_name}")

        # Save merged results
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        merged_file = project_dir / f"{output_name}_{timestamp}_merged.json"

        with open(merged_file, 'w') as f:
            json.dump(merged_results, f, indent=2, default=str)

        print(f"\n✅ Merged {len(merged_results)} total results to: {merged_file}")
        return merged_results

    def close(self):
        """Close database connection"""
        self.query.close()


def main():
    """Command-line interface"""
    import argparse

    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_db = os.path.join(script_dir, "outputs", "conversations.duckdb")
    default_output = os.path.join(script_dir, "outputs", "queries")

    parser = argparse.ArgumentParser(description='Batch Query Processor')
    parser.add_argument('--db', default=default_db, help='Database path')
    parser.add_argument('--output-dir', default=default_output, help='Query output directory')

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Process batch file
    process_parser = subparsers.add_parser('process', help='Process batch query file')
    process_parser.add_argument('batch_file', help='Path to batch query JSON file')

    # Create project index
    index_parser = subparsers.add_parser('index', help='Create project index')
    index_parser.add_argument('project_name', help='Project name')

    # Merge results
    merge_parser = subparsers.add_parser('merge', help='Merge query results')
    merge_parser.add_argument('project_name', help='Project name')
    merge_parser.add_argument('queries', nargs='+', help='Query names to merge')
    merge_parser.add_argument('--output', default='merged', help='Output name')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    processor = BatchQueryProcessor(db_path=args.db, output_dir=args.output_dir)

    try:
        if args.command == 'process':
            processor.process_batch_file(args.batch_file)

        elif args.command == 'index':
            processor.create_project_index(args.project_name)

        elif args.command == 'merge':
            processor.merge_query_results(args.project_name, args.queries, args.output)

    finally:
        processor.close()


if __name__ == "__main__":
    main()
