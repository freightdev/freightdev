"""
Coordinator Agent - Routes all chat through the Rust Command Coordinator
This replaces Claude and local Ollama with your distributed agent system
"""

import logging
import httpx
from typing import List, Optional, AsyncGenerator
import json

from .base import BaseAgent, AgentType, AgentContext, AgentResponse

logger = logging.getLogger(__name__)

class CoordinatorAgent(BaseAgent):
    """
    Agent that routes all requests through the Rust Command Coordinator.

    The coordinator uses your 4-node Ollama cluster and 13+ agents to handle requests.
    This replaces direct Claude API calls or local Ollama usage.
    """

    def __init__(self, coordinator_url: str = "http://127.0.0.1:9015"):
        super().__init__(AgentType.COORDINATOR, "CommandCoordinator")
        self.coordinator_url = coordinator_url
        self.client = httpx.AsyncClient(timeout=120.0)  # 2 min for complex generations
        logger.info(f"Coordinator Agent initialized: {coordinator_url}")

    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()

    def _get_system_prompt(self) -> str:
        """Not used - coordinator handles prompting"""
        return ""

    def _define_capabilities(self) -> List[str]:
        return [
            "natural_language_processing",
            "code_generation",
            "web_search",
            "file_operations",
            "agent_coordination",
            "task_routing",
            "multi_agent_orchestration"
        ]

    def can_handle(self, message: str, context: AgentContext) -> float:
        """Coordinator can handle everything - it routes to specialists"""
        return 1.0  # Always confident - it delegates

    async def check_health(self) -> bool:
        """Check if command-coordinator is available"""
        try:
            response = await self.client.get(f"{self.coordinator_url}/health")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Coordinator health check failed: {e}")
            return False

    async def process_message(self, context: AgentContext) -> AgentResponse:
        """
        Route message through the command-coordinator.

        The coordinator will:
        1. Use Ollama (qwen2.5, etc.) to parse the command
        2. Route to appropriate agents (code-assistant, web-search, etc.)
        3. Return consolidated results
        """
        try:
            # Check if coordinator is available
            is_healthy = await self.check_health()
            if not is_healthy:
                return AgentResponse(
                    content="⚠️ Command Coordinator is offline. Please start the agency: ./start-agency.sh",
                    agent_type=self.agent_type,
                    confidence=0.0,
                    metadata={"error": "Coordinator offline"}
                )

            # Prepare request for coordinator
            request_data = {
                "command": context.message,
                "model": self._select_model(context.message),
                "context": {
                    "conversation_id": context.conversation_id,
                    "user_id": context.user_id,
                    "history": context.conversation_history[:500] if context.conversation_history else None
                }
            }

            # Route through coordinator
            logger.info(f"Routing to coordinator: {context.message[:50]}...")
            response = await self.client.post(
                f"{self.coordinator_url}/command",
                json=request_data,
                timeout=120.0
            )
            response.raise_for_status()
            result = response.json()

            # Extract response
            if result.get("success"):
                content = self._format_response(result, context)
                confidence = 0.9  # Coordinator successfully routed

                return AgentResponse(
                    content=content,
                    agent_type=self.agent_type,
                    confidence=confidence,
                    reasoning=f"Routed through coordinator ({result.get('execution_time_ms', 0)}ms)",
                    metadata={
                        "actions_taken": result.get("actions_taken", []),
                        "execution_time_ms": result.get("execution_time_ms", 0),
                        "coordinator_response": result
                    }
                )
            else:
                # Coordinator returned error
                error_msg = result.get("error", "Unknown error")
                return AgentResponse(
                    content=f"⚠️ Error: {error_msg}",
                    agent_type=self.agent_type,
                    confidence=0.0,
                    metadata={"error": error_msg}
                )

        except httpx.TimeoutException:
            logger.error("Coordinator request timed out")
            return AgentResponse(
                content="⏱️ Request timed out. The task may be complex - try breaking it into smaller steps.",
                agent_type=self.agent_type,
                confidence=0.0,
                metadata={"error": "timeout"}
            )
        except Exception as e:
            logger.error(f"Coordinator agent error: {e}")
            return AgentResponse(
                content=f"❌ Error communicating with coordinator: {str(e)}",
                agent_type=self.agent_type,
                confidence=0.0,
                metadata={"error": str(e)}
            )

    def _select_model(self, message: str) -> str:
        """
        Select appropriate Ollama model based on task type.

        Models available in your cluster:
        - qwen2.5:14b - Best for general routing and understanding
        - codellama:13b - Code generation
        - deepcoder:14b - Advanced coding
        - smallthinker:3b - Fast simple tasks
        """
        message_lower = message.lower()

        # Code generation tasks
        if any(word in message_lower for word in ["code", "function", "class", "implement", "create", "build", "develop"]):
            if any(word in message_lower for word in ["complex", "advanced", "optimize", "refactor"]):
                return "deepcoder:14b"
            return "codellama:13b"

        # SQL generation
        if any(word in message_lower for word in ["sql", "query", "database", "select", "table"]):
            return "duckdb-nsql:7b"

        # Quick tasks
        if any(word in message_lower for word in ["quick", "simple", "fast", "just"]):
            return "smallthinker:3b"

        # Default: best general model
        return "qwen2.5:14b"

    def _format_response(self, result: dict, context: AgentContext) -> str:
        """Format coordinator response for display"""
        actions_taken = result.get("actions_taken", [])
        results = result.get("result", {}).get("results", [])

        # If we got actual results from agents
        if results and len(results) > 0:
            content_parts = []

            for i, agent_result in enumerate(results):
                if isinstance(agent_result, dict):
                    response_text = agent_result.get("response", agent_result.get("result", ""))
                    if response_text:
                        content_parts.append(response_text)

            if content_parts:
                return "\n\n".join(content_parts)

        # If we got actions but no results, inform user
        if actions_taken:
            actions_str = ", ".join(actions_taken)
            return f"✅ Executed: {actions_str}\n\nThe task completed successfully."

        # Fallback
        return "Task processed by coordinator. Check logs for details."

    async def stream_message(self, context: AgentContext) -> AsyncGenerator[str, None]:
        """
        Stream response from coordinator (not yet implemented in coordinator).
        For now, we'll do a non-streaming request and yield chunks.
        """
        response = await self.process_message(context)

        # Yield in chunks for streaming effect
        words = response.content.split()
        chunk_size = 5

        for i in range(0, len(words), chunk_size):
            chunk = " ".join(words[i:i+chunk_size]) + " "
            yield chunk

    def get_debug_info(self) -> dict:
        """Get debug information about coordinator connection"""
        return {
            "agent_type": self.agent_type.value,
            "name": self.name,
            "coordinator_url": self.coordinator_url,
            "capabilities": self.capabilities,
            "can_stream": False,  # Not yet implemented
            "timeout": "120s"
        }


# Global coordinator agent instance
coordinator_agent = None

def get_coordinator_agent() -> CoordinatorAgent:
    """Get or create global coordinator agent instance"""
    global coordinator_agent
    if coordinator_agent is None:
        coordinator_agent = CoordinatorAgent()
    return coordinator_agent

async def close_coordinator_agent():
    """Close global coordinator agent"""
    global coordinator_agent
    if coordinator_agent:
        await coordinator_agent.close()
        coordinator_agent = None
