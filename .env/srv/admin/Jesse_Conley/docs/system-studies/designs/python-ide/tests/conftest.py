import pytest
import asyncio
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
import tempfile
import shutil
from pathlib import Path
import os
import uuid

# Import your app and components
from backend.app.main import app
from backend.memory.database import Base, db_manager
from backend.auth.models import User, UserSession
from backend.auth.auth_manager import auth_manager
from backend.app.config import settings

# Test database URL (using SQLite for tests)
TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"

@pytest_asyncio.fixture(scope="session")
async def async_engine():
    """Create test database engine"""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    
    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield engine
    
    # Cleanup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()

@pytest_asyncio.fixture
async def db_session(async_engine):
    """Create test database session"""
    async_session = sessionmaker(
        async_engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session() as session:
        yield session
        await session.rollback()

@pytest_asyncio.fixture
async def client():
    """Create test client"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
def sync_client():
    """Synchronous test client for simple tests"""
    return TestClient(app)

@pytest_asyncio.fixture
async def test_user(db_session):
    """Create a test user"""
    user = await auth_manager.create_user(
        username="testuser",
        email="test@example.com",
        password="testpassword123",
        full_name="Test User"
    )
    return user

@pytest_asyncio.fixture
async def admin_user(db_session):
    """Create an admin test user"""
    user = await auth_manager.create_user(
        username="admin",
        email="admin@example.com", 
        password="adminpassword123",
        full_name="Admin User",
        is_admin=True
    )
    return user

@pytest_asyncio.fixture
async def authenticated_client(client, test_user):
    """Client with authenticated user"""
    # Authenticate user and get session token
    user_session = await auth_manager.create_session(test_user.id)
    
    # Set session cookie
    client.cookies.set("session_token", user_session.session_token)
    
    return client

@pytest_asyncio.fixture
async def admin_client(client, admin_user):
    """Client with authenticated admin user"""
    user_session = await auth_manager.create_session(admin_user.id)
    client.cookies.set("session_token", user_session.session_token)
    return client

@pytest.fixture
def temp_workspace():
    """Create temporary workspace directory"""
    temp_dir = tempfile.mkdtemp()
    workspace_path = Path(temp_dir) / "workspace"
    workspace_path.mkdir()
    
    # Create some test files
    (workspace_path / "test.py").write_text("print('Hello World')")
    (workspace_path / "README.md").write_text("# Test Project")
    
    yield workspace_path
    
    # Cleanup
    shutil.rmtree(temp_dir)

@pytest.fixture
def mock_llama_runner(monkeypatch):
    """Mock the Rust llama_runner for testing"""
    class MockLlamaRunner:
        def __init__(self):
            self.model_loaded = False
            self.current_model = None
        
        async def load_model(self, model_path: str):
            self.model_loaded = True
            self.current_model = model_path
            return {"success": True, "model_path": model_path}
        
        async def generate_text(self, prompt: str, **kwargs):
            # Mock response based on prompt
            if "python" in prompt.lower():
                return "Here's a Python example:\n```python\nprint('Hello World')\n```"
            elif "explain" in prompt.lower():
                return "This is an explanation of the concept you asked about."
            else:
                return "This is a helpful AI response to your question."
        
        async def stream_generate(self, prompt: str, **kwargs):
            response = await self.generate_text(prompt, **kwargs)
            # Simulate streaming by yielding chunks
            words = response.split()
            for word in words:
                yield f"{word} "
        
        async def get_model_info(self):
            return {
                "loaded": self.model_loaded,
                "model_name": self.current_model,
                "context_size": 4096
            }
        
        async def health_check(self):
            return True
    
    mock_runner = MockLlamaRunner()
    
    # Replace the real client with our mock
    import backend.inference.model_manager as mm
    monkeypatch.setattr(mm, "llama_runner_client", mock_runner)
    
    return mock_runner

# Pytest configuration
pytest_plugins = ["pytest_asyncio"]

def pytest_configure(config):
    """Configure pytest"""
    # Set test environment
    os.environ["TESTING"] = "true"
    os.environ["DATABASE_URL"] = TEST_DATABASE_URL
    
def pytest_unconfigure(config):
    """Cleanup after tests"""
    # Remove test database file
    db_file = Path("test.db")
    if db_file.exists():
        db_file.unlink()

# Custom markers
pytest.mark.unit = pytest.mark.unit
pytest.mark.integration = pytest.mark.integration  
pytest.mark.e2e = pytest.mark.e2e
pytest.mark.slow = pytest.mark.slow