import logging
from typing import List, Optional, Dict
from dataclasses import dataclass
from datetime import datetime

from .embeddings import embedding_manager
from .storage import conversation_storage

logger = logging.getLogger(__name__)

@dataclass
class ContextChunk:
    """A piece of conversation context."""
    content: str
    role: str  # user, assistant, system
    timestamp: datetime
    importance: float = 1.0  # 0.0 to 1.0
    token_count: int = 0
    message_id: Optional[str] = None

class ContextManager:
    def __init__(self, max_context_tokens: int = 4096):
        self.max_context_tokens = max_context_tokens
        self.current_context: List[ContextChunk] = []
        self.conversation_id: Optional[str] = None
        
    def set_conversation(self, conversation_id: str):
        """Set the active conversation and load recent context."""
        self.conversation_id = conversation_id
        self._load_recent_context()
    
    def add_message(self, content: str, role: str, token_count: Optional[int] = None, message_id: Optional[str] = None):
        """Add a new message to the current context."""
        if token_count is None:
            token_count = int(len(content.split()) * 1.3)  # Rough token estimate
        
        chunk = ContextChunk(
            content=content,
            role=role,
            timestamp=datetime.utcnow(),
            token_count=token_count,
            message_id=message_id
        )
        
        self.current_context.append(chunk)
        self._trim_context_if_needed()
    
    def get_context_for_prompt(self, include_system: bool = True) -> str:
        """Build a context string suitable for model prompts."""
        context_parts = []
        for chunk in self.current_context:
            if not include_system and chunk.role == 'system':
                continue
            prefix = {"user": "Human", "assistant": "Assistant", "system": "System"}.get(chunk.role, "Unknown")
            context_parts.append(f"{prefix}: {chunk.content}")
        return "\n\n".join(context_parts)
    
    def get_relevant_context(self, query: str, max_chunks: int = 5) -> List[ContextChunk]:
        """Return contextually relevant chunks using embeddings."""
        if not self.conversation_id:
            return []
        
        results = embedding_manager.search_similar(query, k=max_chunks*2, threshold=0.6)
        
        relevant_chunks = []
        for result in results[:max_chunks]:
            chunk = ContextChunk(
                content=result['text'],
                role=result['metadata'].get('role', 'unknown'),
                timestamp=result['metadata'].get('timestamp', datetime.utcnow()),
                importance=result['similarity'],
                token_count=result['metadata'].get('token_count', 0)
            )
            relevant_chunks.append(chunk)
        
        return relevant_chunks
    
    def _load_recent_context(self, limit: int = 20):
        """Load the most recent messages from storage (placeholder)."""
        if not self.conversation_id:
            return
        # Placeholder for actual storage loading
        self.current_context = []
    
    def _trim_context_if_needed(self):
        """Trim context to respect token limit, keeping most recent messages."""
        total_tokens = sum(chunk.token_count for chunk in self.current_context)
        while total_tokens > self.max_context_tokens and len(self.current_context) > 1:
            removable_chunks = self.current_context[:-1]  # Keep last chunk
            if not removable_chunks:
                break
            least_important = min(removable_chunks, key=lambda x: x.importance)
            self.current_context.remove(least_important)
            total_tokens -= least_important.token_count
            logger.debug(f"Trimmed context: removed {least_important.token_count} tokens")
    
    def get_context_summary(self) -> Dict:
        """Return a summary of the current context."""
        total_tokens = sum(chunk.token_count for chunk in self.current_context)
        return {
            'total_chunks': len(self.current_context),
            'total_tokens': total_tokens,
            'utilization': total_tokens / self.max_context_tokens if self.max_context_tokens else 0,
            'oldest_message': min((c.timestamp for c in self.current_context), default=None),
            'newest_message': max((c.timestamp for c in self.current_context), default=None)
        }
