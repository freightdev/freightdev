import logging
from datetime import datetime
from typing import Dict, Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text

import psutil
import torch

from ...inference.model_manager import model_manager
from ...memory.database import db_manager
from ...memory.embeddings import embedding_manager

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/health", tags=["health"])

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    services: Dict[str, Any]
    system: Dict[str, Any]

class ModelStatus(BaseModel):
    loaded: bool = Field(default=False)
    model_name: str = Field(default="")
    device: str = Field(default="")
    memory_usage: float = Field(default=0.0)

@router.get("/", response_model=HealthResponse)
async def health_check():
    """Complete health check of all services"""
    timestamp = datetime.utcnow().isoformat()
    
    services = {
        "database": await check_database(),
        "model": check_model(),
        "embeddings": check_embeddings(),
        "memory": check_system_memory()
    }

    system = {
        "cpu_percent": psutil.cpu_percent(),
        "memory_percent": psutil.virtual_memory().percent,
        "disk_percent": psutil.disk_usage('/').percent,
        "python_executable": psutil.Process().exe(),
        "gpu_available": torch.cuda.is_available(),
        "gpu_count": torch.cuda.device_count() if torch.cuda.is_available() else 0
    }

    all_healthy = all(service.get("healthy", False) for service in services.values())
    status = "healthy" if all_healthy else "degraded"

    return HealthResponse(
        status=status,
        timestamp=timestamp,
        services=services,
        system=system
    )

@router.get("/model", response_model=ModelStatus)
async def model_status():
    """Check AI model status"""
    try:
        is_loaded = model_manager.is_loaded()
        memory_usage = 0.0
        device = ""
        model_name = ""

        if is_loaded:
            model_name = model_manager.model_name or ""
            device = model_manager.device or ""
            if torch.cuda.is_available():
                memory_usage = torch.cuda.memory_allocated() / 1024**3  # GB

        return ModelStatus(
            loaded=is_loaded,
            model_name=model_name,
            device=device,
            memory_usage=memory_usage
        )

    except Exception as e:
        logger.error(f"Model status check failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/model/load")
async def load_model(model_path: str):
    """Load a specific model"""
    try:
        success = model_manager.load_model(model_path)
        if success:
            return {"status": "success", "message": f"Model loaded: {model_path}"}
        raise HTTPException(status_code=400, detail="Failed to load model")
    except Exception as e:
        logger.error(f"Model loading failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/database")
async def database_status():
    """Check database connectivity"""
    return await check_database()

async def check_database():
    """Check database connections"""
    postgres_healthy = False
    duckdb_healthy = False

    try:
        session = await db_manager.get_postgres_session()
        await session.execute(text("SELECT 1"))
        await session.close()
        postgres_healthy = True
    except Exception as e:
        logger.warning(f"PostgreSQL check failed: {e}")

    try:
        conn = db_manager.get_duckdb_connection()
        conn.execute("SELECT 1")
        duckdb_healthy = True
    except Exception as e:
        logger.warning(f"DuckDB check failed: {e}")

    return {
        "healthy": postgres_healthy and duckdb_healthy,
        "postgres": {"healthy": postgres_healthy},
        "duckdb": {"healthy": duckdb_healthy}
    }

def check_model():
    """Check model status safely"""
    try:
        is_loaded = model_manager.is_loaded()
        model_name = model_manager.model_name if model_manager.model_name else ""
        device = model_manager.device if model_manager.device else ""
        return {
            "healthy": is_loaded,
            "loaded": is_loaded,
            "model_name": model_name,
            "device": device,
        }
    except Exception as e:
        logger.error(f"Model check error: {e}")
        return {"healthy": False, "loaded": False, "model_name": "", "device": ""}

def check_embeddings():
    """Check embeddings system"""
    try:
        healthy = embedding_manager.model is not None
        index_size = embedding_manager.index.ntotal if healthy and embedding_manager.index else 0
        embedding_dim = embedding_manager.embedding_dim if healthy else 0

        return {
            "healthy": healthy,
            "model_loaded": healthy,
            "embedding_dim": embedding_dim,
            "index_size": index_size
        }
    except Exception as e:
        logger.error(f"Embeddings check error: {e}")
        return {"healthy": False, "model_loaded": False, "embedding_dim": 0, "index_size": 0}

def check_system_memory():
    """Check system memory usage"""
    try:
        memory = psutil.virtual_memory()
        return {
            "healthy": memory.percent < 90,
            "total_gb": round(memory.total / 1024**3, 2),
            "used_gb": round(memory.used / 1024**3, 2),
            "available_gb": round(memory.available / 1024**3, 2),
            "percent": memory.percent
        }
    except Exception as e:
        logger.error(f"System memory check failed: {e}")
        return {"healthy": False, "total_gb": 0, "used_gb": 0, "available_gb": 0, "percent": 0}
