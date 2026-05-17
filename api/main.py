import asyncio
import logging
import uuid
import os
import sys
import warnings
import asyncio
from datetime import UTC, datetime
from typing import Any

<<<<<<< HEAD
from fastapi import FastAPI, HTTPException, Request, Body
=======
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

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
>>>>>>> 9ef9e7cfa2babf47fbaf0f1b562565d9e14d1e44
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
<<<<<<< HEAD
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
=======
import logging


# Configure logging to hide /api/ping requests
class HidePingFilter(logging.Filter):
    def filter(self, record):
        # Hide /api/ping from access logs
        if "/api/ping" in str(record.getMessage()):
            return False
        return True


# Apply filter to uvicorn access logs
logging.getLogger("uvicorn.access").addFilter(HidePingFilter())
>>>>>>> 9ef9e7cfa2babf47fbaf0f1b562565d9e14d1e44


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

<<<<<<< HEAD
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

mongo_client: AsyncIOMotorClient | None = None
db: AsyncIOMotorDatabase | None = None
=======
@app.get("/api/ping")
async def ping():
    return {"status": "ok"}

mongo_client = AsyncIOMotorClient(settings.mongodb_uri)
db: AsyncIOMotorDatabase = mongo_client[settings.mongodb_db]
>>>>>>> 9ef9e7cfa2babf47fbaf0f1b562565d9e14d1e44


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


class SummarizeRequest(BaseModel):
    text: str = Field(min_length=1)


def now_iso() -> str:
    return datetime.now(UTC).isoformat()


def make_id(prefix: str) -> str:
    return f"{prefix}_{uuid.uuid4().hex[:12]}"


import requests

API_KEYS = []
def load_api_keys():
    global API_KEYS
    key_path = os.path.join(os.path.dirname(__file__), "api_keys.csv")
    try:
        if os.path.exists(key_path):
            with open(key_path, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        API_KEYS.append(line)
    except Exception as e:
        print(f"Warning: Could not load api_keys.csv: {e}")

load_api_keys()
_current_key_index = 0

def call_gemini_api_sync(prompt: str, system_prompt: str, chat_history: list) -> str:
    global _current_key_index
    if not API_KEYS:
        return "Error: No API keys configured in api_keys.csv."

    contents = []
    for msg in chat_history:
        role = "user" if msg.get("sender") == "user" else "model"
        contents.append({"role": role, "parts": [{"text": msg.get("content", "")}]})
        
    contents.append({"role": "user", "parts": [{"text": prompt}]})

    payload = {
        "contents": contents
    }
    if system_prompt:
        payload["systemInstruction"] = {"parts": [{"text": system_prompt}]}

    for _ in range(len(API_KEYS)):
        key = API_KEYS[_current_key_index]
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key={key}"
        
        try:
            resp = requests.post(url, json=payload, timeout=30)
            if resp.status_code == 200:
                data = resp.json()
                try:
                    return data["candidates"][0]["content"]["parts"][0]["text"]
                except (KeyError, IndexError):
                    return "Error: Unexpected response format from Gemini."
            elif resp.status_code == 429:
                print(f"API Key {_current_key_index} rate limited. Trying next key...")
                _current_key_index = (_current_key_index + 1) % len(API_KEYS)
                continue
            else:
                return f"Error: Gemini API returned status {resp.status_code}: {resp.text}"
        except Exception as e:
            return f"Error: Request to Gemini failed: {e}"
            
    return "Error: All API keys are rate limited or unavailable."

async def generate_ai_reply(prompt: str, system_prompt: str, chat_history: list) -> str:
    return await asyncio.to_thread(call_gemini_api_sync, prompt, system_prompt, chat_history)


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
<<<<<<< HEAD
    if db is None:
        raise RuntimeError("Database is not initialized")
    await db.users.create_index("user_id", unique=True)
    await db.users.create_index("email", unique=True, sparse=True)
=======
    """Create database indexes with error handling."""
    try:
        await db.users.create_index("user_id", unique=True)
        await db.users.create_index("email", unique=True, sparse=True)
>>>>>>> 9ef9e7cfa2babf47fbaf0f1b562565d9e14d1e44

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
<<<<<<< HEAD
    global mongo_client, db
    loop = asyncio.get_running_loop()
    mongo_client = AsyncIOMotorClient(settings.mongodb_uri, io_loop=loop)
    db = mongo_client[settings.mongodb_db]
    await ensure_indexes()
=======
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
        get_bart_summarizer()
        
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
    
>>>>>>> 9ef9e7cfa2babf47fbaf0f1b562565d9e14d1e44


@app.on_event("shutdown")
async def on_shutdown() -> None:
    if mongo_client is not None:
        mongo_client.close()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/ping")
async def ping() -> dict[str, str]:
    """Silent connectivity check endpoint - minimal logging"""
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
    new_message = {
        "id": make_id("msg"),
        "chat_id": chat_id,
        "sender": payload.sender,
        "content": payload.content,
        "created_at": created_at,
        "user_id": payload.user_id,
    }

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$push": {"messages": new_message},
            "$set": {"updated_at": now_iso()},
        },
    )

    return {
        "chat_id": chat_id,
        "message": new_message,
    }


@app.post("/chats/{chat_id}/generate_ai")
async def generate_ai(chat_id: str) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")

    system_prompt = chat.get("system_prompt", settings.default_system_prompt)
    chat_history = chat.get("messages", [])
    
    prompt = "Continue the conversation."
    context_history = chat_history

    if chat_history and chat_history[-1].get("sender") == "user":
        prompt = chat_history[-1].get("content", "")
        context_history = chat_history[:-1]

    ai_content = await generate_ai_reply(prompt, system_prompt, context_history)

    assistant_message = {
        "id": make_id("msg"),
        "chat_id": chat_id,
        "sender": "ai",
        "content": ai_content,
        "created_at": now_iso(),
        "user_id": None,
    }

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$push": {"messages": assistant_message},
            "$set": {"updated_at": now_iso()},
        },
    )

    logger.info(f"Message added to chat {chat_id}")
    return {
        "chat_id": chat_id,
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
from fastapi import Depends, UploadFile, File, Form, Request
import io
from fastapi.responses import StreamingResponse

_whisper_model = None
_kpipeline = None
_bart_summarizer = None

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


def get_bart_summarizer():
    global _bart_summarizer
    if _bart_summarizer is None:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            from transformers import pipeline
            print("Loading BART summarizer locally...")
            _bart_summarizer = pipeline("summarization", model="facebook/bart-large-cnn", device=0)
            print("Successfully loaded BART summarizer on GPU.")
    return _bart_summarizer

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


@app.post("/api/summarize")
async def summarize(payload: SummarizeRequest) -> dict[str, str]:
    """Summarize text to generate chat titles using BART (up to 12 words)."""
    text = payload.text.strip()
    
    # Skip very short messages (less than 2 words)
    if len(text.split()) < 2:
        return {"summary": text[:50]}  # Use original text as title if too short
    
    try:
        summarizer = get_bart_summarizer()
        # BART expects input length max 1024 tokens, limit to first 512 chars
        truncated_text = text[:512]
        
        # Generate chat titles (up to 12 words for more descriptive names)
        result = summarizer(truncated_text, max_length=12, min_length=2, do_sample=False)
        summary = result[0]["summary_text"]
        
        return {"summary": summary}
    except Exception as e:
        import traceback
        traceback.print_exc()
        # Fallback to original text if summarization fails
        return {"summary": text[:50] + "..." if len(text) > 50 else text}


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

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$push": {"messages": user_message},
            "$set": {"updated_at": now_iso()},
        },
    )
<<<<<<< HEAD
    logger.info(f"Message added to chat {chat_id}")
    return {"chat_id": chat_id, "user_message": user_message, "assistant_message": assistant_message}
=======
    return {"chat_id": chat_id, "message": user_message}
>>>>>>> 9ef9e7cfa2babf47fbaf0f1b562565d9e14d1e44


@app.get("/users/{user_id}/search")
@limiter.limit("30/minute")
async def search_chats(request: Request, user_id: str, query: str):
    # Searches chats where user messages contain the query
    cursor = db.chats.find({"owner_id": user_id, "messages.content": {"$regex": query, "$options": "i"}})
    chats = [chat_to_response(chat) async for chat in cursor]
    logger.info(f"Search performed for user {user_id} with query: {query}")
    return {"items": chats}
