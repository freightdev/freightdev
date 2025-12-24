"""
Scout Agent - Finds leads from free sources
"""
import re
from typing import List, Dict
from datetime import datetime, timedelta
import requests
from bs4 import BeautifulSoup

from app.config.settings import config


class ScoutAgent:
    """Finds dev gigs from free sources"""

    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        }
        self.config = config

    def search_all(self, categories: List[str] = None, min_budget: int = 1000) -> List[Dict]:
        """
        Search all sources for leads

        Args:
            categories: List of categories to search (e.g., ['web_development'])
            min_budget: Minimum budget filter

        Returns:
            List of raw lead dictionaries
        """
        leads = []

        # Search each source
        leads.extend(self.search_reddit(categories, min_budget))
        leads.extend(self.search_hackernews())
        # TODO: Add Indeed, Twitter, LinkedIn scrapers

        return leads

    def search_reddit(self, categories: List[str] = None, min_budget: int = 1000) -> List[Dict]:
        """
        Scrape Reddit using configured subreddits and keywords

        Note: This is a basic scraper. For production, use PRAW (Reddit API)
        """
        leads = []

        # Use configured subreddits
        for subreddit_config in self.config.sources.reddit.subreddits:
            subreddit_name = subreddit_config['name']
            keywords = [k.lower() for k in subreddit_config['keywords']]
            exclude_keywords = [k.lower() for k in subreddit_config.get('exclude_keywords', [])]

            try:
                # Fetch posts from subreddit
                url = f"https://www.reddit.com/r/{subreddit_name}/new.json"
                params = {'limit': self.config.sources.reddit.limit}
                response = requests.get(url, headers=self.headers, params=params, timeout=15)

                if response.status_code == 200:
                    data = response.json()
                    posts = data.get('data', {}).get('children', [])

                    for post in posts:
                        post_data = post.get('data', {})

                        # Get title and text
                        title = post_data.get('title', '')
                        selftext = post_data.get('selftext', '')
                        full_text = (title + " " + selftext).lower()

                        # Check post age (skip old posts)
                        created = datetime.fromtimestamp(post_data.get('created_utc', 0))
                        max_age = timedelta(hours=self.config.sources.reddit.max_age_hours)
                        if datetime.now() - created > max_age:
                            continue

                        # Filter 1: Must be [Hiring] post
                        if not title.lower().startswith('[hiring]'):
                            # Also accept posts with hiring keywords
                            if not any(kw in title.lower() for kw in ['hiring', 'looking for', 'need developer', 'seeking']):
                                continue

                        # Filter 2: Must contain web development keywords
                        has_web_dev_keyword = any(keyword in full_text for keyword in keywords)
                        if not has_web_dev_keyword:
                            continue

                        # Filter 3: Must NOT contain exclusion keywords
                        has_exclusion = any(exclude in full_text for exclude in exclude_keywords)
                        if has_exclusion:
                            continue

                        # Extract budget
                        budget = self._extract_budget(title + " " + selftext)

                        # Filter 4: Must meet minimum budget (if budget found)
                        # If no budget mentioned, allow it through for manual review
                        if budget is not None and budget < min_budget:
                            continue

                        # Extract tech stack
                        tech_stack = self._extract_tech_stack(title + " " + selftext)

                        # Filter 5: Prefer posts mentioning preferred tech
                        preferred_tech = [t.lower() for t in self.config.filters.tech_stack.preferred]
                        has_preferred_tech = any(tech.lower() in full_text for tech in preferred_tech)

                        # Skip if it has avoided tech
                        avoided_tech = [t.lower() for t in self.config.filters.tech_stack.avoid]
                        has_avoided_tech = any(tech in full_text for tech in avoided_tech)
                        if has_avoided_tech:
                            continue

                        # Create lead
                        lead = {
                            'source': 'reddit',
                            'title': title,
                            'description': selftext[:1000],
                            'url': f"https://reddit.com{post_data.get('permalink', '')}",
                            'budget_min': budget if budget else None,
                            'budget_max': budget * 2 if budget else None,  # Rough estimate
                            'tech_stack': tech_stack,
                            'found_at': datetime.now(),
                        }

                        leads.append(lead)

            except Exception as e:
                print(f"Error scraping r/{subreddit_name}: {e}")

        return leads

    def search_hackernews(self) -> List[Dict]:
        """
        Scrape HackerNews 'Who is Hiring' monthly threads using config
        """
        leads = []

        try:
            # Find the latest "Who is Hiring" thread
            url = "https://news.ycombinator.com/submitted?id=whoishiring"
            response = requests.get(url, headers=self.headers, timeout=10)

            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')

                # Find "Who is Hiring" links using configured patterns
                thread_patterns = [t.lower() for t in self.config.sources.hackernews.thread_titles]
                hiring_links = soup.find_all('a', class_='storylink')

                for link in hiring_links[:1]:  # Just the latest thread
                    link_text_lower = link.text.lower()

                    # Match against configured thread patterns
                    if any(pattern in link_text_lower for pattern in thread_patterns):
                        thread_url = f"https://news.ycombinator.com/{link.get('href', '')}"

                        # Parse the thread
                        thread_response = requests.get(thread_url, headers=self.headers, timeout=10)
                        thread_soup = BeautifulSoup(thread_response.content, 'html.parser')

                        # Extract job posts (comments)
                        comments = thread_soup.find_all('div', class_='comment')

                        # Get configured keywords
                        keywords = [k.lower() for k in self.config.sources.hackernews.keywords]
                        max_comments = self.config.sources.hackernews.max_comments

                        for comment in comments[:max_comments]:
                            text = comment.get_text(strip=True)
                            text_lower = text.lower()

                            # Look for positions matching our keywords
                            if any(keyword in text_lower for keyword in keywords):
                                # Extract tech stack
                                tech_stack = self._extract_tech_stack(text)

                                # Only include if it mentions preferred or acceptable tech
                                preferred = [t.lower() for t in self.config.filters.tech_stack.preferred]
                                acceptable = [t.lower() for t in self.config.filters.tech_stack.acceptable]
                                all_acceptable = preferred + acceptable

                                has_relevant_tech = any(
                                    tech.lower() in text_lower for tech in all_acceptable
                                )

                                if not has_relevant_tech:
                                    continue

                                lead = {
                                    'source': 'hackernews',
                                    'title': text[:100],  # First 100 chars as title
                                    'description': text[:1000],
                                    'url': thread_url,
                                    'budget_min': None,  # HN doesn't usually list budgets
                                    'budget_max': None,
                                    'tech_stack': tech_stack,
                                    'found_at': datetime.now(),
                                }

                                leads.append(lead)

        except Exception as e:
            print(f"Error scraping HackerNews: {e}")

        return leads

    def _extract_budget(self, text: str) -> int:
        """Extract budget from text using config patterns"""
        # Use patterns from config
        for pattern_config in self.config.filters.budget.patterns:
            pattern = pattern_config['regex']
            multiplier = pattern_config.get('multiplier', 1)

            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                try:
                    # Get the captured number
                    value_str = match.group(1)

                    # Remove commas and handle 'k' notation
                    value_str = value_str.replace(',', '')

                    if 'k' in value_str.lower():
                        value = float(value_str.lower().replace('k', '')) * 1000
                    else:
                        value = float(value_str)

                    return int(value * multiplier)
                except (ValueError, IndexError):
                    # Skip invalid number formats
                    continue

        return None

    def _extract_tech_stack(self, text: str) -> List[str]:
        """Extract technologies mentioned in text using config"""
        # Combine all tech from config
        all_tech = (
            self.config.filters.tech_stack.preferred +
            self.config.filters.tech_stack.acceptable +
            self.config.filters.tech_stack.avoid
        )

        found = []
        text_lower = text.lower()

        for tech in all_tech:
            # Handle variations like "next.js" vs "nextjs"
            tech_variations = [
                tech.lower(),
                tech.lower().replace('.', ''),
                tech.lower().replace(' ', ''),
            ]

            if any(variation in text_lower for variation in tech_variations):
                found.append(tech)

        return list(set(found))  # Remove duplicates
