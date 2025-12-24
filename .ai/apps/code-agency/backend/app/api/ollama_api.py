"""
Ollama API Endpoints
Provides access to Ollama cluster models and chat functionality
"""
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Optional
import json

from ..services.ollama_service import get_cluster, ModelInfo

router = APIRouter(prefix="/api/ollama", tags=["ollama"])


class ChatMessage(BaseModel):
    role: str  # 'user' or 'assistant'
    content: str


class ChatRequest(BaseModel):
    model: str
    messages: List[ChatMessage]
    stream: bool = True
    node: Optional[str] = None


class GenerateRequest(BaseModel):
    model: str
    prompt: str
    stream: bool = True
    node: Optional[str] = None


@router.get("/models")
async def list_models():
    """Get all available models from the Ollama cluster"""
    try:
        cluster = get_cluster()
        models = cluster.get_all_unique_models()
        return {
            "models": [model.dict() for model in models],
            "count": len(models)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch models: {str(e)}")


@router.get("/models/detailed")
async def list_models_detailed():
    """Get all models grouped by node"""
    try:
        cluster = get_cluster()
        inventory = cluster.list_all_models()
        return {
            "inventory": inventory,
            "nodes": list(inventory.keys())
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch models: {str(e)}")


@router.get("/health")
async def health_check():
    """Check health of all Ollama nodes"""
    try:
        cluster = get_cluster()
        status = cluster.health_check()
        healthy_count = sum(1 for v in status.values() if v)
        return {
            "nodes": status,
            "healthy": healthy_count,
            "total": len(status),
            "all_healthy": all(status.values())
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")


@router.post("/chat")
async def chat(request: ChatRequest):
    """Chat with an Ollama model"""
    try:
        cluster = get_cluster()
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]

        if request.stream:
            async def stream_response():
                try:
                    for chunk in cluster.chat(
                        model=request.model,
                        messages=messages,
                        stream=True,
                        node=request.node
                    ):
                        # Send SSE format
                        if 'message' in chunk:
                            content = chunk['message'].get('content', '')
                            if content:
                                yield f"data: {json.dumps({'content': content, 'done': chunk.get('done', False)})}\n\n"
                        elif 'response' in chunk:
                            yield f"data: {json.dumps({'content': chunk['response'], 'done': chunk.get('done', False)})}\n\n"

                        if chunk.get('done', False):
                            yield f"data: {json.dumps({'done': True})}\n\n"
                            break
                except Exception as e:
                    yield f"data: {json.dumps({'error': str(e)})}\n\n"

            return StreamingResponse(
                stream_response(),
                media_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "X-Accel-Buffering": "no"
                }
            )
        else:
            response = cluster.chat(
                model=request.model,
                messages=messages,
                stream=False,
                node=request.node
            )
            return {"response": response}

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat failed: {str(e)}")


@router.post("/generate")
async def generate(request: GenerateRequest):
    """Generate text with an Ollama model"""
    try:
        cluster = get_cluster()

        if request.stream:
            async def stream_response():
                try:
                    for chunk in cluster.generate(
                        model=request.model,
                        prompt=request.prompt,
                        stream=True,
                        node=request.node
                    ):
                        if 'response' in chunk:
                            yield f"data: {json.dumps({'content': chunk['response'], 'done': chunk.get('done', False)})}\n\n"

                        if chunk.get('done', False):
                            yield f"data: {json.dumps({'done': True})}\n\n"
                            break
                except Exception as e:
                    yield f"data: {json.dumps({'error': str(e)})}\n\n"

            return StreamingResponse(
                stream_response(),
                media_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "X-Accel-Buffering": "no"
                }
            )
        else:
            response = cluster.generate(
                model=request.model,
                prompt=request.prompt,
                stream=False,
                node=request.node
            )
            return {"response": response}

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")


@router.get("/models/{model_name}/nodes")
async def find_model_nodes(model_name: str):
    """Find which nodes have a specific model"""
    try:
        cluster = get_cluster()
        nodes = cluster.find_model(model_name)
        return {
            "model": model_name,
            "nodes": nodes,
            "available": len(nodes) > 0
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to find model: {str(e)}")
