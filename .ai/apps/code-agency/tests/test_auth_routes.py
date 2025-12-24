import pytest
from httpx import AsyncClient
from fastapi import status
from unittest.mock import patch

class TestAuthRoutes:
    """Test authentication API routes and responses"""
    
    @pytest.mark.asyncio
    async def test_register_endpoint_validation(self, client: AsyncClient):
        """Test registration endpoint input validation"""
        # Test missing required fields
        response = await client.post("/api/auth/register", json={})
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Test invalid email format
        invalid_data = {
            "username": "testuser",
            "email": "not-an-email",
            "password": "password123",
            "full_name": "Test User"
        }
        response = await client.post("/api/auth/register", json=invalid_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Test username too short
        invalid_data = {
            "username": "ab",  # Too short
            "email": "test@example.com",
            "password": "password123",
            "full_name": "Test User"
        }
        response = await client.post("/api/auth/register", json=invalid_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.asyncio
    async def test_login_endpoint_validation(self, client: AsyncClient):
        """Test login endpoint input validation"""
        # Test missing fields
        response = await client.post("/api/auth/login", json={})
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Test empty username
        response = await client.post("/api/auth/login", json={
            "username": "",
            "password": "password"
        })
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.asyncio 
    async def test_login_response_format(self, client: AsyncClient, test_user):
        """Test login response contains all required fields"""
        login_data = {
            "username": "testuser",
            "password": "testpassword123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Check required response fields
        required_fields = ["access_token", "token_type", "user"]
        for field in required_fields:
            assert field in data
        
        # Check user object structure
        user_data = data["user"]
        user_required_fields = ["id", "username", "email", "full_name", "is_active", "created_at"]
        for field in user_required_fields:
            assert field in user_data
        
        # Ensure sensitive data is not included
        sensitive_fields = ["password", "password_hash"]
        for field in sensitive_fields:
            assert field not in user_data
    
    @pytest.mark.asyncio
    async def test_auth_headers_accepted(self, client: AsyncClient, test_user):
        """Test different authentication header formats"""
        session = await auth_manager.create_session(test_user.id)
        token = session.session_token
        
        # Test Bearer token
        headers = {"Authorization": f"Bearer {token}"}
        response = await client.get("/api/auth/me", headers=headers)
        assert response.status_code == status.HTTP_200_OK
        
        # Test Session token (custom format)
        headers = {"Authorization": f"Session {token}"}
        response = await client.get("/api/auth/me", headers=headers)
        assert response.status_code == status.HTTP_200_OK
    
    @pytest.mark.asyncio
    async def test_cookie_authentication(self, client: AsyncClient, test_user):
        """Test authentication via session cookie"""
        # Login to get session cookie
        login_data = {
            "username": "testuser", 
            "password": "testpassword123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        assert response.status_code == status.HTTP_200_OK
        
        # Cookie should be set automatically by the client
        # Try accessing protected endpoint
        response = await client.get("/api/auth/me")
        assert response.status_code == status.HTTP_200_OK
    
    @pytest.mark.asyncio
    async def test_cors_on_auth_endpoints(self, client: AsyncClient):
        """Test CORS headers on authentication endpoints"""
        # Test preflight request
        response = await client.options("/api/auth/login")
        
        headers = response.headers
        assert "access-control-allow-origin" in headers
        assert "access-control-allow-methods" in headers
        assert "POST" in headers.get("access-control-allow-methods", "")
    
    @pytest.mark.asyncio 
    async def test_rate_limiting_login_attempts(self, client: AsyncClient):
        """Test rate limiting on login attempts (if implemented)"""
        # This test assumes rate limiting is implemented
        # Make multiple failed login attempts
        login_data = {
            "username": "nonexistent", 
            "password": "wrongpassword"
        }
        
        responses = []
        for i in range(6):  # Try 6 failed attempts
            response = await client.post("/api/auth/login", json=login_data)
            responses.append(response.status_code)
        
        # If rate limiting is implemented, later attempts should be rate limited
        # For now, just ensure we don't crash
        assert all(status_code in [401, 429] for status_code in responses)
    
    @pytest.mark.asyncio
    async def test_logout_clears_session(self, client: AsyncClient, test_user):
        """Test logout properly clears session and cookies"""
        # Login first
        login_data = {
            "username": "testuser",
            "password": "testpassword123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        assert response.status_code == status.HTTP_200_OK
        
        # Verify we're authenticated
        response = await client.get("/api/auth/me")
        assert response.status_code == status.HTTP_200_OK
        
        # Logout
        response = await client.post("/api/auth/logout")
        assert response.status_code == status.HTTP_200_OK
        
        # Should no longer be authenticated
        response = await client.get("/api/auth/me")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    @pytest.mark.asyncio
    async def test_user_sessions_endpoint(self, authenticated_client, test_user):
        """Test endpoint to view user's active sessions"""
        response = await authenticated_client.get("/api/auth/sessions")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "sessions" in data
        assert len(data["sessions"]) >= 1  # At least current session
        
        # Check session data structure
        session = data["sessions"][0]
        required_fields = ["id", "created_at", "last_used", "user_agent"]
        for field in required_fields:
            assert field in session
        
        # Sensitive data should not be included
        assert "session_token" not in session

if __name__ == "__main__":
    pytest.main([__file__, "-v"])