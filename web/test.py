#!/usr/bin/env python3
"""
LegalEase API Test Script
Tests all API endpoints used by the web interface.
"""

import requests
import json
import time
from typing import Optional, Dict, Any

# Configuration - matches web interface
API_BASE_URL = "http://127.0.0.1:8000"
USER_ID = "user1"

class LegalEaseAPITester:
    def __init__(self, base_url: str = API_BASE_URL, user_id: str = USER_ID):
        self.base_url = base_url.rstrip('/')
        self.user_id = user_id
        self.session = requests.Session()
        self.current_chat_id: Optional[str] = None

    def test_health(self) -> bool:
        """Test health endpoint"""
        print("🔍 Testing health endpoint...")
        try:
            response = self.session.get(f"{self.base_url}/health")
            if response.status_code == 200:
                data = response.json()
                if data.get("status") == "ok":
                    print("✅ Health check passed")
                    return True
            print(f"❌ Health check failed: {response.status_code} - {response.text}")
            return False
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return False

    def test_create_chat(self, title: str = "Test Chat") -> Optional[str]:
        """Test creating a new chat"""
        print(f"📝 Creating new chat: '{title}'...")
        try:
            response = self.session.post(
                f"{self.base_url}/users/{self.user_id}/chats",
                json={"title": title},
                headers={"Content-Type": "application/json"}
            )

            if response.status_code == 200:
                data = response.json()
                chat_id = data.get("id")
                if chat_id:
                    print(f"✅ Chat created successfully: {chat_id}")
                    self.current_chat_id = chat_id
                    return chat_id
                else:
                    print(f"❌ Chat creation failed: missing id in response")
                    return None
            else:
                print(f"❌ Chat creation failed: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            print(f"❌ Chat creation error: {e}")
            return None

    def test_get_chats(self) -> bool:
        """Test getting all chats"""
        print("📋 Getting all chats...")
        try:
            response = self.session.get(f"{self.base_url}/users/{self.user_id}/chats")

            if response.status_code == 200:
                data = response.json()
                items = data.get("items", [])
                print(f"✅ Retrieved {len(items)} chats")

                # Print chat details
                for i, chat in enumerate(items[:3]):  # Show first 3 chats
                    print(f"   Chat {i+1}: {chat.get('title')} (ID: {chat.get('id')})")
                    messages = chat.get('messages', [])
                    print(f"   Messages: {len(messages)}")

                return True
            else:
                print(f"❌ Get chats failed: {response.status_code} - {response.text}")
                return False
        except Exception as e:
            print(f"❌ Get chats error: {e}")
            return False

    def test_send_message(self, content: str = "Hello, this is a test message!") -> bool:
        """Test sending a message"""
        if not self.current_chat_id:
            print("❌ No current chat ID - create a chat first")
            return False

        print(f"💬 Sending message to chat {self.current_chat_id}...")
        try:
            response = self.session.post(
                f"{self.base_url}/chats/{self.current_chat_id}/messages",
                json={
                    "user_id": self.user_id,
                    "sender": "user",
                    "content": content
                },
                headers={"Content-Type": "application/json"}
            )

            if response.status_code == 200:
                data = response.json()
                user_msg = data.get("user_message", {})
                ai_msg = data.get("assistant_message", {})

                print("✅ Message sent successfully")
                print(f"   User message ID: {user_msg.get('id')}")
                print(f"   AI response ID: {ai_msg.get('id')}")
                print(f"   AI response: {ai_msg.get('content', '')[:100]}...")

                return True
            else:
                print(f"❌ Send message failed: {response.status_code} - {response.text}")
                return False
        except Exception as e:
            print(f"❌ Send message error: {e}")
            return False

    def test_get_chat_details(self) -> bool:
        """Test getting specific chat details"""
        if not self.current_chat_id:
            print("❌ No current chat ID - create a chat first")
            return False

        print(f"📖 Getting chat details for {self.current_chat_id}...")
        try:
            response = self.session.get(f"{self.base_url}/chats/{self.current_chat_id}")

            if response.status_code == 200:
                data = response.json()
                messages = data.get("messages", [])
                print(f"✅ Chat details retrieved: {len(messages)} messages")

                # Show last few messages
                for msg in messages[-2:]:  # Show last 2 messages
                    sender = msg.get('sender', 'unknown')
                    content = msg.get('content', '')[:50]
                    print(f"   {sender.upper()}: {content}...")

                return True
            else:
                print(f"❌ Get chat details failed: {response.status_code} - {response.text}")
                return False
        except Exception as e:
            print(f"❌ Get chat details error: {e}")
            return False

    def run_all_tests(self) -> bool:
        """Run all API tests in sequence"""
        print("🚀 Starting LegalEase API Tests")
        print("=" * 50)

        # Test 1: Health check
        if not self.test_health():
            return False

        print()

        # Test 2: Get existing chats
        if not self.test_get_chats():
            return False

        print()

        # Test 3: Create new chat
        chat_id = self.test_create_chat("API Test Chat")
        if not chat_id:
            return False

        print()

        # Test 4: Send message
        if not self.test_send_message("This is a test message from the API tester."):
            return False

        print()

        # Test 5: Get chat details
        if not self.test_get_chat_details():
            return False

        print()

        # Test 6: Send another message
        if not self.test_send_message("This is another test message to verify conversation flow."):
            return False

        print()

        # Test 7: Get updated chats list
        if not self.test_get_chats():
            return False

        print()
        print("🎉 All API tests passed successfully!")
        return True


def main():
    """Main function to run the API tests"""
    tester = LegalEaseAPITester()

    try:
        success = tester.run_all_tests()
        if success:
            print("\n✅ All tests completed successfully!")
            print("The API is working correctly and ready for the web interface.")
        else:
            print("\n❌ Some tests failed. Check the API server and MongoDB connection.")
            return 1
    except KeyboardInterrupt:
        print("\n⏹️  Tests interrupted by user")
        return 1
    except Exception as e:
        print(f"\n💥 Unexpected error: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())