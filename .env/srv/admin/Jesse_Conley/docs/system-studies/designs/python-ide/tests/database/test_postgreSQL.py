import asyncio
from sqlalchemy import text
from backend.memory.database import db_manager

async def test_postgres():
    await db_manager.initialize_postgres()
    
    async with db_manager.postgres_session() as session:
        result = await session.execute(text("SELECT 1"))
        print("Postgres test:", result.all())
    
    await db_manager.close_connections()

asyncio.run(test_postgres())
