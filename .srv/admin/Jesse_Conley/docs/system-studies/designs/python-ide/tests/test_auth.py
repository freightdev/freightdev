import pytest
from httpx import AsyncClient
from fastapi import status
import uuid
from datetime import datetime, timedelta

from backend.auth.models import User, UserSession
from backend.auth.auth_manager import auth_manager

class TestAuthenticationSystem:
    """Test user authentication, registration, and session management"""
    
    @pytest.mark.asyncio
    async def test_user_registration(self, client: AsyncClient, db_session):
        """Test user can register successfully"""
        user_data = {
            "username": "newuser",
            "email": "newuser@example.com", 
            "password": "securepassword123",
            "full_name": "New User"
        }
        
        response = await client.post("/api/auth/register", json=user_data)
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        
        assert data["username"] == "newuser"
        assert data["email"] == "newuser@example.com"
        assert data["full_name"] == "New User"
        assert "password" not in data  # Password should not be returned
        assert "id" in data
        assert data["is_active"] is True
        assert data["is_verified"] is True  # Auto-verified for now
    
    @pytest.mark.asyncio
    async def test_duplicate_user_registration(self, client: AsyncClient, test_user):
        """Test registration fails with duplicate username/email"""
        # Try to register with same username
        user_data = {
            "username": "testuser",  # Same as test_user
            "email": "different@example.com",
            "password": "password123",
            "full_name": "Different User"
        }
        
        response = await client.post("/api/auth/register", json=user_data)
        assert response.status_code == status.HTTP_409_CONFLICT
        
        # Try to register with same email
        user_data = {
            "username": "differentuser",
            "email": "test@example.com",  # Same as test_user
            "password": "password123",
            "full_name": "Different User"
        }
        
        response = await client.post("/api/auth/register", json=user_data)
        assert response.status_code == status.HTTP_409_CONFLICT
    
    @pytest.mark.asyncio
    async def test_user_login_success(self, client: AsyncClient, test_user):
        """Test successful login with username and password"""
        login_data = {
            "username": "testuser",
            "password": "testpassword123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "access_token" in data
        assert "user" in data
        assert data["user"]["username"] == "testuser"
        
        # Check that session cookie is set
        assert "session_token" in response.cookies
    
    @pytest.mark.asyncio 
    async def test_user_login_with_email(self, client: AsyncClient, test_user):
        """Test login with email instead of username"""
        login_data = {
            "username": "test@example.com",  # Using email as username
            "password": "testpassword123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["user"]["email"] == "test@example.com"
    
    @pytest.mark.asyncio
    async def test_login_invalid_credentials(self, client: AsyncClient, test_user):
        """Test login fails with wrong password"""
        login_data = {
            "username": "testuser",
            "password": "wrongpassword"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        data = response.json()
        assert "error" in data
        assert data["error"] == "invalid_credentials"
    
    @pytest.mark.asyncio
    async def test_login_nonexistent_user(self, client: AsyncClient):
        """Test login fails with nonexistent username"""
        login_data = {
            "username": "nonexistent",
            "password": "password123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        data = response.json()
        assert "error" in data
    
    @pytest.mark.asyncio
    async def test_protected_endpoint_without_auth(self, client: AsyncClient):
        """Test protected endpoint requires authentication"""
        response = await client.get("/api/chat/conversations/testuser")
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        data = response.json()
        assert "authentication_required" in data["detail"]["error"]
    
    @pytest.mark.asyncio
    async def test_protected_endpoint_with_auth(self, authenticated_client):
        """Test protected endpoint works with valid session"""
        response = await authenticated_client.get("/api/chat/conversations/testuser")
        
        # Should not get 401 (might get 404 or 200 depending on data)
        assert response.status_code != status.HTTP_401_UNAUTHORIZED
    
    @pytest.mark.asyncio
    async def test_session_token_validation(self, client: AsyncClient, test_user):
        """Test session token validation"""
        # Create session manually
        session = await auth_manager.create_session(test_user.id)
        
        # Use session token in Authorization header
        headers = {"Authorization": f"Bearer {session.session_token}"}
        response = await client.get("/api/auth/me", headers=headers)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["username"] == "testuser"
    
    @pytest.mark.asyncio
    async def test_session_expires(self, client: AsyncClient, test_user, db_session):
        """Test that expired sessions are rejected"""
        # Create expired session
        session = UserSession.create_session(test_user.id, expires_in_days=-1)  # Expired
        db_session.add(session)
        await db_session.commit()
        
        # Try to use expired session
        headers = {"Authorization": f"Bearer {session.session_token}"}
        response = await client.get("/api/auth/me", headers=headers)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    @pytest.mark.asyncio
    async def test_logout(self, authenticated_client):
        """Test user logout"""
        response = await authenticated_client.post("/api/auth/logout")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["message"] == "Logged out successfully"
        
        # Session cookie should be cleared
        assert "session_token" not in authenticated_client.cookies or \
               authenticated_client.cookies["session_token"] == ""
    
    @pytest.mark.asyncio
    async def test_logout_invalidates_session(self, client: AsyncClient, test_user):
        """Test logout invalidates the session token"""
        # Login first
        login_data = {
            "username": "testuser",
            "password": "testpassword123"
        }
        
        response = await client.post("/api/auth/login", json=login_data)
        assert response.status_code == status.HTTP_200_OK
        
        session_token = response.cookies["session_token"]
        
        # Logout
        response = await client.post("/api/auth/logout")
        assert response.status_code == status.HTTP_200_OK
        
        # Try to use the old session token
        headers = {"Authorization": f"Bearer {session_token}"}
        response = await client.get("/api/auth/me", headers=headers)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    @pytest.mark.asyncio
    async def test_get_current_user_info(self, authenticated_client, test_user):
        """Test getting current user information"""
        response = await authenticated_client.get("/api/auth/me")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert data["id"] == str(test_user.id)
        assert data["username"] == "testuser"
        assert data["email"] == "test@example.com"
        assert data["full_name"] == "Test User"
        assert "password" not in data
        assert "last_login" in data
    
    @pytest.mark.asyncio
    async def test_multiple_session_support(self, client: AsyncClient, test_user):
        """Test user can have multiple active sessions"""
        # Create two sessions for the same user
        session1 = await auth_manager.create_session(test_user.id, user_agent="Browser 1")
        session2 = await auth_manager.create_session(test_user.id, user_agent="Browser 2")
        
        # Both sessions should work
        headers1 = {"Authorization": f"Bearer {session1.session_token}"}
        headers2 = {"Authorization": f"Bearer {session2.session_token}"}
        
        response1 = await client.get("/api/auth/me", headers=headers1)
        response2 = await client.get("/api/auth/me", headers=headers2)
        
        assert response1.status_code == status.HTTP_200_OK
        assert response2.status_code == status.HTTP_200_OK
        
        # Both should return the same user
        data1 = response1.json()
        data2 = response2.json()
        assert data1["id"] == data2["id"]

class TestAdminAuthentication:
    """Test admin-specific authentication features"""
    
    @pytest.mark.asyncio
    async def test_admin_endpoint_requires_admin(self, authenticated_client):
        """Test admin endpoint rejects non-admin users"""
        response = await authenticated_client.get("/api/auth/users")
        
        assert response.status_code == status.HTTP_403_FORBIDDEN
        data = response.json()
        assert "insufficient_privileges" in data["detail"]["error"]
    
    @pytest.mark.asyncio
    async def test_admin_endpoint_allows_admin(self, admin_client):
        """Test admin endpoint allows admin users"""
        response = await admin_client.get("/api/auth/users")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "users" in data
    
    @pytest.mark.asyncio
    async def test_create_admin_user(self, client: AsyncClient):
        """Test creating admin user through registration"""
        # This might require special setup or invitation codes
        # For now, test direct creation via auth_manager
        admin_user = await auth_manager.create_user(
            username="newadmin",
            email="admin@test.com",
            password="adminpass123",
            is_admin=True
        )
        
        assert admin_user is not None
        assert admin_user.is_admin is True
        assert admin_user.username == "newadmin"

class TestPasswordSecurity:
    """Test password hashing and security"""
    
    @pytest.mark.asyncio
    async def test_password_hashing(self, db_session):
        """Test passwords are properly hashed"""
        user = await auth_manager.create_user(
            username="testpass",
            email="testpass@example.com", 
            password="mypassword123"
        )
        
        # Password should be hashed, not stored in plain text
        assert user.password_hash != "mypassword123"
        assert len(user.password_hash) > 50  # Bcrypt hashes are long
        
        # Should be able to verify the password
        assert user.check_password("mypassword123") is True
        assert user.check_password("wrongpassword") is False
    
    @pytest.mark.asyncio
    async def test_weak_password_rejection(self, client: AsyncClient):
        """Test registration rejects weak passwords"""
        user_data = {
            "username": "weakpass",
            "email": "weak@example.com",
            "password": "123",  # Too weak
            "full_name": "Weak User"
        }
        
        response = await client.post("/api/auth/register", json=user_data)
        
        # Should reject weak password (implement this in your registration endpoint)
        assert response.status_code in [status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY]

if __name__ == "__main__":
    pytest.main([__file__, "-v"])