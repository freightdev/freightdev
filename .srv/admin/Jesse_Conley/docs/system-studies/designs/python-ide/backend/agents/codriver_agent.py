import logging
from typing import List, Dict, Any, Optional

from .base import BaseAgent, AgentType, AgentContext, AgentResponse
from .chat_agent import chat_agent
from .code_agent import code_agent
from ..inference.generator import text_generator
from ..inference.sampler import SamplingConfig

logger = logging.getLogger(__name__)

class CoDriverAgent(BaseAgent):
    """Meta-agent that coordinates other agents and manages complex tasks"""
    
    def __init__(self):
        super().__init__(AgentType.CODRIVER, "CoDriver")
        self.sub_agents = {
            "chat": chat_agent,
            "code": code_agent
        }
        self.conversation_context = {}
    
    def _get_system_prompt(self) -> str:
        return """You are CoDriver, a meta-agent that coordinates AI assistance. Your role is to:

- Analyze complex requests that might need multiple types of expertise
- Coordinate between different specialized agents (chat, code)
- Maintain context across multi-step conversations
- Provide project-level guidance and planning
- Help break down complex tasks into manageable steps
- Ensure all agents stay aligned with user goals

You should:
- Route simple requests to appropriate specialized agents
- Handle complex multi-step tasks yourself
- Coordinate when a task needs both conversational and technical expertise
- Keep track of project context and long-term goals
- Provide high-level guidance and planning

You are the primary interface - users talk to you, and you manage the other agents."""

    def _define_capabilities(self) -> List[str]:
        return [
            "task_coordination",
            "agent_management", 
            "project_planning",
            "complex_reasoning",
            "context_management",
            "multi_step_tasks",
            "goal_alignment",
            "strategic_thinking"
        ]
    
    def can_handle(self, message: str, context: AgentContext) -> float:
        """CoDriver can handle anything, but with varying confidence"""
        message_lower = message.lower()
        
        # High confidence for coordination requests
        coordination_patterns = [
            "help me", "plan", "strategy", "approach", "steps", "process",
            "manage", "organize", "coordinate", "break down", "analyze",
            "what should i", "how do i", "best way", "recommend"
        ]
        
        # High confidence for complex multi-part requests
        complex_patterns = [
            "and", "then", "also", "plus", "additionally", "furthermore",
            "first", "second", "finally", "step by step"
        ]
        
        # Detect if other agents might be more specialized
        chat_score = chat_agent.can_handle(message, context)
        code_score = code_agent.can_handle(message, context)
        
        base_confidence = 0.6
        
        # Boost for coordination language
        coord_matches = sum(1 for pattern in coordination_patterns 
                          if pattern in message_lower)
        base_confidence += min(coord_matches * 0.1, 0.2)
        
        # Boost for complex requests
        complex_matches = sum(1 for pattern in complex_patterns 
                            if pattern in message_lower)
        base_confidence += min(complex_matches * 0.05, 0.15)
        
        # If other agents are highly confident, reduce CoDriver confidence
        if chat_score > 0.8 or code_score > 0.8:
            base_confidence *= 0.7
        
        # But if it's a complex request, CoDriver should handle coordination
        if coord_matches > 2 or complex_matches > 2:
            base_confidence = max(base_confidence, 0.8)
        
        return max(0.3, min(1.0, base_confidence))
    
    async def process_message(self, context: AgentContext) -> AgentResponse:
        """Process message and coordinate with other agents if needed"""
        try:
            # Analyze the request complexity
            analysis = self._analyze_request(context)
            
            if analysis["complexity"] == "simple":
                # Route to most appropriate specialized agent
                return await self._route_to_specialist(context, analysis)
            
            elif analysis["complexity"] == "moderate":
                # Handle with consultation from specialists
                return await self._handle_with_consultation(context, analysis)
            
            else:  # complex
                # Handle as multi-step coordinated task
                return await self._handle_complex_task(context, analysis)
                
        except Exception as e:
            logger.error(f"CoDriver error: {e}")
            return AgentResponse(
                content="I encountered an error while coordinating your request. Let me try a different approach.",
                agent_type=self.agent_type,
                confidence=0.0,
                metadata={"error": str(e)}
            )
    
    def _analyze_request(self, context: AgentContext) -> Dict[str, Any]:
        """Analyze the complexity and nature of the request"""
        message = context.message.lower()
        
        # Count complexity indicators
        complexity_indicators = {
            "multiple_tasks": len([word for word in ["and", "then", "also", "plus"] if word in message]),
            "planning_words": len([word for word in ["plan", "strategy", "approach", "steps"] if word in message]),
            "question_marks": message.count("?"),
            "sentence_count": len([s for s in message.split(".") if s.strip()]),
            "coordination_needed": any(word in message for word in ["coordinate", "manage", "organize"])
        }
        
        # Determine complexity
        complexity_score = (
            complexity_indicators["multiple_tasks"] * 2 +
            complexity_indicators["planning_words"] * 1.5 +
            complexity_indicators["question_marks"] * 0.5 +
            complexity_indicators["sentence_count"] * 0.3
        )
        
        if complexity_score < 2:
            complexity = "simple"
        elif complexity_score < 5:
            complexity = "moderate" 
        else:
            complexity = "complex"
        
        # Determine best specialist agents
        chat_confidence = chat_agent.can_handle(context.message, context)
        code_confidence = code_agent.can_handle(context.message, context)
        
        return {
            "complexity": complexity,
            "complexity_score": complexity_score,
            "indicators": complexity_indicators,
            "best_specialist": "code" if code_confidence > chat_confidence else "chat",
            "specialist_scores": {"chat": chat_confidence, "code": code_confidence}
        }
    
    async def _route_to_specialist(self, context: AgentContext, analysis: Dict) -> AgentResponse:
        """Route simple request to best specialist agent"""
        specialist_name = analysis["best_specialist"]
        specialist = self.sub_agents[specialist_name]
        
        logger.info(f"CoDriver routing to {specialist_name} agent")
        
        # Get response from specialist
        response = await specialist.process_message(context)
        
        # Add CoDriver coordination metadata
        response.metadata.update({
            "coordinated_by": "codriver",
            "routed_to": specialist_name,
            "routing_confidence": analysis["specialist_scores"][specialist_name]
        })
        
        return response
    
    async def _handle_with_consultation(self, context: AgentContext, analysis: Dict) -> AgentResponse:
        """Handle moderate complexity with specialist consultation"""
        # Build enhanced prompt with specialist perspectives
        prompt = self._build_coordination_prompt(context, analysis)
        
        # Use balanced sampling for coordination
        sampling_config = SamplingConfig.for_reasoning()
        
        # Generate coordinated response
        response = text_generator.generate_response(
            prompt,
            **sampling_config.to_dict()
        )
        
        response = self.post_process_response(response, context)
        
        # Generate follow-up suggestions
        suggestions = self._generate_coordination_suggestions(context, analysis)
        
        return AgentResponse(
            content=response,
            agent_type=self.agent_type,
            confidence=0.8,
            reasoning=f"Handled as moderate complexity task with {analysis['best_specialist']} consultation",
            suggestions=suggestions,
            metadata={
                "coordination_type": "consultation",
                "complexity_analysis": analysis,
                "consulted_agents": [analysis["best_specialist"]]
            }
        )
    
    async def _handle_complex_task(self, context: AgentContext, analysis: Dict) -> AgentResponse:
        """Handle complex multi-step tasks"""
        # Break down the task into steps
        steps = self._decompose_task(context.message)
        
        # Build comprehensive coordination response
        prompt = f"""System: {self.system_prompt}

Task Analysis:
- Complexity: {analysis['complexity']}
- Multiple components detected: {analysis['indicators']['multiple_tasks']}
- Planning required: {analysis['indicators']['planning_words'] > 0}

User Request: {context.message}

Provide a comprehensive response that:
1. Acknowledges the complexity of the request
2. Breaks down the task into clear steps
3. Explains how different aspects will be handled
4. Provides initial guidance for getting started
5. Optionally suggest which sub-agent(s) should handle each step"""

        # Use reasoning-focused sampling
        sampling_config = SamplingConfig.for_reasoning(max_tokens=1024)
        
        # Generate coordinated response
        raw_response = text_generator.generate_response(
            prompt,
            **sampling_config.to_dict()
        )
        
        # Post-process the raw response to normalize formatting and context
        response_content = self.post_process_response(raw_response, context)
        
        # Determine which sub-agent should handle each step if possible
        step_assignments = self._assign_steps_to_agents(steps)
        
        # Build metadata with full coordination details
        metadata = {
            "coordination_type": "complex_task",
            "complexity_analysis": analysis,
            "steps": steps,
            "step_assignments": step_assignments,
            "handled_by_codriver": True
        }
        
        return AgentResponse(
            content=response_content,
            agent_type=self.agent_type,
            confidence=0.95,
            reasoning="Handled as complex multi-step task with coordinated planning",
            suggestions=[f"Step '{s}' can be executed by {step_assignments.get(s, 'codriver')}." for s in steps],
            metadata=metadata
        )

    def _decompose_task(self, message: str) -> List[str]:
        """Break a complex message into manageable steps"""
        # Simple heuristic: split on conjunctions and sentence boundaries
        import re
        steps = re.split(r'\b(?:and|then|also|plus|furthermore|first|second|finally|step by step)\b|[.!?]', message)
        steps = [s.strip() for s in steps if s.strip()]
        return steps

    def _assign_steps_to_agents(self, steps: List[str]) -> Dict[str, str]:
        """Assign each step to the most appropriate agent"""
        assignments = {}
        for step in steps:
            chat_score = chat_agent.can_handle(step, AgentContext(step))
            code_score = code_agent.can_handle(step, AgentContext(step))
            if code_score > chat_score:
                assignments[step] = "code"
            else:
                assignments[step] = "chat"
        return assignments

    def _build_coordination_prompt(self, context: AgentContext, analysis: Dict) -> str:
        """Construct a prompt for moderate complexity tasks"""
        return f"""System: {self.system_prompt}

Moderate Task Analysis:
- Complexity: {analysis['complexity']}
- Indicators: {analysis['indicators']}

User Request: {context.message}

Provide a response that leverages the {analysis['best_specialist']} agent's perspective while keeping overall coordination and context management in mind."""
    
    def _generate_coordination_suggestions(self, context: AgentContext, analysis: Dict) -> List[str]:
        """Generate actionable suggestions for moderate complexity tasks"""
        suggestions = [
            f"Consult {analysis['best_specialist']} agent for detailed insights",
            "Break down the request into sub-tasks if possible",
            "Maintain context across steps",
            "Document each step to ensure alignment with overall goals"
        ]
        return suggestions
