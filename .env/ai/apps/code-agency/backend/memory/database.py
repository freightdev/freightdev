import logging
from pathlib import Path
from typing import Optional

import asyncpg
import duckdb
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from ..app.config import settings

logger = logging.getLogger(__name__)

class Base(DeclarativeBase):
    pass

class DatabaseManager:
    def __init__(self):
        self.postgres_engine: Optional[create_async_engine] = None
        self.postgres_session: Optional[async_sessionmaker] = None
        self.duckdb_conn: Optional[duckdb.DuckDBPyConnection] = None
        
    async def initialize_postgres(self) -> bool:
        """Initialize PostgreSQL connection for persistent storage"""
        try:
            self.postgres_engine = create_async_engine(
                settings.postgres_url,
                echo=settings.debug,
                pool_size=10,
                max_overflow=20
            )
            self.postgres_session = async_sessionmaker(
                self.postgres_engine,
                class_=AsyncSession,
                expire_on_commit=False
            )
            logger.info("PostgreSQL connection initialized")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize PostgreSQL: {e}")
            return False
    
    def initialize_duckdb(self) -> bool:
        """Initialize DuckDB for analytics and fast queries"""
        try:
            settings.duckdb_path.parent.mkdir(parents=True, exist_ok=True)
            self.duckdb_conn = duckdb.connect(str(settings.duckdb_path))
            
            self.duckdb_conn.execute("""
                CREATE TABLE IF NOT EXISTS conversation_analytics (
                    id VARCHAR PRIMARY KEY,
                    user_id VARCHAR,
                    agent_type VARCHAR,
                    message_count INTEGER,
                    tokens_used INTEGER,
                    duration_seconds FLOAT,
                    created_at TIMESTAMP,
                    sentiment_score FLOAT
                )
            """)
            
            self.duckdb_conn.execute("""
                CREATE TABLE IF NOT EXISTS token_usage (
                    id UUID PRIMARY KEY,
                    conversation_id VARCHAR,
                    prompt_tokens INTEGER,
                    completion_tokens INTEGER,
                    total_tokens INTEGER,
                    model_name VARCHAR,
                    timestamp TIMESTAMP
                )
            """)
            
            logger.info(f"DuckDB initialized at {settings.duckdb_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize DuckDB: {e}")
            return False
    
    async def get_postgres_session(self) -> AsyncSession:
        """Get a new PostgreSQL session"""
        if not self.postgres_session:
            initialized = await self.initialize_postgres()
            if not initialized:
                raise RuntimeError("Failed to initialize PostgreSQL session")
        return self.postgres_session()
    
    def get_duckdb_connection(self) -> duckdb.DuckDBPyConnection:
        """Get DuckDB connection"""
        if not self.duckdb_conn:
            initialized = self.initialize_duckdb()
            if not initialized:
                raise RuntimeError("Failed to initialize DuckDB connection")
        return self.duckdb_conn
    
    async def close_connections(self):
        """Close all database connections"""
        if self.postgres_engine:
            await self.postgres_engine.dispose()
        if self.duckdb_conn:
            self.duckdb_conn.close()

# Global database manager
db_manager = DatabaseManager()
