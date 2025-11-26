from typing import Optional
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

# Determine project root dynamically
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent 
ENV_FILE = PROJECT_ROOT / ".env"

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra='allow'
    )
    
    # App settings
    app_name: str = Field(default="AI Assistant", env="APP_NAME")
    app_version: str = Field(default="1.0.0", env="APP_VERSION")
    debug: bool = Field(default=True, env="DEBUG")
    host: str = Field(default="0.0.0.0", env="HOST")
    port: int = Field(default=8000, env="PORT")
    
    # Model settings
    models_dir: Path = Field(default=PROJECT_ROOT / "models", env="MODELS_DIR")
    max_context_length: int = Field(default=4096, env="MAX_CONTEXT_LENGTH")
    default_temperature: float = Field(default=0.7, env="DEFAULT_TEMPERATURE")
    default_max_tokens: int = Field(default=512, env="DEFAULT_MAX_TOKENS")
    
    # Database settings
    postgres_url: str = Field(env="POSTGRES_URL")
    duckdb_path: Path = Field(default=PROJECT_ROOT / "data" / "analytics.duckdb", env="DUCKDB_PATH")
    
    # Memory settings
    embeddings_model: str = Field(default="sentence-transformers/all-MiniLM-L6-v2", env="EMBEDDINGS_MODEL")
    embedding_dim: int = Field(default=384, env="EMBEDDINGS_DIMENSION")
    enable_embeddings: bool = Field(default=True, env="ENABLE_EMBEDDINGS")
    similarity_threshold: float = Field(default=0.7, env="SIMILARITY_THRESHOLD")
    
    # Workspace settings
    workspace_dir: Path = Field(default=PROJECT_ROOT / "workspace", env="WORKSPACE_DIR")
    max_file_size_mb: int = Field(default=50, env="MAX_FILE_SIZE_MB")
    
    # Security settings
    secret_key: str = Field(env="SECRET_KEY")
    keep_data_local_only: bool = Field(default=True, env="KEEP_DATA_LOCAL_ONLY")
    require_authentication: bool = Field(default=False, env="REQUIRE_AUTHENTICATION")
    
    # Logging settings
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    log_dir: Path = Field(default=PROJECT_ROOT / "data" / "logs", env="LOG_DIR")
    
    # Agent settings
    enable_chat_agent: bool = Field(default=True, env="ENABLE_CHAT_AGENT")
    enable_code_agent: bool = Field(default=True, env="ENABLE_CODE_AGENT")
    enable_codriver_agent: bool = Field(default=True, env="ENABLE_CODRIVER_AGENT")
    auto_agent_routing: bool = Field(default=True, env="AUTO_AGENT_ROUTING")
    
    # GitHub integration
    github_token: Optional[str] = Field(default=None, env="GITHUB_TOKEN")

# Global settings instance
settings = Settings()
