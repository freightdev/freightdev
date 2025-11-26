import asyncio
import asyncpg
from pathlib import Path
import logging

class MigrationRunner:
    def __init__(self, database_url: str, migrations_dir: str = "migrations"):
        self.database_url = database_url
        self.migrations_dir = Path(migrations_dir)
        
    async def run_migrations(self):
        """Run all pending migrations"""
        conn = await asyncpg.connect(self.database_url)
        
        try:
            # Create migrations table if it doesn't exist
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version VARCHAR(20) PRIMARY KEY,
                    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    filename VARCHAR(255) NOT NULL
                )
            """)
            
            # Get applied migrations
            applied = await conn.fetch("SELECT version FROM schema_migrations ORDER BY version")
            applied_versions = {row['version'] for row in applied}
            
            # Get available migrations
            migration_files = sorted(self.migrations_dir.glob("*.sql"))
            
            for migration_file in migration_files:
                version = migration_file.stem.split('_')[0]
                
                if version not in applied_versions:
                    print(f"Applying migration {migration_file.name}...")
                    
                    # Read and execute migration
                    sql = migration_file.read_text()
                    await conn.execute(sql)
                    
                    # Record as applied
                    await conn.execute(
                        "INSERT INTO schema_migrations (version, filename) VALUES ($1, $2)",
                        version, migration_file.name
                    )
                    
                    print(f"✅ Applied {migration_file.name}")
                else:
                    print(f"⏭️  Skipping {migration_file.name} (already applied)")
                    
        finally:
            await conn.close()

# Usage in your startup
async def initialize_database():
    runner = MigrationRunner(settings.postgres_url)
    await runner.run_migrations()