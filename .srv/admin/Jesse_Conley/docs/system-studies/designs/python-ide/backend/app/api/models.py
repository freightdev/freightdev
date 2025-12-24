from typing import List, Dict
from pathlib import Path

import json
from pydantic import BaseModel
from fastapi import APIRouter

from ...inference.model_manager import model_manager
from ..config import settings

router = APIRouter()
MODELS_DIR = Path(settings.models_dir)

class LoadModelRequest(BaseModel):
    model_json_path: str

def list_available_models() -> List[Dict]:
    models = []
    for meta_file in MODELS_DIR.glob("*/model.json"):
        with open(meta_file) as f:
            meta = json.load(f)
            models.append({
                "name": meta.get("name") or meta_file.parent.name,
                "description": meta.get("description", ""),
                "json_path": str(meta_file),
                "installed": Path(meta["path"]).exists()
            })
    return models

@router.get("/models")
def get_models():
    """Return available models and their install status"""
    return list_available_models()

@router.post("/models/load")
def load_model(request: LoadModelRequest):
    """Load a model dynamically"""
    success = model_manager.load_model(request.model_json_path)
    if not success:
        return {"status": "error", "message": "Failed to load model"}
    return {"status": "ok", "model_name": model_manager.model_name}

@router.post("/models/unload")
def unload_model():
    """Unload current model"""
    model_manager.unload_model()
    return {"status": "ok"}
