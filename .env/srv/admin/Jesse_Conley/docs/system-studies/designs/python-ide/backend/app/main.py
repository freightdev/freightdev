from fastapi import FastAPI, Request, APIRouter, Depends, Form
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from pathlib import Path
import logging
from contextlib import asynccontextmanager

from .api.chat import router as chat_router
from .api.websocket import router as websocket_router
from .api.health import router as health_router
from .api.ide import router as ide_router
from .api.models import router as models_router
from .api.auth import router as auth_router
from .api.agency import router as agency_router

# Agency Control Center APIs
from .api.auth_api import router as auth_control_router
from .api.control_api import router as control_router

from ..memory.database import db_manager
from ..memory.embeddings import embedding_manager
from ..inference.model_manager import model_manager
from .config import settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parent
TEMPLATES_DIR = BASE_DIR / "templates"
STATIC_DIR = BASE_DIR / "static"

templates = Jinja2Templates(directory=TEMPLATES_DIR)
STATIC_DIR.mkdir(exist_ok=True)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Personal AI Development Environment"
)

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.debug else ["https://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(models_router, prefix="/api", tags=["models"])
app.include_router(chat_router)  # Already has /api/chat prefix
app.include_router(websocket_router, tags=["websocket"])
app.include_router(health_router)  # Already has /api/health prefix
app.include_router(ide_router)  # Already has /api/ide prefix
app.include_router(auth_router, prefix="/api/auth", tags=["auth"])
app.include_router(agency_router, tags=["agency"])  # Agency integration

# Agency Control Center
app.include_router(auth_control_router)  # Already has /api/auth prefix
app.include_router(control_router)  # Already has /api/control prefix

# Ollama Integration
from .api.ollama_api import router as ollama_router
app.include_router(ollama_router)  # Already has /api/ollama prefix


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting AI Assistant...")

    # Initialize databases (gracefully handle failures in dev mode)
    try:
        await db_manager.initialize_postgres()
        logger.info("PostgreSQL initialized successfully")
    except Exception as e:
        logger.warning(f"PostgreSQL initialization failed (continuing without it): {e}")

    try:
        db_manager.initialize_duckdb()
        logger.info("DuckDB initialized successfully")
    except Exception as e:
        logger.warning(f"DuckDB initialization failed (continuing without it): {e}")

    try:
        embedding_manager.initialize()
        logger.info("Embeddings initialized successfully")
    except Exception as e:
        logger.warning(f"Embeddings initialization failed (continuing without it): {e}")

    logger.info("AI Assistant started successfully")
    yield

    logger.info("Shutting down AI Assistant...")
    try:
        await db_manager.close_connections()
    except Exception as e:
        logger.warning(f"Error closing connections: {e}")

    # Close agency bridge
    try:
        from ..agents.agency_bridge import close_bridge
        await close_bridge()
        logger.info("Agency bridge closed")
    except Exception as e:
        logger.warning(f"Error closing agency bridge: {e}")

    # Close coordinator agent
    try:
        from ..agents.coordinator_agent import close_coordinator_agent
        await close_coordinator_agent()
        logger.info("Coordinator agent closed")
    except Exception as e:
        logger.warning(f"Error closing coordinator agent: {e}")

    logger.info("AI Assistant stopped")

app.router.lifespan_context = lifespan


@app.get("/")
async def home(request: Request):
    """AI Assistant IDE - Main interface"""
    return templates.TemplateResponse(
        "ide.html", {"request": request, "title": "AI Assistant IDE"}
    )

@app.get("/control")
async def control_center(request: Request):
    """Agency Control Center Dashboard"""
    return templates.TemplateResponse(
        "dashboard.html", {"request": request, "title": "Agency Control Center"}
    )

@app.get("/chat")
async def chat_interface(request: Request):
    return templates.TemplateResponse(
        "chat.html", {"request": request, "title": "AI Chat"}
    )

@app.get("/settings")
async def settings_page(request: Request):
    return templates.TemplateResponse(
        "settings.html",
        {
            "request": request,
            "title": "Settings",
            "current_model": model_manager.model_name,
            "device": model_manager.device,
        }
    )


# Auth Pages
@app.get("/login")
@app.get("/auth/login")
async def login_page(request: Request):
    """Agency Control Center Login"""
    return templates.TemplateResponse("login.html", {"request": request, "title": "Agency Login"})

@app.get("/auth/register")
async def register_page(request: Request):
    return templates.TemplateResponse("register.html", {"request": request, "title": "Register"})

@app.get("/auth/forgot-password")
async def forgot_password_page(request: Request):
    return templates.TemplateResponse("forgot-password.html", {"request": request, "title": "Forgot Password"})

@app.get("/auth/verify")
async def verify_email_page(request: Request):
    return templates.TemplateResponse("verify.html", {"request": request, "title": "Verify Email"})

@app.get("/auth/oauth")
async def oauth_page(request: Request):
    return templates.TemplateResponse("oauth.html", {"request": request, "title": "OAuth Login"})


health_check_router = APIRouter()

@health_check_router.get("/ping")
@health_check_router.get("/health")
async def health():
    return {"status": "ok", "message": "AI Assistant is running"}

app.include_router(health_check_router)


if __name__ == "__main__":
    uvicorn.run(
        "backend.app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info"
    )
