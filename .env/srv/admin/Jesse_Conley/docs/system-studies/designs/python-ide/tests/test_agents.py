import pytest
from httpx import AsyncClient
from fastapi import status
from backend.agents.chat_agent import chat_agent
from backend.agents.code_agent import code_agent
from backend.agents.codriver import CoDriverAgent
from backend.agents.base import AgentContext, AgentType
from unittest.mock import AsyncMock, patch

class TestAgentSystem:
    """Test the AI agent system and routing"""
    
    @pytest.mark.asyncio
    async def test_chat_agent_initialization(self):
        """Test chat agent initializes correctly"""
        assert chat_agent.agent_type == AgentType.CHAT
        assert chat_agent.name == "ChatAgent"
        assert len(chat_agent.capabilities) > 0
        assert chat_agent.system_prompt is not None
        assert len(chat_agent.system_prompt) > 50
    
    @pytest.mark.asyncio
    async def test_code_agent_initialization(self):
        """Test code agent initializes correctly"""
        assert code_agent.agent_type == AgentType.CODE
        assert code_agent.name == "CodeAgent"
        assert "code_writing" in code_agent.capabilities
        assert "debugging" in code_agent.capabilities
        assert len(code_agent.supported_languages) > 5
    
    @pytest.mark.asyncio
    async def test_codriver_initialization(self):
        """Test CoDriver agent initializes correctly"""
        codriver = CoDriverAgent()
        assert codriver.agent_type == AgentType.CODRIVER
        assert codriver.name == "CoDriver"
        assert "task_coordination" in codriver.capabilities
        assert len(codriver.sub_agents) >= 2
    
    @pytest.mark.asyncio
    async def test_agent_confidence_scoring(self):
        """Test agents correctly score message confidence"""
        chat_context = AgentContext(
            conversation_id="test-conv",
            user_id="test-user",
            message="What is the weather like today?",
            conversation_history="",
            agent_type=AgentType.CHAT
        )
        
        code_context = AgentContext(
            conversation_id="test-conv",
            user_id="test-user", 
            message="Write a Python function to sort a list",
            conversation_history="",
            agent_type=AgentType.CODE
        )
        
        # Chat agent should be more confident with general questions
        chat_confidence_for_chat = chat_agent.can_handle("What is the weather?", chat_context)
        chat_confidence_for_code = chat_agent.can_handle("Write a Python function", chat_context)
        
        assert chat_confidence_for_chat > chat_confidence_for_code
        
        # Code agent should be more confident with programming questions
        code_confidence_for_code = code_agent.can_handle("Write a Python function", code_context)
        code_confidence_for_chat = code_agent.can_handle("What is the weather?", code_context)
        
        assert code_confidence_for_code > code_confidence_for_chat
    
    @pytest.mark.asyncio
    @patch('backend.inference.generator.text_generator.generate_response')
    async def test_chat_agent_response_generation(self, mock_generate):
        """Test chat agent generates appropriate responses"""
        mock_generate.return_value = "This is a helpful response about the weather."
        
        context = AgentContext(
            conversation_id="test-conv",
            user_id="test-user",
            message="What is the weather like?",
            conversation_history="",
            agent_type=AgentType.CHAT
        )
        
        response = await chat_agent.process_message(context)
        
        assert response.agent_type == AgentType.CHAT
        assert response.content == "This is a helpful response about the weather."
        assert response.confidence > 0.0
        assert mock_generate.called
    
    @pytest.mark.asyncio
    @patch('backend.inference.generator.text_generator.generate_response')
    async def test_code_agent_response_generation(self, mock_generate):
        """Test code agent generates code-focused responses"""
        mock_generate.return_value = """Here's a Python function to sort a list:

```python
def sort_list(items):
    This function takes a list and returns a new sorted list."""
    return sorted(items)
    context = AgentContext(
        conversation_id="test-conv",
        user_id="test-user",
        message="Write a Python function to sort a list",
        conversation_history="",
        agent_type=AgentType.CODE
    )
    
    response = await code_agent.process_message(context)
    
    assert response.agent_type == AgentType.CODE
    assert "```python" in response.content
    assert "def sort_list" in response.content
    assert response.metadata.get("contains_code") is True
    assert mock_generate.called

@pytest.mark.asyncio
@patch('backend.inference.generator.text_generator.generate_response')
async def test_codriver_coordination(self, mock_generate):
    """Test CoDriver agent coordination"""
    mock_generate.return_value = "I'll help you plan this project step by step."
    
    codriver = CoDriverAgent()
    context = AgentContext(
        conversation_id="test-conv",
        user_id="test-user",
        message="Help me build a web application with user authentication",
        conversation_history="",
        agent_type=AgentType.CODRIVER
    )
    
    response = await codriver.process_message(context)
    
    assert response.agent_type == AgentType.CODRIVER
    assert len(response.content) > 0
    assert response.confidence > 0.0

@pytest.mark.asyncio
async def test_agent_prompt_building(self):
    """Test agents build prompts correctly"""
    context = AgentContext(
        conversation_id="test-conv",
        user_id="test-user",
        message="Hello, how are you?",
        conversation_history="Human: Hi there!\nAssistant: Hello! How can I help you today?",
        agent_type=AgentType.CHAT
    )
    
    prompt = chat_agent.build_prompt(context)
    
    assert "System:" in prompt
    assert context.message in prompt
    assert "Human: Hi there!" in prompt  # Previous history
    assert "Assistant:" in prompt
    assert len(prompt) > 100

@pytest.mark.asyncio
async def test_agent_response_validation(self):
    """Test agents validate their responses"""
    # Test valid response
    valid_response = "This is a helpful and informative response."
    assert chat_agent.validate_response(valid_response) is True
    
    # Test empty response
    assert chat_agent.validate_response("") is False
    assert chat_agent.validate_response("   ") is False
    
    # Test repetitive response
    repetitive = "word word word word word word word word word word"
    assert chat_agent.validate_response(repetitive) is False

@pytest.mark.asyncio
async def test_agent_metadata_extraction(self):
    """Test agents extract metadata correctly"""
    response_with_code = """Here's a Python example:
    def hello():
    print("Hello World")
    This is a simple function."""

    metadata = code_agent.extract_metadata(response_with_code)
    
    assert metadata["contains_code"] is True
    assert metadata["code_blocks"] == 1
    assert "python" in metadata.get("languages_used", [])
    assert metadata["agent_type"] == "code"
    assert "response_length" in metadata


@pytest.mark.asyncio
async def test_agent_router_initialization(self):
    """Test agent router initializes with all agents"""
    from backend.agents.router import agent_router
    
    assert "chat" in agent_router.agents
    assert "code" in agent_router.agents
    assert "codriver" in agent_router.agents
    assert agent_router.default_agent == "codriver"

@pytest.mark.asyncio
@patch('backend.inference.generator.text_generator.generate_response')
async def test_automatic_agent_routing(self, mock_generate):
    """Test router automatically selects appropriate agent"""
    from backend.agents.router import agent_router
    
    mock_generate.return_value = "This is a test response"
    
    # Test chat routing
    chat_response = await agent_router.route_message(
        "What's the weather like?",
        context="",
        user_id="test-user"
    )
    
    assert len(chat_response) > 0
    
    # Test code routing  
    code_response = await agent_router.route_message(
        "Write a Python function to calculate fibonacci",
        context="",
        user_id="test-user"
    )
    
    assert len(code_response) > 0

@pytest.mark.asyncio
async def test_explicit_agent_selection(self):
    """Test explicitly specifying which agent to use"""
    from backend.agents.router import agent_router
    
    with patch.object(agent_router.agents["chat"], "process_message", new_callable=AsyncMock) as mock_chat:
        mock_chat.return_value.content = "Chat response"
        
        response = await agent_router.route_message(
            "Hello",
            agent_type="chat",
            user_id="test-user"
        )
        
        assert mock_chat.called
        assert response == "Chat response"

@pytest.mark.asyncio
async def test_router_confidence_analysis(self):
    """Test router analyzes agent confidence correctly"""
    from backend.agents.router import agent_router
    
    # Analyze general question
    scores = agent_router.analyze_message("What is artificial intelligence?")
    
    assert "chat" in scores
    assert "code" in scores
    assert "codriver" in scores
    assert all(0.0 <= score <= 1.0 for score in scores.values())
    
    # Chat should have higher confidence for general questions
    assert scores["chat"] >= scores["code"]
    
    # Analyze coding question
    coding_scores = agent_router.analyze_message("Write a Python web scraper")
    
    # Code agent should have higher confidence
    assert coding_scores["code"] >= coding_scores["chat"]

@pytest.mark.asyncio
async def test_routing_explanation(self):
    """Test router can explain its routing decisions"""
    from backend.agents.router import agent_router
    
    explanation = agent_router.get_routing_explanation(
        "Write a Python function to sort data"
    )
    
    assert "message" in explanation
    assert "all_scores" in explanation
    assert "recommended_agent" in explanation
    assert "confidence" in explanation
    assert "explanation" in explanation
    
    # Should recommend code agent for programming question
    assert explanation["recommended_agent"] in ["code", "codriver"]

if name == "main":
    pytest.main([file, "-v"])
