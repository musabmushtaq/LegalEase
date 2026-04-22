from __future__ import annotations

import uuid
import os
import sys
import warnings
from datetime import UTC, datetime
from typing import Any

# Suppress deprecation warnings from dependencies
warnings.filterwarnings("ignore", category=DeprecationWarning, module=".*pkg_resources.*")
warnings.filterwarnings("ignore", message=".*pkg_resources is deprecated.*")
warnings.filterwarnings("ignore", message=".*Defaulting repo_id.*")
warnings.filterwarnings("ignore", message=".*unauthenticated requests.*")
warnings.filterwarnings("ignore", message=".*You are sending unauthenticated.*")
# Suppress Hugging Face Hub warnings
os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"

# Add nvidia CUDA dll paths locally if on windows so CTranslate2 can find cublas64_12.dll
if os.name == "nt":
    import site
    packages = site.getsitepackages()
    for p in packages:
        cublas = os.path.join(p, "nvidia", "cublas", "bin")
        cudnn = os.path.join(p, "nvidia", "cudnn", "bin")
        if os.path.exists(cublas):
            os.add_dll_directory(cublas)
            os.environ["PATH"] += os.pathsep + cublas
        if os.path.exists(cudnn):
            os.add_dll_directory(cudnn)
            os.environ["PATH"] += os.pathsep + cudnn

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
    """Create database indexes with error handling."""
    try:
        await db.users.create_index("user_id", unique=True)
        await db.users.create_index("email", unique=True, sparse=True)

        await db.chats.create_index("chat_id", unique=True)
        await db.chats.create_index([("owner_id", 1), ("updated_at", -1)])
        await db.chats.create_index("share_token", sparse=True)

        await db.files.create_index("file_id", unique=True)
        await db.files.create_index([("user_id", 1), ("uploaded_at", -1)])
    except Exception as e:
        print(f"⚠️  Warning: Could not create database indexes: {e}")
        # Don't raise - continue even if indexes fail
        # (they may already exist or MongoDB might not be available)


@app.on_event("startup")
async def on_startup() -> None:
    """Initialize models and create database indexes on startup."""
    try:
        print("\n\nInitializing Systems")
        print("If you haven't run this before, a download from Hugging Face will start in the background.")
        print("=" * 60)
        await ensure_indexes()
        print("Database ready")
        
        
        # Pre-load the AI models before accepting requests
        print("=" * 60)
        get_whisper_model()
        print("=" * 60)
        get_kpipeline()
        
        print("=" * 60)
        print("All systems ready! API accepting requests...")
        print("=" * 60 + "\n")
    except Exception as e:
        print(f"\n❌ Critical error during startup: {e}")
        print("=" * 60 + "\n")
        raise


@app.on_event("shutdown")
async def on_shutdown() -> None:
    """Clean up resources on shutdown."""
    mongo_client.close()
    


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/ping")
async def ping() -> dict[str, str]:
    """Silent connectivity check endpoint - minimal logging"""
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


@app.patch("/chats/{chat_id}/messages/{message_id}")
async def update_message(chat_id: str, message_id: str, payload: UpdateMessageRequest) -> dict[str, Any]:
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

    return {
        "chat_id": chat_id,
        "message_id": message_id,
        "content": payload.content,
        "edited_at": messages[message_index]["edited_at"],
    }


@app.delete("/chats/{chat_id}/messages/{message_id}")
async def delete_message(chat_id: str, message_id: str) -> dict[str, bool]:
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

    return {"deleted": True}


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

# --- NEW: Auth, Search, and File endpoints ---
import jwt
from passlib.context import CryptContext
from fastapi import Depends, UploadFile, File, Form, Request
import io
from fastapi.responses import StreamingResponse

_whisper_model = None
_kpipeline = None

def get_kpipeline():
    global _kpipeline
    if _kpipeline is None:
        # Suppress Kokoro and Torch warnings
        with warnings.catch_warnings():
            warnings.filterwarnings("ignore", message=".*dropout option.*")
            warnings.filterwarnings("ignore", message=".*weight_norm.*")
            warnings.simplefilter("ignore", FutureWarning)
            warnings.simplefilter("ignore", UserWarning)
            
            from kokoro import KPipeline
            print("Loading Kokoro-82M locally...")
            _kpipeline = KPipeline(lang_code='a') 
            print("Successfully loaded Kokoro-82M.")
    return _kpipeline

@app.post("/api/tts")
async def generate_tts(payload: dict):
    text = payload.get("text", "")
    if not text.strip():
        raise HTTPException(status_code=400, detail="Text is empty")

    import soundfile as sf
    import numpy as np

    pipeline = get_kpipeline()
    generator = pipeline(text, voice='af_heart', speed=1)
    
    pieces = []
    try:
        for gs, ps, audio in generator:
            pieces.append(audio)
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
        
    if not pieces:
        raise HTTPException(status_code=500, detail="No audio generated")
        
    audio_concat = np.concatenate(pieces)
    
    # Convert to WAV in memory
    buf = io.BytesIO()
    sf.write(buf, audio_concat, 24000, format='WAV')
    buf.seek(0)
    
    return StreamingResponse(buf, media_type="audio/wav")

def get_whisper_model():
    global _whisper_model
    if _whisper_model is None:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            from faster_whisper import WhisperModel
            print("Loading Whisper large-v3-turbo locally to GPU...")
            
            try:
                # We explicitly tell it to try 'cuda' (your 4GB VRAM GPU) and use int8 quantization to save memory
                _whisper_model = WhisperModel(
                    "deepdml/faster-whisper-large-v3-turbo-ct2", 
                    device="cuda", 
                    compute_type="int8"
                )
                print("Successfully loaded Whisper on GPU (CUDA).")
            except Exception as e:
                print(f"Failed to load on CUDA or specific hf model: {e}.")
                print("Falling back to CPU / default 'large-v3'...")
                _whisper_model = WhisperModel(
                    "large-v3", 
                    device="cpu", 
                    compute_type="int8"
                )
    return _whisper_model

@app.post("/api/transcribe_raw")
async def transcribe_raw(request: Request):
    import numpy as np
    try:
        raw_bytes = await request.body()
        if not raw_bytes:
            raise HTTPException(status_code=400, detail="No audio data provided")
        # Ensure it's read as float32 and copy to make it writable & C-contiguous
        audio_array = np.frombuffer(raw_bytes, dtype=np.float32).copy()
        
        model = get_whisper_model()
        # Transcribe expects 16kHz float32 1D numpy array
        segments, info = model.transcribe(audio_array, beam_size=1, word_timestamps=False)
        text = "".join([segment.text for segment in segments])
        return {"text": text.strip()}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = "my_super_secret_jwt_key_for_legalease"
ALGORITHM = "HS256"

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

@app.post("/auth/register")
async def register(payload: RegisterRequest):
    existing = await db.users.find_one({"$or": [{"username": payload.username}, {"email": payload.email}]})
    if existing:
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
    return {"user_id": user_id, "username": payload.username}

@app.post("/auth/login")
async def login(payload: LoginRequest):
    user = await db.users.find_one({"username": payload.username})
    if not user or not pwd_context.verify(payload.password[:72], user["password"]):
        raise HTTPException(status_code=401, detail="Invalid username or password")
    
    token = jwt.encode({"user_id": user["user_id"], "username": user["username"]}, SECRET_KEY, algorithm=ALGORITHM)
    return {"access_token": token, "token_type": "bearer", "user_id": user["user_id"]}

@app.post("/chats/{chat_id}/messages_with_file")
async def add_message_with_file(chat_id: str, content: str = Form(...), file: UploadFile = File(None)):
    # Replaces normal messages endpoint to also handle files
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
    return {"chat_id": chat_id, "user_message": user_message, "assistant_message": assistant_message}

@app.get("/users/{user_id}/search")
async def search_chats(user_id: str, query: str):
    # Searches chats where user messages contain the query
    cursor = db.chats.find({"owner_id": user_id, "messages.content": {"$regex": query, "$options": "i"}})
    chats = [chat_to_response(chat) async for chat in cursor]
    return {"items": chats}
