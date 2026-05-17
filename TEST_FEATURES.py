#!/usr/bin/env python3
"""
Comprehensive test suite for LegalEase API endpoints
Tests all features to ensure web has complete API coverage
"""

import asyncio
import json
import httpx
import sys

BASE_URL = "http://127.0.0.1:8000"

# Color codes for output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"

async def test_health():
    """Test health endpoint"""
    print(f"\n{YELLOW}Testing: Health Check{RESET}")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{BASE_URL}/health")
            assert response.status_code == 200, f"Expected 200, got {response.status_code}"
            data = response.json()
            assert data["status"] == "ok"
            print(f"{GREEN}✓ Health check passed{RESET}")
            return True
    except Exception as e:
        print(f"{RED}✗ Health check failed: {e}{RESET}")
        return False

async def test_authentication():
    """Test auth endpoints"""
    print(f"\n{YELLOW}Testing: Authentication{RESET}")
    
    async with httpx.AsyncClient() as client:
        # Test registration
        print("  - Testing registration...")
        try:
            response = await client.post(
                f"{BASE_URL}/auth/register",
                json={
                    "username": "testuser1",
                    "email": "test1@example.com",
                    "password": "TestPassword123!"
                }
            )
            assert response.status_code == 200, f"Register failed: {response.status_code}"
            reg_data = response.json()
            user_id = reg_data["user_id"]
            print(f"{GREEN}  ✓ Registration passed (user_id: {user_id}){RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Registration failed: {e}{RESET}")
            return False
        
        # Test login
        print("  - Testing login...")
        try:
            response = await client.post(
                f"{BASE_URL}/auth/login",
                json={
                    "username": "testuser1",
                    "password": "TestPassword123!"
                }
            )
            assert response.status_code == 200, f"Login failed: {response.status_code}"
            login_data = response.json()
            token = login_data["access_token"]
            print(f"{GREEN}  ✓ Login passed (token: {token[:20]}...){RESET}")
            return token, user_id
        except Exception as e:
            print(f"{RED}  ✗ Login failed: {e}{RESET}")
            return None, None

async def test_chats(token, user_id):
    """Test chat CRUD operations"""
    print(f"\n{YELLOW}Testing: Chat Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
        # Test create chat
        print("  - Testing create chat...")
        try:
            response = await client.post(
                f"{BASE_URL}/users/{user_id}/chats",
                json={"title": "Test Chat"},
                headers=headers
            )
            assert response.status_code == 200, f"Create chat failed: {response.status_code}"
            chat_data = response.json()
            chat_id = chat_data["id"]
            print(f"{GREEN}  ✓ Create chat passed (chat_id: {chat_id}){RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Create chat failed: {e}{RESET}")
            return None
        
        # Test list chats
        print("  - Testing list chats...")
        try:
            response = await client.get(
                f"{BASE_URL}/users/{user_id}/chats",
                headers=headers
            )
            assert response.status_code == 200, f"List chats failed: {response.status_code}"
            chats_data = response.json()
            assert len(chats_data["items"]) > 0
            print(f"{GREEN}  ✓ List chats passed ({len(chats_data['items'])} chats){RESET}")
        except Exception as e:
            print(f"{RED}  ✗ List chats failed: {e}{RESET}")
            return None
        
        # Test get chat
        print("  - Testing get chat...")
        try:
            response = await client.get(
                f"{BASE_URL}/chats/{chat_id}",
                headers=headers
            )
            assert response.status_code == 200, f"Get chat failed: {response.status_code}"
            print(f"{GREEN}  ✓ Get chat passed{RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Get chat failed: {e}{RESET}")
            return None
        
        # Test update chat
        print("  - Testing update chat (rename + pin)...")
        try:
            response = await client.patch(
                f"{BASE_URL}/chats/{chat_id}",
                json={"title": "Renamed Chat", "is_pinned": True},
                headers=headers
            )
            assert response.status_code == 200, f"Update chat failed: {response.status_code}"
            updated_data = response.json()
            assert updated_data["title"] == "Renamed Chat"
            assert updated_data["is_pinned"] == True
            print(f"{GREEN}  ✓ Update chat passed{RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Update chat failed: {e}{RESET}")
            return None
        
        return chat_id

async def test_messages(token, user_id, chat_id):
    """Test message operations"""
    print(f"\n{YELLOW}Testing: Message Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
        # Test add message
        print("  - Testing add message...")
        try:
            response = await client.post(
                f"{BASE_URL}/chats/{chat_id}/messages",
                json={
                    "sender": "user",
                    "content": "Hello, LegalEase!"
                },
                headers=headers
            )
            assert response.status_code == 200, f"Add message failed: {response.status_code}"
            msg_data = response.json()
            user_msg_id = msg_data["user_message"]["id"]
            ai_msg_id = msg_data["assistant_message"]["id"]
            print(f"{GREEN}  ✓ Add message passed (user_msg: {user_msg_id}, ai_msg: {ai_msg_id}){RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Add message failed: {e}{RESET}")
            return None
        
        # Test update message
        print("  - Testing update message...")
        try:
            response = await client.patch(
                f"{BASE_URL}/chats/{chat_id}/messages/{user_msg_id}",
                json={"content": "Updated message content"},
                headers=headers
            )
            assert response.status_code == 200, f"Update message failed: {response.status_code}"
            updated_msg = response.json()
            assert updated_msg["content"] == "Updated message content"
            print(f"{GREEN}  ✓ Update message passed{RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Update message failed: {e}{RESET}")
            return None
        
        # Test delete message
        print("  - Testing delete message...")
        try:
            response = await client.delete(
                f"{BASE_URL}/chats/{chat_id}/messages/{ai_msg_id}",
                headers=headers
            )
            assert response.status_code == 200, f"Delete message failed: {response.status_code}"
            del_data = response.json()
            assert del_data["deleted"] == True
            print(f"{GREEN}  ✓ Delete message passed{RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Delete message failed: {e}{RESET}")
            return None
        
        return user_msg_id

async def test_share(token, chat_id):
    """Test share functionality"""
    print(f"\n{YELLOW}Testing: Share Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
        # Test enable sharing
        print("  - Testing enable sharing...")
        try:
            response = await client.post(
                f"{BASE_URL}/chats/{chat_id}/share",
                json={"enabled": True},
                headers=headers
            )
            assert response.status_code == 200, f"Share enable failed: {response.status_code}"
            share_data = response.json()
            assert share_data["is_shared"] == True
            share_token = share_data["share_token"]
            share_link = share_data["share_link"]
            print(f"{GREEN}  ✓ Enable sharing passed (token: {share_token}){RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Enable sharing failed: {e}{RESET}")
            return None
        
        # Test get shared chat
        print("  - Testing access shared chat...")
        try:
            response = await client.get(f"{BASE_URL}/share/{share_token}")
            assert response.status_code == 200, f"Get shared chat failed: {response.status_code}"
            shared_data = response.json()
            assert shared_data["is_shared"] == True
            print(f"{GREEN}  ✓ Access shared chat passed{RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Access shared chat failed: {e}{RESET}")
            return None
        
        # Test disable sharing
        print("  - Testing disable sharing...")
        try:
            response = await client.post(
                f"{BASE_URL}/chats/{chat_id}/share",
                json={"enabled": False},
                headers=headers
            )
            assert response.status_code == 200, f"Share disable failed: {response.status_code}"
            share_data = response.json()
            assert share_data["is_shared"] == False
            print(f"{GREEN}  ✓ Disable sharing passed{RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Disable sharing failed: {e}{RESET}")
            return None
        
        return share_token

async def test_search(token, user_id):
    """Test search functionality"""
    print(f"\n{YELLOW}Testing: Search Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
        # Test search chats
        print("  - Testing search chats...")
        try:
            response = await client.get(
                f"{BASE_URL}/users/{user_id}/search?query=test",
                headers=headers
            )
            assert response.status_code == 200, f"Search failed: {response.status_code}"
            search_data = response.json()
            print(f"{GREEN}  ✓ Search chats passed ({len(search_data['items'])} results){RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Search failed: {e}{RESET}")
            return False
        
        return True

async def test_chat_deletion(token, chat_id):
    """Test chat deletion"""
    print(f"\n{YELLOW}Testing: Delete Chat{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
        print("  - Testing delete chat...")
        try:
            response = await client.delete(
                f"{BASE_URL}/chats/{chat_id}",
                headers=headers
            )
            assert response.status_code == 200, f"Delete chat failed: {response.status_code}"
            del_data = response.json()
            assert del_data["deleted"] == True
            print(f"{GREEN}  ✓ Delete chat passed{RESET}")
        except Exception as e:
            print(f"{RED}  ✗ Delete chat failed: {e}{RESET}")
            return False
        
        return True

async def main():
    """Run all tests"""
    print(f"\n{YELLOW}{'='*60}")
    print("LegalEase API - Comprehensive Feature Test")
    print(f"{'='*60}{RESET}")
    
    # Test health
    if not await test_health():
        print(f"\n{RED}API is not responding. Make sure the server is running.{RESET}")
        sys.exit(1)
    
    # Test authentication
    token, user_id = await test_authentication()
    if not token:
        print(f"\n{RED}Authentication failed.{RESET}")
        sys.exit(1)
    
    # Test chats
    chat_id = await test_chats(token, user_id)
    if not chat_id:
        print(f"\n{RED}Chat operations failed.{RESET}")
        sys.exit(1)
    
    # Test messages
    msg_id = await test_messages(token, user_id, chat_id)
    if not msg_id:
        print(f"\n{RED}Message operations failed.{RESET}")
        sys.exit(1)
    
    # Test search
    if not await test_search(token, user_id):
        print(f"\n{RED}Search operations failed.{RESET}")
        sys.exit(1)
    
    # Test share
    share_token = await test_share(token, chat_id)
    if not share_token:
        print(f"\n{RED}Share operations failed.{RESET}")
        sys.exit(1)
    
    # Test chat deletion
    if not await test_chat_deletion(token, chat_id):
        print(f"\n{RED}Chat deletion failed.{RESET}")
        sys.exit(1)
    
    print(f"\n{GREEN}{'='*60}")
    print("✓ ALL TESTS PASSED!")
    print(f"{'='*60}{RESET}\n")

if __name__ == "__main__":
    asyncio.run(main())
