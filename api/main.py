import asyncio
import logging
import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import FastAPI, HTTPException, Request, Body
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address
# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("legalease")


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
    allowed_origins: str = "http://localhost:8080,http://127.0.0.1:8080"
    secret_key: str = "my_super_secret_jwt_key_for_legalease"
    algorithm: str = "HS256"
    max_file_size: int = 10485760  # 10MB
    rate_limit: str = "100/minute"


settings = Settings()
app = FastAPI(title="LegalEase API", version="0.1.0")

# Parse allowed origins
allowed_origins = [origin.strip() for origin in settings.allowed_origins.split(",")]

# Add CORS middleware with restricted origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

mongo_client: AsyncIOMotorClient | None = None
db: AsyncIOMotorDatabase | None = None


class CreateChatRequest(BaseModel):
    title: str = "New Chat"


class UpdateChatRequest(BaseModel):
    title: str | None = None
    is_pinned: bool | None = None


class AddMessageRequest(BaseModel):
    user_id: str | None = None
    sender: str = Field(default="user", pattern="^(user|ai)$")
    content: str = Field(min_length=1)


class UpdateMessageRequest(BaseModel):
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
    if db is None:
        raise RuntimeError("Database is not initialized")
    await db.users.create_index("user_id", unique=True)
    await db.users.create_index("email", unique=True, sparse=True)

    await db.chats.create_index("chat_id", unique=True)
    await db.chats.create_index([("owner_id", 1), ("updated_at", -1)])
    await db.chats.create_index("share_token", sparse=True)

    await db.files.create_index("file_id", unique=True)
    await db.files.create_index([("user_id", 1), ("uploaded_at", -1)])


@app.on_event("startup")
async def on_startup() -> None:
    global mongo_client, db
    loop = asyncio.get_running_loop()
    mongo_client = AsyncIOMotorClient(settings.mongodb_uri, io_loop=loop)
    db = mongo_client[settings.mongodb_db]
    await ensure_indexes()


@app.on_event("shutdown")
async def on_shutdown() -> None:
    if mongo_client is not None:
        mongo_client.close()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/users/{user_id}/chats")
@limiter.limit("60/minute")
async def list_user_chats(request: Request, user_id: str) -> dict[str, list[dict[str, Any]]]:
    cursor = db.chats.find({"owner_id": user_id}).sort("updated_at", -1)
    chats = [chat_to_response(chat) async for chat in cursor]
    logger.info(f"Retrieved {len(chats)} chats for user {user_id}")
    return {"items": chats}


@app.post("/users/{user_id}/chats")
@limiter.limit("20/minute")
async def create_chat(request: Request, user_id: str, payload: CreateChatRequest = Body(...)) -> dict[str, Any]:
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
@limiter.limit("60/minute")
async def get_chat(request: Request, chat_id: str) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    return chat_to_response(chat)


@app.patch("/chats/{chat_id}")
@limiter.limit("20/minute")
async def update_chat(request: Request, chat_id: str, payload: UpdateChatRequest = Body(...)) -> dict[str, Any]:
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
    logger.info(f"Chat {chat_id} updated")
    return chat_to_response(updated)


@app.delete("/chats/{chat_id}")
@limiter.limit("10/minute")
async def delete_chat(request: Request, chat_id: str) -> dict[str, bool]:
    result = await db.chats.delete_one({"chat_id": chat_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Chat not found")
    logger.info(f"Chat {chat_id} deleted")
    return {"deleted": True}


@app.post("/chats/{chat_id}/messages")
@limiter.limit("60/minute")
async def add_message(request: Request, chat_id: str, payload: AddMessageRequest = Body(...)) -> dict[str, Any]:
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

    logger.info(f"Message added to chat {chat_id}")
    return {
        "chat_id": chat_id,
        "user_message": user_message,
        "assistant_message": assistant_message,
    }


@app.post("/chats/{chat_id}/share")
@limiter.limit("20/minute")
async def share_chat(request: Request, chat_id: str, payload: ShareToggleRequest = Body(...)) -> dict[str, Any]:
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
        logger.info(f"Chat {chat_id} shared")
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
    logger.info(f"Chat {chat_id} share disabled")
    return {"chat_id": chat_id, "is_shared": False}


@app.patch("/chats/{chat_id}/messages/{message_id}")
@limiter.limit("30/minute")
async def update_message(request: Request, chat_id: str, message_id: str, payload: UpdateMessageRequest = Body(...)) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")

    # Find and update the specific message
    messages = chat.get("messages", [])
    message_index = None
    for i, msg in enumerate(messages):
        if msg.get("id") == message_id:
            message_index = i
            break

    if message_index is None:
        raise HTTPException(status_code=404, detail="Message not found")

    # Only allow editing user messages
    if messages[message_index].get("sender") != "user":
        raise HTTPException(status_code=400, detail="Can only edit user messages")

    # Update the message content
    messages[message_index]["content"] = payload.content
    messages[message_index]["edited_at"] = now_iso()

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$set": {
                "messages": messages,
                "updated_at": now_iso(),
            }
        },
    )

    logger.info(f"Message {message_id} in chat {chat_id} updated")
    return {
        "chat_id": chat_id,
        "message_id": message_id,
        "content": payload.content,
        "edited_at": messages[message_index]["edited_at"],
    }


@app.delete("/chats/{chat_id}/messages/{message_id}")
@limiter.limit("30/minute")
async def delete_message(request: Request, chat_id: str, message_id: str) -> dict[str, bool]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")

    messages = chat.get("messages", [])
    original_length = len(messages)

    # Remove the message and all subsequent messages (like ChatGPT behavior)
    filtered_messages = []
    found_message = False

    for msg in messages:
        if msg.get("id") == message_id:
            found_message = True
            continue  # Skip this message and all after it
        if not found_message:
            filtered_messages.append(msg)

    if len(filtered_messages) == original_length:
        raise HTTPException(status_code=404, detail="Message not found")

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$set": {
                "messages": filtered_messages,
                "updated_at": now_iso(),
            }
        },
    )

    logger.info(f"Message {message_id} in chat {chat_id} deleted")
    return {"deleted": True}


@app.get("/share/{share_token}")
@limiter.limit("60/minute")
async def get_shared_chat(request: Request, share_token: str) -> dict[str, Any]:
    chat = await db.chats.find_one({"share_token": share_token, "is_shared": True})
    if not chat:
        raise HTTPException(status_code=404, detail="Shared chat not found")

    # Public response: read-only chat view for guests.
    logger.info(f"Shared chat accessed with token: {share_token}")
    return {
        "chat_id": chat["chat_id"],
        "title": chat.get("title", "Shared Chat"),
        "messages": chat.get("messages", []),
        "is_shared": True,
    }

# --- Auth, Search, and File endpoints ---
import jwt
from typing import Optional
from passlib.context import CryptContext
from fastapi import Depends, UploadFile, File, Form

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=50, pattern="^[a-zA-Z0-9_]+$")
    email: str = Field(pattern=r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=8, max_length=128)


@app.post("/auth/register")
@limiter.limit("5/minute")
async def register(request: Request, payload: RegisterRequest = Body(...)):
    logger.info(f"Register attempt for user: {payload.username}")
    existing = await db.users.find_one({"$or": [{"username": payload.username}, {"email": payload.email}]})
    if existing:
        logger.warning(f"Registration failed: username or email already taken - {payload.username}")
        raise HTTPException(status_code=400, detail="Username or email already taken")
    hashed_password = pwd_context.hash(payload.password[:72])
    user_id = make_id("user")
    await db.users.insert_one({
        "user_id": user_id,
        "username": payload.username,
        "email": payload.email,
        "password": hashed_password,
        "created_at": now_iso()
    })
    logger.info(f"User registered successfully: {user_id}")
    return {"user_id": user_id, "username": payload.username}


@app.post("/auth/login")
@limiter.limit("10/minute")
async def login(request: Request, payload: LoginRequest = Body(...)):
    logger.info(f"Login attempt for user: {payload.username}")
    user = await db.users.find_one({"username": payload.username})
    if not user or not pwd_context.verify(payload.password[:72], user["password"]):
        logger.warning(f"Login failed: invalid credentials for {payload.username}")
        raise HTTPException(status_code=401, detail="Invalid username or password")
    
    token = jwt.encode(
        {"user_id": user["user_id"], "username": user["username"]},
        settings.secret_key,
        algorithm=settings.algorithm
    )
    logger.info(f"Login successful for user: {user['user_id']}")
    return {"access_token": token, "token_type": "bearer", "user_id": user["user_id"]}


@app.post("/chats/{chat_id}/messages_with_file", response_model=None)
@limiter.limit("30/minute")
async def add_message_with_file(
    request: Request,
    chat_id: str,
    content: str = Form(...),
    file: Optional[UploadFile] = File(None),
):
    # Validate file size if present
    if file:
        file_size = 0
        content_bytes = await file.read()
        file_size = len(content_bytes)
        
        if file_size > settings.max_file_size:
            logger.warning(f"File upload rejected: size {file_size} exceeds limit {settings.max_file_size}")
            raise HTTPException(
                status_code=413,
                detail=f"File size exceeds limit of {settings.max_file_size / (1024*1024):.0f}MB"
            )
        
        # Validate file type
        allowed_extensions = {"pdf", "doc", "docx", "txt", "png", "jpg", "jpeg"}
        file_ext = file.filename.split(".")[-1].lower() if file.filename else ""
        if file_ext not in allowed_extensions:
            logger.warning(f"File upload rejected: invalid extension {file_ext}")
            raise HTTPException(
                status_code=400,
                detail=f"File type not allowed. Allowed: {', '.join(allowed_extensions)}"
            )
        
        # Reset file position for later reading
        await file.seek(0)
    
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
        
    created_at = now_iso()
    file_id = None
    if file:
        file_id = make_id("file")
        # In a real scenario, write file.file to disk / S3 here
        await db.files.insert_one({
            "file_id": file_id,
            "filename": file.filename,
            "chat_id": chat_id,
            "uploaded_at": created_at
        })
        content += f" [Attachment: {file.filename}]"

    user_message = {
        "id": make_id("msg"),
        "chat_id": chat_id,
        "sender": "user",
        "content": content,
        "file_id": file_id,
        "created_at": created_at
    }

    assistant_message = {
        "id": make_id("msg"),
        "chat_id": chat_id,
        "sender": "ai",
        "content": build_demo_reply(content),
        "created_at": now_iso(),
    }

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$push": {"messages": {"$each": [user_message, assistant_message]}},
            "$set": {"updated_at": now_iso()},
        },
    )
    logger.info(f"Message added to chat {chat_id}")
    return {"chat_id": chat_id, "user_message": user_message, "assistant_message": assistant_message}


@app.get("/users/{user_id}/search")
@limiter.limit("30/minute")
async def search_chats(request: Request, user_id: str, query: str):
    # Searches chats where user messages contain the query
    cursor = db.chats.find({"owner_id": user_id, "messages.content": {"$regex": query, "$options": "i"}})
    chats = [chat_to_response(chat) async for chat in cursor]
    logger.info(f"Search performed for user {user_id} with query: {query}")
    return {"items": chats}
