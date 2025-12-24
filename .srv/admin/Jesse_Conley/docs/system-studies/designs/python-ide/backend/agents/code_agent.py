import logging
import re
from typing import List, Dict, Any

from .base import BaseAgent, AgentType, AgentContext, AgentResponse
from ..inference.generator import text_generator
from ..inference.sampler import SamplingConfig
from ..ide.file_manager import file_manager

logger = logging.getLogger(__name__)

class CodeAgent(BaseAgent):
    """Programming and code assistance agent."""

    def __init__(self):
        super().__init__(AgentType.CODE, "CodeAgent")
        self.supported_languages = [
            "python", "javascript", "typescript", "rust", "go", "java",
            "cpp", "c", "html", "css", "sql", "bash", "yaml", "json"
        ]

    def _get_system_prompt(self) -> str:
        return """You are an expert programming assistant. You excel at writing, debugging, and explaining code.
Always follow best practices, include comments, and consider error handling. Reference workspace files when relevant."""

    def _define_capabilities(self) -> List[str]:
        return [
            "code_writing",
            "debugging",
            "code_review",
            "refactoring",
            "algorithm_design",
            "architecture_advice",
            "testing_strategies",
            "documentation",
            "performance_optimization",
            "best_practices"
        ]

    def can_handle(self, message: str, context: AgentContext) -> float:
        """Determine confidence for coding requests."""
        message_lower = message.lower()
        confidence = 0.3

        high_patterns = [
            r'\b(code|function|class|method|variable)\b',
            r'\b(debug|error|bug|fix|syntax)\b', 
            r'\b(write|create|build|implement)\b.*\b(function|class|script)\b',
            r'\b(optimize|refactor|improve)\b.*\b(code|function)\b',
            r'\b(algorithm|data structure)\b',
            r'```.*```',
            r'\.(py|js|ts|rs|go|java|cpp|c|html|css|sql)$'
        ]
        for p in high_patterns:
            if re.search(p, message_lower):
                confidence += 0.2

        programming_keywords = [
            "import", "export", "class", "def", "function", "var", "let", "const",
            "if", "else", "for", "while", "try", "catch", "async", "await",
            "return", "yield", "break", "continue", "lambda", "map", "filter",
            "api", "database", "server", "client", "framework", "library",
            "git", "commit", "push", "pull", "merge", "branch"
        ]
        keyword_matches = sum(1 for k in programming_keywords if k in message_lower)
        confidence += min(keyword_matches * 0.1, 0.3)

        language_terms = [
            "python", "javascript", "typescript", "rust", "golang", "java",
            "react", "vue", "angular", "django", "flask", "fastapi", "nodejs",
            "sql", "mongodb", "postgresql", "redis", "docker", "kubernetes"
        ]
        language_matches = sum(1 for t in language_terms if t in message_lower)
        confidence += min(language_matches * 0.15, 0.2)

        if any(ext in message_lower for ext in ['.py', '.js', '.ts', '.rs', '.go', '.java']):
            confidence += 0.2

        non_technical = ["what is", "explain", "tell me about", "general", "opinion"]
        if any(phrase in message_lower for phrase in non_technical) and not any(k in message_lower for k in programming_keywords):
            confidence -= 0.2

        return max(0.1, min(1.0, confidence))

    async def process_message(self, context: AgentContext) -> AgentResponse:
        """Process coding request with context and code-optimized sampling."""
        try:
            file_context = await self._get_file_context(context.message)
            prompt = self._build_code_prompt(context, file_context)
            sampling_config = SamplingConfig.for_code()

            response = text_generator.generate_response(
                prompt,
                **sampling_config.to_dict()
            )
            response = self.post_process_response(response, context)

            if not self.validate_response(response):
                logger.warning("Code agent generated poor quality response")
                response = "I'm having trouble generating a good code response. Please provide more details."

            metadata = self._extract_code_metadata(response)
            metadata.update(self.extract_metadata(response))
            confidence = self._calculate_code_confidence(response, context)
            suggestions = self._generate_suggestions(response, context)

            return AgentResponse(
                content=response,
                agent_type=self.agent_type,
                confidence=confidence,
                reasoning="Processed as coding/technical request",
                suggestions=suggestions,
                metadata=metadata
            )

        except Exception as e:
            logger.error(f"Code agent error: {e}")
            return AgentResponse(
                content="Error processing your coding request. Try providing more details.",
                agent_type=self.agent_type,
                confidence=0.0,
                metadata={"error": str(e)}
            )

    async def _get_file_context(self, message: str) -> Dict[str, Any]:
        """Retrieve relevant workspace files and project structure."""
        file_context = {"files": [], "project_structure": None}
        patterns = [r'(\w+\.\w+)', r'`([^`]+\.\w+)`', r'"([^"]+\.\w+)"']
        referenced_files = [m for pattern in patterns for m in re.findall(pattern, message)]

        for filename in referenced_files[:3]:
            try:
                file_data = file_manager.read_file(filename)
                if file_data.get("content") and not file_data.get("is_binary", False):
                    file_context["files"].append({
                        "name": filename,
                        "content": file_data["content"][:2000],
                        "language": file_data.get("language", "text")
                    })
            except Exception as e:
                logger.debug(f"Could not read file {filename}: {e}")

        if not file_context["files"]:
            try:
                tree = file_manager.get_file_tree("", max_depth=2)
                if not tree.get("error"):
                    file_context["project_structure"] = tree
            except Exception as e:
                logger.debug(f"Could not get project structure: {e}")

        return file_context

    def _build_code_prompt(self, context: AgentContext, file_context: Dict[str, Any]) -> str:
        """Build prompt including system, file context, and conversation."""
        parts = [f"System: {self.system_prompt}"]

        if file_context["files"]:
            parts.append("Current workspace files:")
            for f in file_context["files"]:
                parts.append(f"File: {f['name']} ({f['language']})")
                parts.append(f"```{f['language']}\n{f['content']}\n```")
        elif file_context["project_structure"]:
            parts.append("Project structure:")
            parts.append(self._format_tree_structure(file_context["project_structure"]))

        if context.conversation_history:
            parts.append("Previous conversation:")
            parts.append(context.conversation_history)

        parts.append(f"Human: {context.message}")
        parts.append("Assistant:")

        return "\n\n".join(parts)

    def _format_tree_structure(self, tree: Dict[str, Any], indent: int = 0) -> str:
        """Format a file tree for the prompt."""
        prefix = "  " * indent
        lines = []

        if tree.get("type") == "directory":
            lines.append(f"{prefix}{tree['name']}/")
            for child in tree.get("children", [])[:10]:
                lines.extend(self._format_tree_structure(child, indent + 1).split("\n"))
        else:
            lines.append(f"{prefix}{tree['name']}")

        return "\n".join(lines)

    def _extract_code_metadata(self, response: str) -> Dict[str, Any]:
        """Extract code-specific info from response."""
        metadata = {}
        code_blocks = re.findall(r'```(\w+)?\n(.*?)```', response, re.DOTALL)
        if code_blocks:
            metadata["code_blocks"] = len(code_blocks)
            metadata["languages_used"] = [lang for lang, _ in code_blocks if lang]

        concepts = {
            "functions": len(re.findall(r'\b(def|function|func)\s+\w+', response)),
            "classes": len(re.findall(r'\b(class|struct)\s+\w+', response)),
            "imports": len(re.findall(r'\b(import|from|#include|use)\s+', response)),
            "error_handling": len(re.findall(r'\b(try|catch|except|Result|Option)\b', response)),
            "async_code": len(re.findall(r'\b(async|await|Promise)\b', response))
        }
        metadata["programming_concepts"] = {k: v for k, v in concepts.items() if v > 0}
        return metadata

    def _calculate_code_confidence(self, response: str, context: AgentContext) -> float:
        confidence = 0.7
        if "```" in response:
            confidence += 0.2
        markers = ["because", "this", "here", "step", "first", "then", "finally"]
        confidence += min(sum(0.05 for m in markers if m in response.lower()), 0.15)
        if any(p in response.lower() for p in ["might work", "try this", "not sure"]):
            confidence -= 0.1
        if any(p in response.lower() for p in ["best practice", "recommended", "should", "important"]):
            confidence += 0.1
        return max(0.1, min(1.0, confidence))

    def _generate_suggestions(self, response: str, context: AgentContext) -> List[str]:
        suggestions = []
        msg_lower = context.message.lower()

        if "```" in response:
            suggestions.append("Would you like me to explain any part of this code?")
            suggestions.append("Need help with testing this code?")
        if "error" in msg_lower or "bug" in msg_lower:
            suggestions.append("Would you like me to help debug this step by step?")
            suggestions.append("Need help setting up error handling?")
        if any(w in msg_lower for w in ["optimize", "improve", "better"]):
            suggestions.append("Want me to suggest performance improvements?")
            suggestions.append("Should we discuss alternative approaches?")

        return suggestions[:3]


# Global instance
code_agent = CodeAgent()
