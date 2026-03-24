"""
Database initialization script for LegalEase.
Creates indexes in MongoDB for optimal performance.

Usage:
    python init_db.py

Prerequisites:
    - MongoDB running on mongodb://localhost:27017
"""

import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

async def main():
    """Initialize database indexes."""
    mongodb_uri = "mongodb://localhost:27017"
    mongodb_db = "legalease"
    
    print(f"🔌 Connecting to MongoDB at {mongodb_uri}...")
    try:
        client = AsyncIOMotorClient(mongodb_uri)
        await client.admin.command("ping")
        db = client[mongodb_db]
        print(f"✓ Connected to {mongodb_db}")
    except Exception as e:
        print(f"✗ Connection failed: {e}")
        print("  Make sure MongoDB is running: net start MongoDB")
        return False

    try:
        print("\n📊 Creating indexes...")
        
        # Users collection
        await db.users.create_index("user_id", unique=True)
        await db.users.create_index("email", unique=True, sparse=True)
        print("  ✓ users indexes created")

        # Chats collection
        await db.chats.create_index("chat_id", unique=True)
        await db.chats.create_index([("owner_id", 1), ("updated_at", -1)])
        await db.chats.create_index("share_token", sparse=True)
        print("  ✓ chats indexes created")

        # Files collection
        await db.files.create_index("file_id", unique=True)
        await db.files.create_index([("user_id", 1), ("uploaded_at", -1)])
        print("  ✓ files indexes created")

        print("\n✅ Database initialized successfully!")
        return True
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        return False
    finally:
        client.close()

if __name__ == "__main__":
    success = asyncio.run(main())
    exit(0 if success else 1)
