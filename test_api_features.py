#!/usr/bin/env python3
"""
Simple test suite for LegalEase API endpoints using requests
Tests all features to ensure web has complete API coverage
"""

import json
import requests
import sys

BASE_URL = "http://127.0.0.1:8000"

# Color codes for output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"

def test_health():
    """Test health endpoint"""
    print(f"\n{YELLOW}Testing: Health Check{RESET}")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        assert data["status"] == "ok"
        print(f"{GREEN}✓ Health check passed{RESET}")
        return True
    except Exception as e:
        print(f"{RED}✗ Health check failed: {e}{RESET}")
        return False

def test_authentication():
    """Test auth endpoints"""
    print(f"\n{YELLOW}Testing: Authentication{RESET}")
    
    # Test registration
    print("  - Testing registration...")
    try:
        response = requests.post(
            f"{BASE_URL}/auth/register",
            json={
                "username": "testuser1",
                "email": "test1@example.com",
                "password": "TestPassword123!"
            },
            timeout=5
        )
        assert response.status_code == 200, f"Register failed: {response.status_code} - {response.text}"
        reg_data = response.json()
        user_id = reg_data["user_id"]
        print(f"{GREEN}  ✓ Registration passed (user_id: {user_id}){RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Registration failed: {e}{RESET}")
        return None, None
    
    # Test login
    print("  - Testing login...")
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login",
            json={
                "username": "testuser1",
                "password": "TestPassword123!"
            },
            timeout=5
        )
        assert response.status_code == 200, f"Login failed: {response.status_code} - {response.text}"
        login_data = response.json()
        token = login_data["access_token"]
        print(f"{GREEN}  ✓ Login passed (token: {token[:20]}...){RESET}")
        return token, user_id
    except Exception as e:
        print(f"{RED}  ✗ Login failed: {e}{RESET}")
        return None, None

def test_chats(token, user_id):
    """Test chat CRUD operations"""
    print(f"\n{YELLOW}Testing: Chat Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test create chat
    print("  - Testing create chat...")
    try:
        response = requests.post(
            f"{BASE_URL}/users/{user_id}/chats",
            json={"title": "Test Chat"},
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Create chat failed: {response.status_code} - {response.text}"
        chat_data = response.json()
        chat_id = chat_data["id"]
        print(f"{GREEN}  ✓ Create chat passed (chat_id: {chat_id}){RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Create chat failed: {e}{RESET}")
        return None
    
    # Test list chats
    print("  - Testing list chats...")
    try:
        response = requests.get(
            f"{BASE_URL}/users/{user_id}/chats",
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"List chats failed: {response.status_code} - {response.text}"
        chats_data = response.json()
        assert len(chats_data["items"]) > 0
        print(f"{GREEN}  ✓ List chats passed ({len(chats_data['items'])} chats){RESET}")
    except Exception as e:
        print(f"{RED}  ✗ List chats failed: {e}{RESET}")
        return None
    
    # Test get chat
    print("  - Testing get chat...")
    try:
        response = requests.get(
            f"{BASE_URL}/chats/{chat_id}",
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Get chat failed: {response.status_code} - {response.text}"
        print(f"{GREEN}  ✓ Get chat passed{RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Get chat failed: {e}{RESET}")
        return None
    
    # Test update chat
    print("  - Testing update chat (rename + pin)...")
    try:
        response = requests.patch(
            f"{BASE_URL}/chats/{chat_id}",
            json={"title": "Renamed Chat", "is_pinned": True},
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Update chat failed: {response.status_code} - {response.text}"
        updated_data = response.json()
        assert updated_data["title"] == "Renamed Chat"
        assert updated_data["is_pinned"] == True
        print(f"{GREEN}  ✓ Update chat passed{RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Update chat failed: {e}{RESET}")
        return None
    
    return chat_id

def test_messages(token, chat_id):
    """Test message operations"""
    print(f"\n{YELLOW}Testing: Message Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test add message
    print("  - Testing add message...")
    try:
        response = requests.post(
            f"{BASE_URL}/chats/{chat_id}/messages",
            json={
                "sender": "user",
                "content": "Hello, LegalEase!"
            },
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Add message failed: {response.status_code} - {response.text}"
        msg_data = response.json()
        user_msg_id = msg_data["user_message"]["id"]
        ai_msg_id = msg_data["assistant_message"]["id"]
        print(f"{GREEN}  ✓ Add message passed (user_msg: {user_msg_id[:10]}..., ai_msg: {ai_msg_id[:10]}...){RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Add message failed: {e}{RESET}")
        return None
    
    # Test update message
    print("  - Testing update message...")
    try:
        response = requests.patch(
            f"{BASE_URL}/chats/{chat_id}/messages/{user_msg_id}",
            json={"content": "Updated message content"},
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Update message failed: {response.status_code} - {response.text}"
        updated_msg = response.json()
        assert updated_msg["content"] == "Updated message content"
        print(f"{GREEN}  ✓ Update message passed{RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Update message failed: {e}{RESET}")
        return None
    
    # Test delete message
    print("  - Testing delete message...")
    try:
        response = requests.delete(
            f"{BASE_URL}/chats/{chat_id}/messages/{ai_msg_id}",
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Delete message failed: {response.status_code} - {response.text}"
        del_data = response.json()
        assert del_data["deleted"] == True
        print(f"{GREEN}  ✓ Delete message passed{RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Delete message failed: {e}{RESET}")
        return None
    
    return user_msg_id

def test_share(token, chat_id):
    """Test share functionality"""
    print(f"\n{YELLOW}Testing: Share Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test enable sharing
    print("  - Testing enable sharing...")
    try:
        response = requests.post(
            f"{BASE_URL}/chats/{chat_id}/share",
            json={"enabled": True},
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Share enable failed: {response.status_code} - {response.text}"
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
        response = requests.get(f"{BASE_URL}/share/{share_token}", timeout=5)
        assert response.status_code == 200, f"Get shared chat failed: {response.status_code} - {response.text}"
        shared_data = response.json()
        assert shared_data["is_shared"] == True
        print(f"{GREEN}  ✓ Access shared chat passed{RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Access shared chat failed: {e}{RESET}")
        return None
    
    # Test disable sharing
    print("  - Testing disable sharing...")
    try:
        response = requests.post(
            f"{BASE_URL}/chats/{chat_id}/share",
            json={"enabled": False},
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Share disable failed: {response.status_code} - {response.text}"
        share_data = response.json()
        assert share_data["is_shared"] == False
        print(f"{GREEN}  ✓ Disable sharing passed{RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Disable sharing failed: {e}{RESET}")
        return None
    
    return share_token

def test_search(token, user_id):
    """Test search functionality"""
    print(f"\n{YELLOW}Testing: Search Operations{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test search chats
    print("  - Testing search chats...")
    try:
        response = requests.get(
            f"{BASE_URL}/users/{user_id}/search?query=test",
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Search failed: {response.status_code} - {response.text}"
        search_data = response.json()
        print(f"{GREEN}  ✓ Search chats passed ({len(search_data['items'])} results){RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Search failed: {e}{RESET}")
        return False
    
    return True

def test_chat_deletion(token, chat_id):
    """Test chat deletion"""
    print(f"\n{YELLOW}Testing: Delete Chat{RESET}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    print("  - Testing delete chat...")
    try:
        response = requests.delete(
            f"{BASE_URL}/chats/{chat_id}",
            headers=headers,
            timeout=5
        )
        assert response.status_code == 200, f"Delete chat failed: {response.status_code} - {response.text}"
        del_data = response.json()
        assert del_data["deleted"] == True
        print(f"{GREEN}  ✓ Delete chat passed{RESET}")
    except Exception as e:
        print(f"{RED}  ✗ Delete chat failed: {e}{RESET}")
        return False
    
    return True

def main():
    """Run all tests"""
    print(f"\n{YELLOW}{'='*60}")
    print("LegalEase API - Comprehensive Feature Test")
    print(f"{'='*60}{RESET}")
    
    # Test health
    if not test_health():
        print(f"\n{RED}API is not responding. Make sure the server is running.{RESET}")
        print(f"Start the API with: cd api && uvicorn main:app --reload")
        sys.exit(1)
    
    # Test authentication
    token, user_id = test_authentication()
    if not token:
        print(f"\n{RED}Authentication failed.{RESET}")
        sys.exit(1)
    
    # Test chats
    chat_id = test_chats(token, user_id)
    if not chat_id:
        print(f"\n{RED}Chat operations failed.{RESET}")
        sys.exit(1)
    
    # Test messages
    msg_id = test_messages(token, chat_id)
    if not msg_id:
        print(f"\n{RED}Message operations failed.{RESET}")
        sys.exit(1)
    
    # Test search
    if not test_search(token, user_id):
        print(f"\n{RED}Search operations failed.{RESET}")
        sys.exit(1)
    
    # Test share
    share_token = test_share(token, chat_id)
    if not share_token:
        print(f"\n{RED}Share operations failed.{RESET}")
        sys.exit(1)
    
    # Test chat deletion
    if not test_chat_deletion(token, chat_id):
        print(f"\n{RED}Chat deletion failed.{RESET}")
        sys.exit(1)
    
    print(f"\n{GREEN}{'='*60}")
    print("✓ ALL TESTS PASSED!")
    print(f"{'='*60}{RESET}\n")
    print(f"{YELLOW}Summary:{RESET}")
    print(f"  ✓ Authentication (login/register)")
    print(f"  ✓ Chat CRUD operations")
    print(f"  ✓ Message CRUD operations")
    print(f"  ✓ Search functionality")
    print(f"  ✓ Share/unshare functionality")
    print(f"  ✓ Shared chat access")
    print(f"\n{GREEN}All API endpoints are working correctly!{RESET}\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{YELLOW}Test interrupted.{RESET}")
        sys.exit(0)
