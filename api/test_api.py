"""
Basic unit tests for LegalEase API endpoints.
Run with: pytest test_api.py
"""

import pytest
import uuid
from fastapi.testclient import TestClient
from main import app, db, settings
import asyncio

@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client


class TestHealth:
    """Test health check endpoint."""
    
    def test_health_endpoint(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


class TestAuth:
    """Test authentication endpoints."""
    
    @pytest.fixture(autouse=True)
    async def cleanup(self):
        """Clean up test data after each test."""
        yield
        # Optional: Clean up test users
    
    def test_register_user(self, client):
        """Test user registration."""
        unique = uuid.uuid4().hex[:8]
        username = f"testuser1_{unique}"
        response = client.post(
            "/auth/register",
            json={
                "username": username,
                "email": f"test1_{unique}@example.com",
                "password": "securepass123"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "user_id" in data
        assert data["username"] == username
    
    def test_register_duplicate_username(self, client):
        """Test registration with duplicate username."""
        unique = uuid.uuid4().hex[:8]
        username = f"duplicate_{unique}"

        # Register first user
        client.post(
            "/auth/register",
            json={
                "username": username,
                "email": f"test2_{unique}@example.com",
                "password": "securepass123"
            }
        )
        
        # Try to register with same username
        response = client.post(
            "/auth/register",
            json={
                "username": username,
                "email": f"test3_{unique}@example.com",
                "password": "securepass123"
            }
        )
        assert response.status_code == 400
    
    def test_login_user(self, client):
        """Test user login."""
        unique = uuid.uuid4().hex[:8]
        username = f"logintest_{unique}"

        # Register user
        reg_response = client.post(
            "/auth/register",
            json={
                "username": username,
                "email": f"{username}@example.com",
                "password": "securepass123"
            }
        )
        
        # Login with correct credentials
        response = client.post(
            "/auth/login",
            json={
                "username": username,
                "password": "securepass123"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    def test_login_invalid_credentials(self, client):
        """Test login with invalid credentials."""
        response = client.post(
            "/auth/login",
            json={
                "username": "nonexistent",
                "password": "wrongpassword"
            }
        )
        assert response.status_code == 401


class TestChats:
    """Test chat endpoints."""
    
    def test_list_user_chats(self, client):
        """Test listing user chats."""
        user_id = "test_user_1"
        response = client.get(f"/users/{user_id}/chats")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert isinstance(data["items"], list)
    
    def test_create_chat(self, client):
        """Test creating a new chat."""
        user_id = "test_user_2"
        response = client.post(
            f"/users/{user_id}/chats",
            json={"title": "Test Chat"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "id" in data
        assert data["title"] == "Test Chat"
    
    def test_get_chat(self, client):
        """Test getting a specific chat."""
        user_id = "test_user_3"
        
        # Create chat first
        create_resp = client.post(
            f"/users/{user_id}/chats",
            json={"title": "Get Test Chat"}
        )
        chat_id = create_resp.json()["id"]
        
        # Get chat
        response = client.get(f"/chats/{chat_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == chat_id


class TestMessages:
    """Test message endpoints."""
    
    def test_add_message(self, client):
        """Test adding a message to a chat."""
        user_id = "test_user_4"
        
        # Create chat
        create_resp = client.post(
            f"/users/{user_id}/chats",
            json={"title": "Message Test"}
        )
        chat_id = create_resp.json()["id"]
        
        # Add message
        response = client.post(
            f"/chats/{chat_id}/messages",
            json={
                "sender": "user",
                "content": "Hello, LegalEase!"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "user_message" in data
        assert "assistant_message" in data


class TestValidation:
    """Test input validation."""
    
    def test_register_weak_password(self, client):
        """Test registration with weak password."""
        response = client.post(
            "/auth/register",
            json={
                "username": "weakpass",
                "email": "weak@example.com",
                "password": "short"  # Less than 8 characters
            }
        )
        assert response.status_code == 422  # Validation error
    
    def test_register_invalid_email(self, client):
        """Test registration with invalid email."""
        response = client.post(
            "/auth/register",
            json={
                "username": "invalidemail",
                "email": "not-an-email",
                "password": "securepass123"
            }
        )
        assert response.status_code == 422  # Validation error
    
    def test_invalid_username_pattern(self, client):
        """Test registration with invalid username pattern."""
        response = client.post(
            "/auth/register",
            json={
                "username": "invalid@user!",  # Invalid characters
                "email": "valid@example.com",
                "password": "securepass123"
            }
        )
        assert response.status_code == 422  # Validation error


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
