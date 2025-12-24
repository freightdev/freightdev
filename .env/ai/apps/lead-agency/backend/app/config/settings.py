"""
Lead Agency v2 - Configuration Loader
Loads and validates all configuration from YAML files
"""
import os
import yaml
from pathlib import Path
from typing import Dict, Any, List
from pydantic import BaseModel, Field

# Config directory
CONFIG_DIR = Path(__file__).parent


class RedditSourceConfig(BaseModel):
    subreddits: List[Dict[str, Any]]
    limit: int = 100
    max_age_hours: int = 72


class HackerNewsConfig(BaseModel):
    thread_titles: List[str]
    keywords: List[str]
    max_comments: int = 500


class IndeedConfig(BaseModel):
    enabled: bool = True
    search_terms: List[str]
    locations: List[str]
    job_types: List[str]
    limit: int = 50


class SourcesConfig(BaseModel):
    reddit: RedditSourceConfig
    hackernews: HackerNewsConfig
    indeed: IndeedConfig


class BudgetConfig(BaseModel):
    min_budget: int
    max_budget: int | None
    patterns: List[Dict[str, Any]]


class TechStackConfig(BaseModel):
    preferred: List[str]
    acceptable: List[str]
    avoid: List[str]


class FiltersConfig(BaseModel):
    budget: BudgetConfig
    tech_stack: TechStackConfig
    project_type: Dict[str, List[str]]
    quality_indicators: Dict[str, List[str]]
    min_score: Dict[str, int]


class ScoringConfig(BaseModel):
    scoring_weights: Dict[str, int]
    budget_scoring: Dict[str, List[Dict[str, Any]]]
    description_scoring: Dict[str, Any]
    tech_stack_scoring: Dict[str, int]
    client_quality_scoring: Dict[str, Any]
    timeline_scoring: Dict[str, int]
    engagement_scoring: Dict[str, int]
    penalties: Dict[str, int]


class SMTPConfig(BaseModel):
    host: str
    port: int
    use_tls: bool
    username: str
    password: str
    from_email: str
    from_name: str


class EmailConfig(BaseModel):
    smtp: SMTPConfig
    outreach: Dict[str, Any]
    templates: Dict[str, Dict[str, str]]
    tracking: Dict[str, bool]


class Config:
    """Main configuration class"""

    def __init__(self):
        self.sources = self._load_yaml('sources.yaml', SourcesConfig)
        self.filters = self._load_yaml('filters.yaml', FiltersConfig)
        self.scoring = self._load_yaml('scoring.yaml', ScoringConfig)
        self.email = self._load_yaml('email.yaml', EmailConfig)

    def _load_yaml(self, filename: str, model_class):
        """Load and validate YAML config file"""
        filepath = CONFIG_DIR / filename

        if not filepath.exists():
            raise FileNotFoundError(f"Config file not found: {filepath}")

        with open(filepath, 'r') as f:
            data = yaml.safe_load(f)

        # Replace environment variables
        data = self._replace_env_vars(data)

        # Validate with Pydantic
        return model_class(**data)

    def _replace_env_vars(self, data: Any) -> Any:
        """Recursively replace ${VAR} with environment variables"""
        if isinstance(data, dict):
            return {k: self._replace_env_vars(v) for k, v in data.items()}
        elif isinstance(data, list):
            return [self._replace_env_vars(item) for item in data]
        elif isinstance(data, str) and data.startswith('${') and data.endswith('}'):
            var_name = data[2:-1]
            return os.getenv(var_name, data)
        return data


# Global config instance
config = Config()
