#!/usr/bin/env python3
"""
Query Templates
Pre-built query configurations for common use cases
"""

import json
import os
from pathlib import Path

class QueryTemplates:
    """Pre-built query templates for common scenarios"""

    @staticmethod
    def project_kickoff(project_name: str, keywords: list) -> dict:
        """Template for gathering all knowledge about a new project"""
        return {
            "project_name": project_name,
            "queries": [
                {
                    "name": "all_mentions",
                    "search": " ".join(keywords),
                    "include_messages": True,
                    "filters": {
                        "min_messages": 3,
                        "limit": 100
                    }
                },
                {
                    "name": "architecture_decisions",
                    "search": f"{' '.join(keywords)} architecture design decision",
                    "include_messages": True,
                    "filters": {
                        "min_messages": 5
                    }
                },
                {
                    "name": "technical_discussions",
                    "search": f"{' '.join(keywords)} backend frontend database API",
                    "include_messages": True
                },
                {
                    "name": "code_snippets",
                    "search": " ".join(keywords),
                    "extract_code": True
                }
            ]
        }

    @staticmethod
    def tech_stack_research(technology: str) -> dict:
        """Template for researching a specific technology"""
        return {
            "project_name": f"{technology}_research",
            "queries": [
                {
                    "name": "all_discussions",
                    "search": technology,
                    "include_messages": True,
                    "filters": {
                        "limit": 100
                    }
                },
                {
                    "name": "code_examples",
                    "search": technology,
                    "extract_code": True,
                    "code_language": technology.lower()
                },
                {
                    "name": "best_practices",
                    "search": f"{technology} best practice pattern architecture",
                    "include_messages": True
                },
                {
                    "name": "problems_solutions",
                    "search": f"{technology} error problem issue fix solution",
                    "include_messages": True
                }
            ]
        }

    @staticmethod
    def language_deep_dive(language: str) -> dict:
        """Template for gathering all knowledge about a programming language"""
        return {
            "project_name": f"{language}_knowledge",
            "queries": [
                {
                    "name": "all_code",
                    "search": language,
                    "extract_code": True,
                    "code_language": language.lower()
                },
                {
                    "name": "tutorials_learning",
                    "search": f"{language} learn tutorial example how to",
                    "include_messages": True
                },
                {
                    "name": "advanced_concepts",
                    "search": f"{language} advanced async concurrency optimization",
                    "include_messages": True
                },
                {
                    "name": "frameworks_libraries",
                    "search": f"{language} framework library crate package",
                    "include_messages": True
                }
            ]
        }

    @staticmethod
    def feature_implementation(feature_name: str, keywords: list) -> dict:
        """Template for implementing a specific feature"""
        return {
            "project_name": f"feature_{feature_name}",
            "queries": [
                {
                    "name": "requirements",
                    "search": f"{feature_name} {' '.join(keywords)} requirement need should",
                    "include_messages": True
                },
                {
                    "name": "implementation_ideas",
                    "search": f"{feature_name} {' '.join(keywords)} implement build create",
                    "include_messages": True
                },
                {
                    "name": "code_examples",
                    "search": f"{feature_name} {' '.join(keywords)}",
                    "extract_code": True
                },
                {
                    "name": "similar_features",
                    "search": " ".join(keywords),
                    "include_messages": True,
                    "filters": {
                        "min_messages": 5
                    }
                }
            ]
        }

    @staticmethod
    def debugging_session(error_keywords: list) -> dict:
        """Template for finding solutions to errors"""
        return {
            "project_name": "debugging",
            "queries": [
                {
                    "name": "error_discussions",
                    "search": f"{' '.join(error_keywords)} error bug issue problem",
                    "include_messages": True
                },
                {
                    "name": "solutions",
                    "search": f"{' '.join(error_keywords)} fix solve solution workaround",
                    "include_messages": True
                },
                {
                    "name": "related_code",
                    "search": " ".join(error_keywords),
                    "extract_code": True
                }
            ]
        }

    @staticmethod
    def domain_expertise(domain: str) -> dict:
        """Template for gathering domain knowledge (e.g., trucking, finance, healthcare)"""
        return {
            "project_name": f"{domain}_domain",
            "queries": [
                {
                    "name": "domain_knowledge",
                    "search": domain,
                    "include_messages": True,
                    "filters": {
                        "limit": 200
                    }
                },
                {
                    "name": "terminology",
                    "search": f"{domain} term definition means what is",
                    "include_messages": True
                },
                {
                    "name": "workflows",
                    "search": f"{domain} process workflow flow step",
                    "include_messages": True
                },
                {
                    "name": "requirements",
                    "search": f"{domain} requirement regulation compliance rule",
                    "include_messages": True
                }
            ]
        }

    @staticmethod
    def architecture_review(project_keywords: list) -> dict:
        """Template for reviewing system architecture"""
        return {
            "project_name": "architecture_review",
            "queries": [
                {
                    "name": "architecture_decisions",
                    "search": f"{' '.join(project_keywords)} architecture design pattern",
                    "include_messages": True
                },
                {
                    "name": "database_design",
                    "search": f"{' '.join(project_keywords)} database schema model table",
                    "include_messages": True
                },
                {
                    "name": "api_design",
                    "search": f"{' '.join(project_keywords)} API endpoint route REST GraphQL",
                    "include_messages": True
                },
                {
                    "name": "infrastructure",
                    "search": f"{' '.join(project_keywords)} infrastructure deployment docker kubernetes",
                    "include_messages": True
                },
                {
                    "name": "security",
                    "search": f"{' '.join(project_keywords)} security auth authentication authorization",
                    "include_messages": True
                }
            ]
        }

    @staticmethod
    def timeline_analysis(project_keywords: list, start_date: str, end_date: str) -> dict:
        """Template for analyzing project evolution over time"""
        return {
            "project_name": "timeline_analysis",
            "queries": [
                {
                    "name": "early_phase",
                    "search": " ".join(project_keywords),
                    "include_messages": True,
                    "filters": {
                        "start_date": start_date,
                        "end_date": end_date
                    }
                },
                {
                    "name": "decisions_made",
                    "search": f"{' '.join(project_keywords)} decide decision chose",
                    "include_messages": True,
                    "filters": {
                        "start_date": start_date,
                        "end_date": end_date
                    }
                },
                {
                    "name": "problems_encountered",
                    "search": f"{' '.join(project_keywords)} problem issue error bug challenge",
                    "include_messages": True,
                    "filters": {
                        "start_date": start_date,
                        "end_date": end_date
                    }
                }
            ]
        }

    @staticmethod
    def code_migration(from_tech: str, to_tech: str) -> dict:
        """Template for migrating from one technology to another"""
        return {
            "project_name": f"migrate_{from_tech}_to_{to_tech}",
            "queries": [
                {
                    "name": "old_tech_code",
                    "search": from_tech,
                    "extract_code": True,
                    "code_language": from_tech.lower()
                },
                {
                    "name": "new_tech_examples",
                    "search": to_tech,
                    "extract_code": True,
                    "code_language": to_tech.lower()
                },
                {
                    "name": "migration_discussions",
                    "search": f"{from_tech} {to_tech} migrate convert port rewrite",
                    "include_messages": True
                },
                {
                    "name": "comparison",
                    "search": f"{from_tech} vs {to_tech} difference compare",
                    "include_messages": True
                }
            ]
        }

    @staticmethod
    def save_template(template: dict, output_file: str):
        """Save a template to a JSON file"""
        with open(output_file, 'w') as f:
            json.dump(template, f, indent=2)
        print(f"✅ Template saved to: {output_file}")


def main():
    """Command-line interface for generating templates"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate query templates')
    parser.add_argument('template_type', choices=[
        'project-kickoff',
        'tech-stack',
        'language-dive',
        'feature',
        'debug',
        'domain',
        'architecture',
        'timeline',
        'migration'
    ], help='Type of template to generate')

    parser.add_argument('--name', help='Project/feature/technology name')
    parser.add_argument('--keywords', nargs='+', help='Keywords for search')
    parser.add_argument('--language', help='Programming language')
    parser.add_argument('--from-tech', help='Technology to migrate from')
    parser.add_argument('--to-tech', help='Technology to migrate to')
    parser.add_argument('--start-date', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end-date', help='End date (YYYY-MM-DD)')
    parser.add_argument('--output', help='Output file (default: template.json)', default='template.json')

    args = parser.parse_args()

    templates = QueryTemplates()
    template = None

    if args.template_type == 'project-kickoff':
        if not args.name or not args.keywords:
            print("Error: --name and --keywords required for project-kickoff")
            return
        template = templates.project_kickoff(args.name, args.keywords)

    elif args.template_type == 'tech-stack':
        if not args.name:
            print("Error: --name required for tech-stack")
            return
        template = templates.tech_stack_research(args.name)

    elif args.template_type == 'language-dive':
        if not args.language:
            print("Error: --language required for language-dive")
            return
        template = templates.language_deep_dive(args.language)

    elif args.template_type == 'feature':
        if not args.name or not args.keywords:
            print("Error: --name and --keywords required for feature")
            return
        template = templates.feature_implementation(args.name, args.keywords)

    elif args.template_type == 'debug':
        if not args.keywords:
            print("Error: --keywords required for debug")
            return
        template = templates.debugging_session(args.keywords)

    elif args.template_type == 'domain':
        if not args.name:
            print("Error: --name required for domain")
            return
        template = templates.domain_expertise(args.name)

    elif args.template_type == 'architecture':
        if not args.keywords:
            print("Error: --keywords required for architecture")
            return
        template = templates.architecture_review(args.keywords)

    elif args.template_type == 'timeline':
        if not args.keywords or not args.start_date or not args.end_date:
            print("Error: --keywords, --start-date, and --end-date required for timeline")
            return
        template = templates.timeline_analysis(args.keywords, args.start_date, args.end_date)

    elif args.template_type == 'migration':
        if not args.from_tech or not args.to_tech:
            print("Error: --from-tech and --to-tech required for migration")
            return
        template = templates.code_migration(args.from_tech, args.to_tech)

    if template:
        templates.save_template(template, args.output)
        print("\nTo use this template:")
        print(f"  python3 batch_query.py process {args.output}")


if __name__ == "__main__":
    main()
