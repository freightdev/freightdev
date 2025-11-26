import logging
from typing import List, AsyncGenerator

from .base import BaseAgent, AgentType, AgentContext, AgentResponse
from ..inference.generator import text_generator
from ..inference.sampler import SamplingConfig

logger = logging.getLogger(__name__)

class ChatAgent(BaseAgent):
    """General conversation agent with streaming responses, only active if a model is loaded."""

    def __init__(self):
        super().__init__(AgentType.CHAT, "ChatAgent")

    def _get_system_prompt(self) -> str:
        return (
            "You are a helpful, intelligent AI assistant. You excel at:\n\n"
            "- Having natural, engaging conversations\n"
            "- Answering questions across many topics\n"
            "- Providing explanations and reasoning through problems\n"
            "- Being helpful while being honest about limitations\n"
            "- Maintaining context throughout conversations\n\n"
            "You should:\n"
            "- Be concise but thorough in your responses\n"
            "- Ask clarifying questions when needed\n"
            "- Provide examples when helpful\n"
            "- Admit when you don't know something\n"
            "- Stay focused on helping the human\n\n"
            "You are part of a personal AI system, so you can be more casual and direct than typical AI assistants."
        )

    def _define_capabilities(self) -> List[str]:
        return [
            "general_conversation",
            "question_answering",
            "explanations",
            "reasoning",
            "problem_solving",
            "creative_tasks",
            "research_assistance",
        ]

    def can_handle(self, message: str, context: AgentContext) -> float:
        message_lower = message.lower()
        conversation_indicators = [
            "what", "why", "how", "when", "where", "who",
            "explain", "tell me", "help me understand",
            "think", "opinion", "suggest", "recommend"
        ]
        technical_indicators = [
            "code", "function", "class", "variable", "debug",
            "error", "bug", "compile", "syntax", "git",
            "terminal", "command", "script"
        ]
        conversation_score = sum(1 for i in conversation_indicators if i in message_lower)
        technical_score = sum(1 for i in technical_indicators if i in message_lower)

        confidence = 0.7 + min(conversation_score * 0.1, 0.2) - min(technical_score * 0.15, 0.3)
        return max(0.1, min(1.0, confidence))

    async def process_message(self, context: AgentContext) -> AgentResponse:
        """Generate a standard, completed response (non-streaming)"""
        try:
            if not text_generator.is_model_loaded():
                return AgentResponse(
                    content="No model is currently loaded. Please select a model first.",
                    agent_type=self.agent_type,
                    confidence=0.0,
                    metadata={"error": "No model loaded"}
                )

            prompt = self.build_prompt(context)
            sampling_config = SamplingConfig.for_chat()

            response = text_generator.generate_response(
                prompt,
                **sampling_config.to_dict()
            )

            response = self.post_process_response(response, context)
            if not self.validate_response(response):
                logger.warning("Chat agent generated poor quality response")
                response = "I apologize, but I couldn't generate a good response. Could you rephrase your question?"

            metadata = self.extract_metadata(response)
            confidence = self._calculate_response_confidence(response, context)

            return AgentResponse(
                content=response,
                agent_type=self.agent_type,
                confidence=confidence,
                reasoning="Processed as general conversation/question",
                metadata=metadata
            )

        except Exception as e:
            logger.error(f"Chat agent error: {e}")
            return AgentResponse(
                content="I encountered an error while processing your message. Please try again.",
                agent_type=self.agent_type,
                confidence=0.0,
                metadata={"error": str(e)}
            )

    async def stream_message(self, context: AgentContext) -> AsyncGenerator[str, None]:
        """Stream response token by token"""
        if not text_generator.is_model_loaded():
            yield "No model is currently loaded. Please select a model first."
            return

        prompt = self.build_prompt(context)
        sampling_config = SamplingConfig.for_chat()

        try:
            for token in text_generator.stream_response(prompt, **sampling_config.to_dict()):
                yield token
        except Exception as e:
            logger.error(f"Streaming generation failed: {e}")
            yield f"Error: {str(e)}"

    def _calculate_response_confidence(self, response: str, context: AgentContext) -> float:
        confidence = 0.8
        if len(response.split()) < 5:
            confidence -= 0.2

        uncertainty_markers = ["i'm not sure", "i don't know", "maybe", "perhaps", "i think"]
        uncertainty_count = sum(1 for m in uncertainty_markers if m in response.lower())
        confidence -= min(uncertainty_count * 0.1, 0.3)

        if any(marker in response for marker in ["1.", "2.", "•", "-"]):
            confidence += 0.1
        if "example" in response.lower() or "for instance" in response.lower():
            confidence += 0.1

        return max(0.1, min(1.0, confidence))

# Global chat agent instance
chat_agent = ChatAgent()
