from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db: str = "legalease"
    api_base_url: str = "http://127.0.0.1:8000"
    default_system_prompt: str = (
        "You are LegalEase, a legal-focused assistant. Provide clear and practical guidance, "
        "mention limitations, and recommend consulting a qualified lawyer for "
        "jurisdiction-specific legal advice."
    )


settings = Settings()
app = FastAPI(title="LegalEase API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

mongo_client = AsyncIOMotorClient(settings.mongodb_uri)
db: AsyncIOMotorDatabase = mongo_client[settings.mongodb_db]


class CreateChatRequest(BaseModel):
    title: str = "New Chat"


class UpdateChatRequest(BaseModel):
    title: str | None = None
    is_pinned: bool | None = None


class AddMessageRequest(BaseModel):
    user_id: str | None = None
    sender: str = Field(default="user", pattern="^(user|ai)$")
    content: str = Field(min_length=1)


class ShareToggleRequest(BaseModel):
    enabled: bool = True


def now_iso() -> str:
    return datetime.now(UTC).isoformat()


def make_id(prefix: str) -> str:
    return f"{prefix}_{uuid.uuid4().hex[:12]}"


def build_demo_reply(prompt: str) -> str:
    return (
        "LegalEase (demo): I received your message - "
        f"\"{prompt}\". Backend is connected locally. "
        "Plug Gemini in this endpoint to return real AI responses."
    )


def chat_to_response(chat: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": chat["chat_id"],
        "user_id": chat["owner_id"],
        "title": chat.get("title", "New Chat"),
        "created_at": chat["created_at"],
        "updated_at": chat["updated_at"],
        "is_pinned": chat.get("is_pinned", False),
        "is_shared": chat.get("is_shared", False),
        "share_link": chat.get("share_link"),
        "messages": chat.get("messages", []),
    }


async def ensure_indexes() -> None:
    await db.users.create_index("user_id", unique=True)
    await db.users.create_index("email", unique=True, sparse=True)

    await db.chats.create_index("chat_id", unique=True)
    await db.chats.create_index([("owner_id", 1), ("updated_at", -1)])
    await db.chats.create_index("share_token", sparse=True)

    await db.files.create_index("file_id", unique=True)
    await db.files.create_index([("user_id", 1), ("uploaded_at", -1)])


@app.on_event("startup")
async def on_startup() -> None:
    await ensure_indexes()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/users/{user_id}/chats")
async def list_user_chats(user_id: str) -> dict[str, list[dict[str, Any]]]:
    cursor = db.chats.find({"owner_id": user_id}).sort("updated_at", -1)
    chats = [chat_to_response(chat) async for chat in cursor]
    return {"items": chats}


@app.post("/users/{user_id}/chats")
async def create_chat(user_id: str, payload: CreateChatRequest) -> dict[str, Any]:
    chat_id = make_id("chat")
    created_at = now_iso()
    doc = {
        "chat_id": chat_id,
        "owner_id": user_id,
        "title": payload.title.strip() or "New Chat",
        "system_prompt": settings.default_system_prompt,
        "is_pinned": False,
        "is_shared": False,
        "share_token": None,
        "share_link": None,
        "messages": [],
        "created_at": created_at,
        "updated_at": created_at,
    }
    await db.chats.insert_one(doc)
    return chat_to_response(doc)


@app.get("/chats/{chat_id}")
async def get_chat(chat_id: str) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    return chat_to_response(chat)


@app.patch("/chats/{chat_id}")
async def update_chat(chat_id: str, payload: UpdateChatRequest) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")

    updates: dict[str, Any] = {"updated_at": now_iso()}
    if payload.title is not None:
        updates["title"] = payload.title.strip() or chat.get("title", "New Chat")
    if payload.is_pinned is not None:
        updates["is_pinned"] = payload.is_pinned

    await db.chats.update_one({"chat_id": chat_id}, {"$set": updates})
    updated = await db.chats.find_one({"chat_id": chat_id})
    if not updated:
        raise HTTPException(status_code=404, detail="Chat not found")
    return chat_to_response(updated)


@app.delete("/chats/{chat_id}")
async def delete_chat(chat_id: str) -> dict[str, bool]:
    result = await db.chats.delete_one({"chat_id": chat_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Chat not found")
    return {"deleted": True}


@app.post("/chats/{chat_id}/messages")
async def add_message(chat_id: str, payload: AddMessageRequest) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")

    created_at = now_iso()
    user_message = {
        "id": make_id("msg"),
        "chat_id": chat_id,
        "sender": payload.sender,
        "content": payload.content,
        "created_at": created_at,
        "user_id": payload.user_id,
    }

    assistant_message = {
        "id": make_id("msg"),
        "chat_id": chat_id,
        "sender": "ai",
        "content": build_demo_reply(payload.content),
        "created_at": now_iso(),
        "user_id": None,
    }

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$push": {"messages": {"$each": [user_message, assistant_message]}},
            "$set": {"updated_at": now_iso()},
        },
    )

    return {
        "chat_id": chat_id,
        "user_message": user_message,
        "assistant_message": assistant_message,
    }


@app.post("/chats/{chat_id}/share")
async def share_chat(chat_id: str, payload: ShareToggleRequest) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")

    if payload.enabled:
        token = chat.get("share_token") or make_id("share")
        link = f"{settings.api_base_url.rstrip('/')}/share/{token}"
        await db.chats.update_one(
            {"chat_id": chat_id},
            {
                "$set": {
                    "is_shared": True,
                    "share_token": token,
                    "share_link": link,
                    "updated_at": now_iso(),
                }
            },
        )
        return {"chat_id": chat_id, "is_shared": True, "share_link": link, "share_token": token}

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$set": {
                "is_shared": False,
                "share_token": None,
                "share_link": None,
                "updated_at": now_iso(),
            }
        },
    )
    return {"chat_id": chat_id, "is_shared": False}


@app.get("/share/{share_token}")
async def get_shared_chat(share_token: str) -> dict[str, Any]:
    chat = await db.chats.find_one({"share_token": share_token, "is_shared": True})
    if not chat:
        raise HTTPException(status_code=404, detail="Shared chat not found")

    # Public response: read-only chat view for guests.
    return {
        "chat_id": chat["chat_id"],
        "title": chat.get("title", "Shared Chat"),
        "messages": chat.get("messages", []),
        "is_shared": True,
    }
