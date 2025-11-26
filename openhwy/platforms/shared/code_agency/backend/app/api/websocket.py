import logging
from typing import Dict, Set
from datetime import datetime

import asyncio
import json
from fastapi import WebSocket, WebSocketDisconnect, APIRouter

from ...agents.router import agent_router
from ...memory.storage import conversation_storage
from ...memory.context import ContextManager
from ...inference.model_manager import model_manager
from ...inference.generator import text_generator
from ...inference.sampler import SamplingConfig

logger = logging.getLogger(__name__)
router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.user_connections: Dict[str, Set[str]] = {}

    async def connect(self, websocket: WebSocket, connection_id: str, user_id: str = "default"):
        await websocket.accept()
        self.active_connections[connection_id] = websocket
        self.user_connections.setdefault(user_id, set()).add(connection_id)
        logger.info(f"WebSocket connected: {connection_id} for user {user_id}")

    def disconnect(self, connection_id: str, user_id: str = "default"):
        if connection_id in self.active_connections:
            self.active_connections.pop(connection_id)
        if user_id in self.user_connections and connection_id in self.user_connections[user_id]:
            self.user_connections[user_id].discard(connection_id)
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]
        logger.info(f"WebSocket disconnected: {connection_id}")

    async def send_personal_message(self, message: dict, connection_id: str):
        websocket = self.active_connections.get(connection_id)
        if websocket:
            try:
                await websocket.send_text(json.dumps(message))
            except Exception as e:
                logger.error(f"Error sending message to {connection_id}: {e}")

    async def send_to_user(self, message: dict, user_id: str):
        for connection_id in self.user_connections.get(user_id, set()).copy():
            await self.send_personal_message(message, connection_id)

manager = ConnectionManager()

@router.websocket("/ws/chat-user/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    logger.info(f"WebSocket connection attempt for user: {user_id}")
    
    connection_id = f"{user_id}_{datetime.utcnow().timestamp()}"
    
    try:
        await manager.connect(websocket, connection_id, user_id)
    except WebSocketDisconnect as e:
        logger.error(f"Connection failed for {user_id}: {e}")
        await websocket.close()
        return

    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            msg_type = message_data.get("type", "chat")

            if msg_type == "load_model":
                await handle_load_model(websocket, message_data)

            elif msg_type == "chat":
                await handle_chat_message(websocket, connection_id, user_id, message_data)

            elif msg_type == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))

            else:
                await websocket.send_text(json.dumps({"type": "error", "message": "Unknown message type"}))

    except WebSocketDisconnect as e:
        logger.warning(f"User {user_id} disconnected: {e}")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        try:
            if websocket.client_state == "OPEN": 
                await websocket.close()
        except Exception as e:
            logger.error(f"Error closing WebSocket for user {user_id}: {e}")
        manager.disconnect(connection_id, user_id)

async def handle_load_model(websocket: WebSocket, message_data: dict):
    model_json = message_data.get("model_json")
    if not model_json:
        await websocket.send_text(json.dumps({"type": "error", "message": "No model_json provided"}))
        return

    await websocket.send_text(json.dumps({"type": "status", "message": "Preparing to load model..."}))

    # Send initial progress
    await websocket.send_text(json.dumps({"type": "model_progress", "progress": 10, "status": "Checking model file..."}))

    try:
        # Load model in a thread to avoid blocking
        loop = asyncio.get_event_loop()

        # Progress updates during loading
        await websocket.send_text(json.dumps({"type": "model_progress", "progress": 30, "status": "Loading model into memory..."}))

        # Run the load in a thread
        success = await asyncio.to_thread(model_manager.load_model, model_json, None)

        if success:
            await websocket.send_text(json.dumps({"type": "model_progress", "progress": 90, "status": "Initializing model..."}))
            await asyncio.sleep(0.5)  # Small delay for UI
            await websocket.send_text(json.dumps({"type": "model_progress", "progress": 100, "status": "Model loaded!"}))
            await asyncio.sleep(0.3)
            await websocket.send_text(json.dumps({
                "type": "status",
                "message": f"✓ Model loaded: {model_manager.model_name}",
                "model_name": model_manager.model_name,
                "device": model_manager.device
            }))
        else:
            await websocket.send_text(json.dumps({"type": "error", "message": "Failed to load model"}))

    except Exception as e:
        logger.error(f"Error loading model: {e}")
        await websocket.send_text(json.dumps({"type": "error", "message": f"Error: {str(e)}"}))

async def handle_codriver_message(websocket: WebSocket, connection_id: str, user_id: str, message_data: dict):
    try:
        message_content = message_data.get("message", "")
        conversation_id = message_data.get("conversation_id")

        await websocket.send_text(json.dumps({"type": "message_received", "message": message_content}))

        if not conversation_id:
            conversation_id = await conversation_storage.create_conversation(user_id=user_id, agent_type="codriver")

        user_message_id = await conversation_storage.save_message(
            conversation_id=conversation_id, role="user", content=message_content
        )

        context_manager = ContextManager()
        context_manager.set_conversation(conversation_id)
        context_manager.add_message(content=message_content, role="user", message_id=user_message_id)

        await websocket.send_text(json.dumps({"type": "typing", "agent_type": "codriver"}))

        start_time = datetime.utcnow()
        context = context_manager.get_context_for_prompt()
        response = await codriver_agent.process_message(context)
        generation_time = (datetime.utcnow() - start_time).total_seconds()

        assistant_message_id = await conversation_storage.save_message(
            conversation_id=conversation_id,
            role="assistant",
            content=response.content,
            generation_time=generation_time
        )

        await websocket.send_text(json.dumps({
            "type": "response",
            "message": response.content,
            "conversation_id": conversation_id,
            "message_id": assistant_message_id,
            "agent_type": "codriver",
            "generation_time": generation_time,
            "suggestions": response.suggestions,
            "metadata": response.metadata
        }))

    except Exception as e:
        logger.error(f"Error handling CoDriver message: {e}")
        await websocket.send_text(json.dumps({"type": "error", "message": str(e)}))

async def handle_chat_message(websocket: WebSocket, connection_id: str, user_id: str, message_data: dict):
    try:
        message_content = message_data.get("message", "")
        conversation_id = message_data.get("conversation_id")
        agent_type = message_data.get("agent_type", "chat")

        # Check if model is loaded
        if not model_manager.is_loaded():
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": "No model loaded. Please select and load a model first from the dropdown above."
            }))
            return

        await websocket.send_text(json.dumps({"type": "message_received", "message": message_content}))

        if not conversation_id:
            conversation_id = await conversation_storage.create_conversation(user_id=user_id, agent_type=agent_type)

        user_message_id = await conversation_storage.save_message(conversation_id=conversation_id, role="user", content=message_content)

        context_manager = ContextManager()
        context_manager.set_conversation(conversation_id)
        context_manager.add_message(content=message_content, role="user", message_id=user_message_id)

        await websocket.send_text(json.dumps({"type": "typing", "agent_type": agent_type}))

        start_time = datetime.utcnow()
        context = context_manager.get_context_for_prompt()

        async def stream_tokens():
            try:
                for token in text_generator.stream_response(
                    message_content,
                    **SamplingConfig.for_chat().to_dict()
                ):
                    await websocket.send_text(json.dumps({"type": "token", "content": token}))
            except WebSocketDisconnect:
                logger.info(f"Client disconnected while streaming tokens for user {user_id}")
            except Exception as e:
                logger.error(f"Streaming error: {e}")
                await websocket.send_text(json.dumps({"type": "error", "message": str(e)}))

        await stream_tokens()

        generation_time = (datetime.utcnow() - start_time).total_seconds()
        assistant_message_id = await conversation_storage.save_message(
            conversation_id=conversation_id,
            role="assistant",
            content="(streamed content)",
            generation_time=generation_time
        )

        await websocket.send_text(json.dumps({
            "type": "done",
            "conversation_id": conversation_id,
            "message_id": assistant_message_id,
            "agent_type": agent_type,
            "generation_time": generation_time
        }))

    except Exception as e:
        logger.error(f"Error handling chat message: {e}")
        await websocket.send_text(json.dumps({"type": "error", "message": str(e)}))
