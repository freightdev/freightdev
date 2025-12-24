import logging
from typing import Dict, List, Optional, Tuple

from .base import BaseAgent, AgentType, AgentContext, AgentResponse
from .chat_agent import chat_agent
from .code_agent import code_agent
from .codriver_agent import CoDriverAgent
from .coordinator_agent import get_coordinator_agent

logger = logging.getLogger(__name__)

class AgentRouter:
    """Routes messages to the most appropriate agent"""

    def __init__(self):
        # Initialize CoDriver (old, local Ollama)
        self.codriver = CoDriverAgent()

        # Initialize Command Coordinator (new, distributed system)
        self.coordinator = get_coordinator_agent()

        # All available agents
        self.agents: Dict[str, BaseAgent] = {
            "chat": chat_agent,
            "code": code_agent,
            "codriver": self.codriver,
            "coordinator": self.coordinator  # NEW: Use distributed agency
        }

        # Default routing preferences - USE COORDINATOR NOW
        self.default_agent = "coordinator"  # Route to distributed agency
        self.confidence_threshold = 0.7  # Minimum confidence to route directly
        
    async def route_message(self, message: str, context: str = "", agent_type: str = None,
                            conversation_id: str = None, user_id: str = "default",
                            **generation_kwargs) -> str:
        """
        Route message to appropriate agent and return response
        
        Args:
            message: The user's message
            context: Conversation context/history
            agent_type: Specific agent to use (optional)
            conversation_id: ID of the conversation
            user_id: User identifier
            **generation_kwargs: Additional parameters for text generation
        """
        try:
            # Create agent context
            agent_context = AgentContext(
                conversation_id=conversation_id or "default",
                user_id=user_id,
                message=message,
                conversation_history=context,
                agent_type=AgentType.CODRIVER,  # Will be updated by routing
                metadata=generation_kwargs
            )
            
            # Route to specific agent if requested
            if agent_type and agent_type in self.agents:
                agent_context.agent_type = AgentType(agent_type)
                agent = self.agents[agent_type]
                logger.info(f"Routing to requested agent: {agent_type}")
                
                response = await agent.process_message(agent_context)
                return response.content
            
            # Otherwise, let Coordinator handle routing/coordination
            logger.info("Routing to Command Coordinator (distributed agency)")
            agent_context.agent_type = AgentType.COORDINATOR
            response = await self.coordinator.process_message(agent_context)

            return response.content
            
        except Exception as e:
            logger.error(f"Routing error: {e}")
            return "I encountered an error while processing your message. Please try again."
    
    def analyze_message(self, message: str, context: str = "") -> Dict[str, float]:
        """Analyze which agents can handle the message and their confidence scores"""
        agent_context = AgentContext(
            conversation_id="analysis",
            user_id="system", 
            message=message,
            conversation_history=context,
            agent_type=AgentType.CHAT
        )
        
        scores = {}
        for name, agent in self.agents.items():
            try:
                scores[name] = agent.can_handle(message, agent_context)
            except Exception as e:
                logger.error(f"Error analyzing message for {name}: {e}")
                scores[name] = 0.0
        
        return scores
    
    def get_best_agent(self, message: str, context: str = "") -> Tuple[str, float]:
        """Get the best agent for handling a message"""
        scores = self.analyze_message(message, context)
        
        if not scores:
            return self.default_agent, 0.5
        
        best_agent = max(scores, key=scores.get)
        best_score = scores[best_agent]
        
        return best_agent, best_score
    
    def get_agent_capabilities(self) -> Dict[str, List[str]]:
        """Get capabilities of all agents"""
        capabilities = {}
        for name, agent in self.agents.items():
            capabilities[name] = {
                "type": agent.agent_type.value,
                "capabilities": agent.capabilities,
                "name": agent.name
            }
        return capabilities
    
    def get_routing_explanation(self, message: str, context: str = "") -> Dict:
        """Get detailed explanation of routing decision"""
        scores = self.analyze_message(message, context)
        best_agent, best_score = self.get_best_agent(message, context)
        
        return {
            "message": message,
            "all_scores": scores,
            "recommended_agent": best_agent,
            "confidence": best_score,
            "would_route_directly": best_score >= self.confidence_threshold,
            "explanation": self._explain_routing_decision(message, scores, best_agent)
        }
    
    def _explain_routing_decision(self, message: str, scores: Dict[str, float], 
                                best_agent: str) -> str:
        """Generate human-readable explanation of routing decision"""
        explanations = []
        
        # Sort agents by score
        sorted_agents = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        
        explanations.append(f"Message: '{message[:50]}{'...' if len(message) > 50 else ''}'")
        explanations.append(f"Recommended agent: {best_agent} (confidence: {scores[best_agent]:.2f})")
        
        # Explain why each agent scored as it did
        for agent_name, score in sorted_agents:
            if score > 0.3:
                if agent_name == "chat":
                    if score > 0.7:
                        explanations.append(f"- Chat agent: High confidence ({score:.2f}) - appears to be general conversation/question")
                    else:
                        explanations.append(f"- Chat agent: Moderate confidence ({score:.2f}) - could handle as general query")
                
                elif agent_name == "code":
                    if score > 0.7:
                        explanations.append(f"- Code agent: High confidence ({score:.2f}) - detected programming/technical content")
                    else:
                        explanations.append(f"- Code agent: Moderate confidence ({score:.2f}) - some technical indicators present")
                
                elif agent_name == "codriver":
                    if score > 0.8:
                        explanations.append(f"- CoDriver: High confidence ({score:.2f}) - complex task requiring coordination")
                    else:
                        explanations.append(f"- CoDriver: Moderate confidence ({score:.2f}) - can coordinate if needed")
        
        # Final routing decision
        if scores[best_agent] >= self.confidence_threshold:
            explanations.append(f"→ Would route directly to {best_agent}")
        else:
            explanations.append(f"→ Would route to CoDriver for coordination (best agent confidence below threshold)")
        
        return "\n".join(explanations)
    
    async def test_agent_response(self, agent_name: str, message: str, 
                                context: str = "") -> AgentResponse:
        """Test how a specific agent would respond (for debugging)"""
        if agent_name not in self.agents:
            raise ValueError(f"Agent {agent_name} not found")
        
        agent_context = AgentContext(
            conversation_id="test",
            user_id="test",
            message=message,
            conversation_history=context,
            agent_type=AgentType(agent_name)
        )
        
        agent = self.agents[agent_name]
        return await agent.process_message(agent_context)
    
    def get_agent_debug_info(self) -> Dict:
        """Get debug information about all agents"""
        debug_info = {
            "router_config": {
                "default_agent": self.default_agent,
                "confidence_threshold": self.confidence_threshold,
                "total_agents": len(self.agents)
            },
            "agents": {}
        }
        
        for name, agent in self.agents.items():
            debug_info["agents"][name] = agent.get_debug_info()
        
        return debug_info

# Global agent router instance
agent_router = AgentRouter()