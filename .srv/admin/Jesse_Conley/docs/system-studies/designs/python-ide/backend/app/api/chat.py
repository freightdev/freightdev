import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

from pydantic import BaseModel
from fastapi import APIRouter, HTTPException

from ...agents.router import agent_router
from ...memory.storage import conversation_storage
from ...memory.context import ContextManager

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/chat", tags=["chat"])

class ChatMessage(BaseModel):
    role: str
    content: str
    timestamp: Optional[datetime] = None

class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    user_id: str = "default"
    agent_type: str = "coordinator"  # Changed from "chat" to use distributed agency
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None

class ChatResponse(BaseModel):
    message: str
    conversation_id: str
    message_id: str
    agent_type: str
    generation_time: float
    token_count: int

class ConversationListResponse(BaseModel):
    conversations: List[Dict[str, Any]]

@router.post("/send", response_model=ChatResponse)
async def send_message(request: ChatRequest):
    start_time = datetime.utcnow()
    if not request.conversation_id:
        request.conversation_id = await conversation_storage.create_conversation(
            user_id=request.user_id,
            agent_type=request.agent_type
        )
    user_message_id = await conversation_storage.save_message(
        conversation_id=request.conversation_id,
        role="user",
        content=request.message
    )
    context_manager = ContextManager()
    context_manager.set_conversation(request.conversation_id)
    context_manager.add_message(
        content=request.message,
        role="user",
        message_id=user_message_id
    )
    context = context_manager.get_context_for_prompt()
    response_content = await agent_router.route_message(
        message=request.message,
        context=context,
        agent_type=request.agent_type,
        temperature=request.temperature,
        max_tokens=request.max_tokens
    )
    generation_time = (datetime.utcnow() - start_time).total_seconds()
    assistant_message_id = await conversation_storage.save_message(
        conversation_id=request.conversation_id,
        role="assistant",
        content=response_content,
        generation_time=generation_time,
        temperature=request.temperature
    )
    context_manager.add_message(
        content=response_content,
        role="assistant",
        message_id=assistant_message_id
    )
    token_count = max(1, int(len(response_content.split()) * 1.3))
    return ChatResponse(
        message=response_content,
        conversation_id=request.conversation_id,
        message_id=assistant_message_id,
        agent_type=request.agent_type,
        generation_time=generation_time,
        token_count=token_count
    )

@router.get("/conversations/{user_id}", response_model=ConversationListResponse)
async def get_conversations(user_id: str, limit: int = 20):
    conversations = await conversation_storage.get_user_conversations(
        user_id=user_id,
        limit=limit
    )
    return ConversationListResponse(conversations=conversations)

@router.get("/conversations/{conversation_id}/messages")
async def get_conversation_messages(conversation_id: str, limit: int = 50):
    messages = await conversation_storage.get_conversation_messages(
        conversation_id=conversation_id,
        limit=limit
    )
    return {"messages": messages or []}

@router.post("/conversations")
async def create_conversation(user_id: str, title: Optional[str] = None, agent_type: str = "chat"):
    conversation_id = await conversation_storage.create_conversation(
        user_id=user_id,
        title=title,
        agent_type=agent_type
    )
    return {"conversation_id": conversation_id}
