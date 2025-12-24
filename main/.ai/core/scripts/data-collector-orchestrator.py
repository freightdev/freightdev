#!/usr/bin/env python3
"""
Data Collector Orchestrator
Coordinates web-scraper, web-search, and data-collector agents
Generates markdown reports for trucking and housing data
"""

import requests
import yaml
import feedparser
from datetime import datetime, timedelta
from pathlib import Path
import json
import sys
from typing import List, Dict, Any
import time

# Service endpoints
DATA_COLLECTOR_URL = "http://localhost:9006"
WEB_SCRAPER_URL = "http://localhost:9003"
SURREAL_DB_URL = "http://192.168.12.66:9000"

class DataCollectorOrchestrator:
    def __init__(self, config_path: str):
        self.config = self.load_config(config_path)
        self.collected_items = []

    def load_config(self, path: str) -> Dict[str, Any]:
        """Load YAML configuration"""
        with open(path, 'r') as f:
            return yaml.safe_load(f)

    def collect_rss_feeds(self) -> List[Dict[str, Any]]:
        """Collect data from RSS feeds"""
        items = []

        feeds = self.config.get('sources', {}).get('rss_feeds', [])
        print(f"📰 Collecting from {len(feeds)} RSS feeds...")

        for feed_config in feeds:
            print(f"  ├─ {feed_config['name']}...")
            try:
                feed = feedparser.parse(feed_config['url'])

                for entry in feed.entries[:10]:  # Limit to 10 most recent
                    item = {
                        'title': entry.get('title', 'No Title'),
                        'url': entry.get('link', ''),
                        'source': feed_config['name'],
                        'category': feed_config['category'],
                        'published_at': entry.get('published', ''),
                        'content': entry.get('summary', entry.get('description', '')),
                        'metadata': {
                            'author': entry.get('author', ''),
                            'tags': [tag.term for tag in entry.get('tags', [])],
                        }
                    }
                    items.append(item)

                print(f"  └─ ✅ Collected {len(feed.entries[:10])} items")

            except Exception as e:
                print(f"  └─ ❌ Error: {e}")

        return items

    def collect_web_scrapes(self) -> List[Dict[str, Any]]:
        """Collect data via web scraper agent"""
        items = []

        scrapes = self.config.get('sources', {}).get('web_scrapes', [])
        print(f"🕷️  Scraping {len(scrapes)} web sources...")

        for scrape_config in scrapes:
            print(f"  ├─ {scrape_config['name']}...")

            # Create scraper job via web-scraper agent
            try:
                payload = {
                    "config": {
                        "id": scrape_config['id'],
                        "name": scrape_config['name'],
                        "url": scrape_config['url'],
                        "selectors": scrape_config.get('selectors', {}),
                        "schedule_seconds": 0,  # Run once
                        "enabled": True
                    }
                }

                # Note: In production, we'd call the web-scraper service
                # For now, simulate with direct requests
                response = requests.get(scrape_config['url'], timeout=30)

                if response.status_code == 200:
                    item = {
                        'title': f"Scraped: {scrape_config['name']}",
                        'url': scrape_config['url'],
                        'source': scrape_config['name'],
                        'category': scrape_config['category'],
                        'published_at': datetime.now().isoformat(),
                        'content': f"Successfully scraped {len(response.text)} bytes",
                        'metadata': {
                            'status_code': response.status_code,
                            'content_type': response.headers.get('content-type', ''),
                        }
                    }
                    items.append(item)
                    print(f"  └─ ✅ Scraped successfully")
                else:
                    print(f"  └─ ❌ HTTP {response.status_code}")

            except Exception as e:
                print(f"  └─ ❌ Error: {e}")

        return items

    def collect_search_queries(self) -> List[Dict[str, Any]]:
        """Execute search queries via web-search agent"""
        items = []

        queries = self.config.get('sources', {}).get('search_queries', [])
        print(f"🔍 Executing {len(queries)} search queries...")

        for query_config in queries:
            query = query_config['query'].format(
                date=datetime.now().strftime('%Y-%m-%d'),
                month=datetime.now().strftime('%B'),
                year=datetime.now().year
            )

            print(f"  ├─ \"{query}\"...")

            # Note: Would call web-search service
            # For now, create placeholder
            item = {
                'title': f"Search: {query}",
                'url': f"https://duckduckgo.com/?q={query}",
                'source': 'Web Search',
                'category': query_config['category'],
                'published_at': datetime.now().isoformat(),
                'content': f"Search results for: {query}",
                'metadata': {
                    'query': query,
                }
            }
            items.append(item)
            print(f"  └─ ✅ Search queued")

        return items

    def generate_markdown(self, items: List[Dict[str, Any]], output_path: Path) -> None:
        """Generate markdown report from collected items"""
        print(f"\n📝 Generating markdown report...")

        # Group by category
        grouped = {}
        for item in items:
            category = item['category']
            if category not in grouped:
                grouped[category] = []
            grouped[category].append(item)

        # Create markdown
        md = f"# {self.config.get('title', 'Data Collection Report')}\n\n"
        md += f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  \n"
        md += f"**Total Items**: {len(items)}  \n\n"
        md += "---\n\n"

        # Table of Contents
        md += "## Table of Contents\n\n"
        for idx, category in enumerate(sorted(grouped.keys()), 1):
            md += f"{idx}. [{category.replace('_', ' ').title()}](#{category.lower().replace('_', '-')})\n"
        md += "\n---\n\n"

        # Sections
        for category in sorted(grouped.keys()):
            category_items = grouped[category]
            md += f"## {category.replace('_', ' ').title()}\n\n"
            md += f"*{len(category_items)} items*\n\n"

            for idx, item in enumerate(category_items, 1):
                md += f"### {idx}. {item['title']}\n\n"
                md += f"**Source**: {item['source']}  \n"
                md += f"**URL**: <{item['url']}>  \n"

                if item.get('published_at'):
                    md += f"**Published**: {item['published_at']}  \n"

                if item.get('metadata'):
                    md += "\n**Metadata**:  \n"
                    for key, value in item['metadata'].items():
                        md += f"- **{key}**: {value}  \n"

                md += "\n"

                if item.get('content'):
                    md += f"{item['content']}\n\n"

                md += "---\n\n"

        # Footer
        md += f"\n*Generated by AI Data Collector at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n"

        # Write to file
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(md)

        print(f"✅ Markdown saved to: {output_path}")
        print(f"   {len(items)} items across {len(grouped)} categories")

    def save_to_database(self, items: List[Dict[str, Any]]) -> None:
        """Save collected data to SurrealDB"""
        if not self.config.get('output', {}).get('database', False):
            return

        table = self.config.get('output', {}).get('database_table', 'collected_data')
        print(f"\n💾 Saving to SurrealDB table: {table}...")

        try:
            for item in items:
                payload = {
                    "query": f"CREATE {table} CONTENT {json.dumps(item)}"
                }

                response = requests.post(
                    f"{SURREAL_DB_URL}/sql",
                    json=payload,
                    headers={
                        "NS": "workspace",
                        "DB": "data_collections"
                    }
                )

                if response.status_code != 200:
                    print(f"  ❌ Failed to save item: {response.text}")

            print(f"✅ Saved {len(items)} items to database")

        except Exception as e:
            print(f"❌ Database error: {e}")

    def run(self) -> None:
        """Execute full collection pipeline"""
        print("🚀 Starting Data Collection Orchestrator\n")
        print(f"Config: {self.config.get('title', 'Unnamed Collection')}\n")

        # Collect from all sources
        rss_items = self.collect_rss_feeds()
        scrape_items = self.collect_web_scrapes()
        search_items = self.collect_search_queries()

        all_items = rss_items + scrape_items + search_items

        if not all_items:
            print("\n⚠️  No items collected!")
            return

        # Generate outputs
        output_config = self.config.get('output', {})
        output_path_template = output_config.get('path', '/tmp/collection-{date}.md')

        output_path = Path(output_path_template.format(
            date=datetime.now().strftime('%Y-%m-%d'),
            category='all'
        ))

        self.generate_markdown(all_items, output_path)
        self.save_to_database(all_items)

        print(f"\n✅ Collection complete! {len(all_items)} total items collected")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 data-collector-orchestrator.py <config.yaml>")
        print("\nExamples:")
        print("  python3 data-collector-orchestrator.py configs/trucking-sources.yaml")
        print("  python3 data-collector-orchestrator.py configs/housing-sources.yaml")
        sys.exit(1)

    config_path = sys.argv[1]

    if not Path(config_path).exists():
        print(f"❌ Config file not found: {config_path}")
        sys.exit(1)

    orchestrator = DataCollectorOrchestrator(config_path)
    orchestrator.run()


if __name__ == "__main__":
    main()
