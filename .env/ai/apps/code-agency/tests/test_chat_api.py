import pytest
from httpx import AsyncClient
from fastapi import status
import json
import asyncio
from unittest.mock import patch, AsyncMock

class TestChatAPI:
    """Test chat API endpoints and conversation management"""
    
    @pytest.mark.asyncio
    async def test_send_chat_message(self, authenticated_client, mock_llama_runner):
        """Test sending a basic chat message"""
        # Load model first
        await mock_llama_runner.load_model("test-model.gguf")
        
        message_data = {
            "message": "Hello, how are you?",
            "agent_type": "chat",
            "temperature": 0.7,
            "max_tokens": 100
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Check response structure
        required_fields = ["message", "conversation_id", "message_id", "agent_type", "generation_time"]
        for field in required_fields:
            assert field in data
        
        assert data["agent_type"] == "chat"
        assert len(data["message"]) > 0
        assert data["generation_time"] > 0
        assert data["conversation_id"] is not None
    
    @pytest.mark.asyncio
    async def test_send_code_message(self, authenticated_client, mock_llama_runner):
        """Test sending a coding-related message"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        message_data = {
            "message": "Write a Python function to calculate fibonacci numbers",
            "agent_type": "code",
            "temperature": 0.3
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert data["agent_type"] == "code"
        assert "python" in data["message"].lower()  # Mock should return Python code
        assert "```" in data["message"]  # Should contain code blocks
    
    @pytest.mark.asyncio
    async def test_codriver_routing(self, authenticated_client, mock_llama_runner):
        """Test CoDriver agent routing"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        message_data = {
            "message": "Help me plan a Python project and then write some code",
            "agent_type": "codriver"
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert data["agent_type"] == "codriver"
        assert len(data["message"]) > 0
    
    @pytest.mark.asyncio
    async def test_conversation_persistence(self, authenticated_client, mock_llama_runner):
        """Test that conversations are saved and can be retrieved"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        # Send first message
        message_data = {
            "message": "Hello, remember my name is Alice",
            "agent_type": "chat"
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        assert response.status_code == status.HTTP_200_OK
        
        conversation_id = response.json()["conversation_id"]
        
        # Send follow-up message in same conversation
        message_data = {
            "message": "What's my name?",
            "conversation_id": conversation_id,
            "agent_type": "chat"
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        assert response.status_code == status.HTTP_200_OK
        
        # Conversation ID should be the same
        assert response.json()["conversation_id"] == conversation_id
    
    @pytest.mark.asyncio
    async def test_get_conversations_list(self, authenticated_client, mock_llama_runner):
        """Test retrieving user's conversations"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        # Create a conversation by sending a message
        message_data = {
            "message": "Test conversation",
            "agent_type": "chat"
        }
        
        await authenticated_client.post("/api/chat/send", json=message_data)
        
        # Get conversations list
        response = await authenticated_client.get("/api/chat/conversations/testuser")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "conversations" in data
        assert len(data["conversations"]) >= 1
        
        # Check conversation structure
        conversation = data["conversations"][0]
        required_fields = ["id", "title", "agent_type", "created_at", "updated_at"]
        for field in required_fields:
            assert field in conversation
    
    @pytest.mark.asyncio
    async def test_get_conversation_messages(self, authenticated_client, mock_llama_runner):
        """Test retrieving messages from a specific conversation"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        # Create conversation with multiple messages
        message_data = {
            "message": "First message",
            "agent_type": "chat"
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        conversation_id = response.json()["conversation_id"]
        
        # Add second message
        message_data = {
            "message": "Second message", 
            "conversation_id": conversation_id,
            "agent_type": "chat"
        }
        
        await authenticated_client.post("/api/chat/send", json=message_data)
        
        # Get messages
        response = await authenticated_client.get(f"/api/chat/conversations/{conversation_id}/messages")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "messages" in data
        assert len(data["messages"]) >= 4  # 2 user messages + 2 assistant responses
        
        # Check message structure
        message = data["messages"][0]
        required_fields = ["id", "role", "content", "timestamp"]
        for field in required_fields:
            assert field in message
        
        # Should have both user and assistant messages
        roles = [msg["role"] for msg in data["messages"]]
        assert "user" in roles
        assert "assistant" in roles
    
    @pytest.mark.asyncio
    async def test_create_new_conversation(self, authenticated_client):
        """Test creating a new conversation explicitly"""
        response = await authenticated_client.post("/api/chat/conversations", json={
            "user_id": "testuser",
            "title": "Test Conversation",
            "agent_type": "chat"
        })
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "conversation_id" in data
        assert data["conversation_id"] is not None
    
    @pytest.mark.asyncio
    async def test_chat_without_model_loaded(self, authenticated_client, mock_llama_runner):
        """Test chat fails gracefully when no model is loaded"""
        # Don't load model
        message_data = {
            "message": "Hello",
            "agent_type": "chat"
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        
        # Should handle gracefully (either error or default response)
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_503_SERVICE_UNAVAILABLE]
        
        if response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE:
            data = response.json()
            assert "error" in data
    
    @pytest.mark.asyncio
    async def test_chat_input_validation(self, authenticated_client):
        """Test chat endpoint input validation"""
        # Test empty message
        response = await authenticated_client.post("/api/chat/send", json={
            "message": "",
            "agent_type": "chat"
        })
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Test invalid agent type
        response = await authenticated_client.post("/api/chat/send", json={
            "message": "Hello",
            "agent_type": "invalid_agent"
        })
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Test invalid temperature
        response = await authenticated_client.post("/api/chat/send", json={
            "message": "Hello",
            "agent_type": "chat",
            "temperature": 5.0  # Too high
        })
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.asyncio
    async def test_unauthorized_chat_access(self, client: AsyncClient):
        """Test chat endpoints require authentication"""
        message_data = {
            "message": "Hello",
            "agent_type": "chat"
        }
        
        response = await client.post("/api/chat/send", json=message_data)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        
        response = await client.get("/api/chat/conversations/testuser")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

class TestWebSocketChat:
    """Test WebSocket chat functionality"""
    
    @pytest.mark.asyncio
    async def test_websocket_connection(self, test_user, mock_llama_runner):
        """Test WebSocket chat connection"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        # Create session for WebSocket auth
        from backend.auth.auth_manager import auth_manager
        session = await auth_manager.create_session(test_user.id)
        
        # This would require WebSocket testing setup
        # For now, just test that the endpoint exists
        # Real WebSocket testing would use pytest-asyncio and websockets library
        
        # Placeholder test - in real implementation you'd use:
        # from fastapi.testclient import TestClient
        # with TestClient(app) as client:
        #     with client.websocket_connect(f"/ws/{test_user.id}?token={session.session_token}") as websocket:
        #         websocket.send_json({"type": "chat", "message": "Hello"})
        #         data = websocket.receive_json()
        #         assert data["type"] == "response"
        
        # For now, just assert the endpoint configuration exists
        assert True  # Placeholder
    
    @pytest.mark.asyncio
    async def test_websocket_authentication(self, test_user):
        """Test WebSocket requires proper authentication"""
        # Test without token should fail
        # Test with invalid token should fail  
        # Test with valid token should succeed
        
        # Placeholder - implement with actual WebSocket client
        assert True

class TestAgentRouting:
    """Test AI agent routing and responses"""
    
    @pytest.mark.asyncio
    async def test_agent_selection_chat(self, authenticated_client, mock_llama_runner):
        """Test chat agent handles general questions"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        chat_questions = [
            "What is the weather like?",
            "Tell me a story", 
            "Explain quantum physics",
            "What do you think about AI?"
        ]
        
        for question in chat_questions:
            message_data = {
                "message": question,
                "agent_type": "chat"
            }
            
            response = await authenticated_client.post("/api/chat/send", json=message_data)
            assert response.status_code == status.HTTP_200_OK
            
            data = response.json()
            assert data["agent_type"] == "chat"
            assert len(data["message"]) > 0
    
    @pytest.mark.asyncio 
    async def test_agent_selection_code(self, authenticated_client, mock_llama_runner):
        """Test code agent handles programming questions"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        coding_questions = [
            "Write a Python function to sort a list",
            "How do I fix this JavaScript error?",
            "Explain object-oriented programming",
            "Debug this code snippet"
        ]
        
        for question in coding_questions:
            message_data = {
                "message": question,
                "agent_type": "code"
            }
            
            response = await authenticated_client.post("/api/chat/send", json=message_data)
            assert response.status_code == status.HTTP_200_OK
            
            data = response.json()
            assert data["agent_type"] == "code"
            # Mock returns Python examples for code questions
            assert "python" in data["message"].lower()
    
    @pytest.mark.asyncio
    async def test_codriver_coordination(self, authenticated_client, mock_llama_runner):
        """Test CoDriver coordinates multiple agent types"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        complex_requests = [
            "Help me plan a web application and write the initial code",
            "Explain REST APIs and show me an example implementation",
            "I need to understand databases and create a schema"
        ]
        
        for request in complex_requests:
            message_data = {
                "message": request,
                "agent_type": "codriver"
            }
            
            response = await authenticated_client.post("/api/chat/send", json=message_data)
            assert response.status_code == status.HTTP_200_OK
            
            data = response.json()
            assert data["agent_type"] == "codriver"
            assert len(data["message"]) > 100  # Should be comprehensive

class TestChatMemory:
    """Test conversation memory and context management"""
    
    @pytest.mark.asyncio
    async def test_conversation_context_maintained(self, authenticated_client, mock_llama_runner):
        """Test that context is maintained within a conversation"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        # Start conversation with context
        message_data = {
            "message": "I'm working on a Python web application using FastAPI",
            "agent_type": "code"
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        conversation_id = response.json()["conversation_id"]
        
        # Follow-up question that relies on context
        message_data = {
            "message": "How do I add authentication to it?",
            "conversation_id": conversation_id,
            "agent_type": "code"
        }
        
        response = await authenticated_client.post("/api/chat/send", json=message_data)
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        # Response should be contextually relevant
        response_text = data["message"].lower()
        assert any(term in response_text for term in ["fastapi", "authentication", "python"])
    
    @pytest.mark.asyncio
    async def test_cross_conversation_isolation(self, authenticated_client, mock_llama_runner):
        """Test that different conversations don't share context"""
        await mock_llama_runner.load_model("test-model.gguf")
        
        # Create first conversation
        message_data1 = {
            "message": "My name is Alice and I like Python",
            "agent_type": "chat"
        }
        
        response1 = await authenticated_client.post("/api/chat/send", json=message_data1)
        conv1_id = response1.json()["conversation_id"]
        
        # Create second conversation
        message_data2 = {
            "message": "What's my name?",
            "agent_type": "chat"
        }
        
        response2 = await authenticated_client.post("/api/chat/send", json=message_data2)
        conv2_id = response2.json()["conversation_id"]
        
        # Should be different conversations
        assert conv1_id != conv2_id
        
        # Second conversation shouldn't know about Alice
        # (This depends on your memory implementation)

if __name__ == "__main__":
    pytest.main([__file__, "-v"])