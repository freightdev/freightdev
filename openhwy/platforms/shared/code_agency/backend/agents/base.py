import logging
from datetime import datetime
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class AgentType(Enum):
    CHAT = "chat"
    CODE = "code"
    CODRIVER = "codriver"
    COORDINATOR = "coordinator"  # NEW: Distributed agency coordinator


@dataclass
class AgentContext:
    """Context information passed to agents"""
    conversation_id: str
    user_id: str
    message: str
    conversation_history: str
    agent_type: AgentType
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}

@dataclass
class AgentResponse:
    """Response from an agent"""
    content: str
    agent_type: AgentType
    confidence: float = 1.0  # 0.0 to 1.0
    reasoning: Optional[str] = None
    suggestions: List[str] = None
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.suggestions is None:
            self.suggestions = []
        if self.metadata is None:
            self.metadata = {}

class BaseAgent(ABC):
    """Base class for all AI agents"""
    
    def __init__(self, agent_type: AgentType, name: str = None):
        self.agent_type = agent_type
        self.name = name or agent_type.value
        self.system_prompt = self._get_system_prompt()
        self.capabilities = self._define_capabilities()
        
    @abstractmethod
    def _get_system_prompt(self) -> str:
        """Return the system prompt for this agent"""
        pass
    
    @abstractmethod
    def _define_capabilities(self) -> List[str]:
        """Define what this agent can do"""
        pass
    
    @abstractmethod
    async def process_message(self, context: AgentContext) -> AgentResponse:
        """Process a message and return response"""
        pass
    
    def can_handle(self, message: str, context: AgentContext) -> float:
        """
        Determine if this agent can handle the message
        Returns confidence score 0.0 to 1.0
        """
        # Default implementation - can be overridden by specific agents
        return 0.5
    
    def build_prompt(self, context: AgentContext) -> str:
        """Build the complete prompt for the model"""
        prompt_parts = []
        
        # System prompt
        if self.system_prompt:
            prompt_parts.append(f"System: {self.system_prompt}")
        
        # Conversation history (if provided)
        if context.conversation_history:
            prompt_parts.append("Previous conversation:")
            prompt_parts.append(context.conversation_history)
        
        # Current user message
        prompt_parts.append(f"Human: {context.message}")
        prompt_parts.append("Assistant:")
        
        return "\n\n".join(prompt_parts)
    
    def extract_metadata(self, response: str) -> Dict[str, Any]:
        """Extract metadata from model response"""
        metadata = {
            "agent_name": self.name,
            "agent_type": self.agent_type.value,
            "response_length": len(response),
            "word_count": len(response.split()),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Look for special markers in response
        if "```" in response:
            metadata["contains_code"] = True
            metadata["code_blocks"] = response.count("```") // 2
        
        if any(word in response.lower() for word in ["error", "exception", "failed", "problem"]):
            metadata["mentions_errors"] = True
        
        if any(word in response.lower() for word in ["suggest", "recommend", "consider", "might want"]):
            metadata["contains_suggestions"] = True
            
        return metadata
    
    def validate_response(self, response: str) -> bool:
        """Validate that the response is appropriate"""
        if not response or len(response.strip()) == 0:
            return False
        
        # Check for excessive repetition
        words = response.split()
        if len(words) > 10:
            unique_words = set(words)
            if len(unique_words) / len(words) < 0.3:  # Too repetitive
                return False
        
        # Check for obvious errors
        error_patterns = [
            "I cannot",
            "I don't know",
            "Error:",
            "Exception:",
            "null",
            "undefined"
        ]
        
        response_lower = response.lower()
        error_count = sum(1 for pattern in error_patterns if pattern.lower() in response_lower)
        
        # If more than 20% of response is error-related, it might be problematic
        if len(response.split()) > 0 and error_count / len(response.split()) > 0.2:
            return False
            
        return True
    
    def post_process_response(self, response: str, context: AgentContext) -> str:
        """Post-process the response before returning"""
        # Remove any system artifacts
        response = response.strip()
        
        # Remove common model artifacts
        artifacts_to_remove = [
            "Assistant:",
            "Human:",
            "System:",
        ]
        
        for artifact in artifacts_to_remove:
            if response.startswith(artifact):
                response = response[len(artifact):].strip()
        
        return response
    
    def get_debug_info(self) -> Dict[str, Any]:
        """Get debug information about the agent"""
        return {
            "name": self.name,
            "type": self.agent_type.value,
            "capabilities": self.capabilities,
            "system_prompt_length": len(self.system_prompt) if self.system_prompt else 0
        }

class AgentError(Exception):
    """Custom exception for agent errors"""
    def __init__(self, message: str, agent_type: AgentType = None, context: AgentContext = None):
        super().__init__(message)
        self.agent_type = agent_type
        self.context = context