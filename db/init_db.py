"""
Database initialization script for LegalEase.
Run this script once on a new system to create indexes in MongoDB.

Usage:
    python init_db.py

Prerequisites:
    - MongoDB must be running locally on mongodb://localhost:27017
    - .env file must exist in the db/ folder with MONGODB_URI and MONGODB_DB
"""

import asyncio
import sys
from pathlib import Path
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db: str = "legalease"


async def main() -> None:
    """Initialize database indexes."""
    settings = Settings()
    
    print(f"🔌 Connecting to MongoDB at {settings.mongodb_uri}...")
    try:
        client = AsyncIOMotorClient(settings.mongodb_uri)
        # Test connection
        await client.admin.command("ping")
        db = client[settings.mongodb_db]
        print(f"✓ Connected to database: {settings.mongodb_db}")
    except Exception as e:
        print(f"✗ Failed to connect to MongoDB: {e}")
        print("  Ensure MongoDB is running: 'mongod' or 'brew services start mongodb-community'")
        sys.exit(1)

    try:
        print("\n📊 Creating indexes...")
        
        # Users collection indexes
        await db.users.create_index("user_id", unique=True)
        await db.users.create_index("email", unique=True, sparse=True)
        print("  ✓ users collection indexes created")

        # Chats collection indexes
        await db.chats.create_index("chat_id", unique=True)
        await db.chats.create_index([("owner_id", 1), ("updated_at", -1)])
        await db.chats.create_index("share_token", sparse=True)
        print("  ✓ chats collection indexes created")

        # Files collection indexes
        await db.files.create_index("file_id", unique=True)
        await db.files.create_index([("user_id", 1), ("uploaded_at", -1)])
        print("  ✓ files collection indexes created")

        print("\n✅ Database initialized successfully!")
        print(f"   Collections: users, chats, files")
        print(f"   Database: {settings.mongodb_db}")
        
    except Exception as e:
        print(f"\n✗ Error creating indexes: {e}")
        sys.exit(1)
    finally:
        client.close()


if __name__ == "__main__":
    asyncio.run(main())
