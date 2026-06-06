from __future__ import annotations

import uuid
import os
import sys
import warnings
import asyncio
from datetime import UTC, datetime
from typing import Any
from google import genai
from google.genai import types

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

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
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


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db: str = "legalease"
    api_base_url: str = "http://127.0.0.1:8000"
    default_system_prompt: str = (
        "You are LegalEase, an elite, highly sophisticated legal-focused AI assistant. "
        "Your mission is to provide authoritative, structured, and extremely practical legal guidance while maintaining "
        "an objective, supportive, and professional tone.\n\n"
        "### PRESENTATION AND FORMATTING RULES:\n"
        "- ALWAYS format your response using beautifully structured GitHub Flavored Markdown (GFM).\n"
        "- USE clear headings (###), bold styling for emphasis, and bulleted or numbered lists for logical steps.\n"
        "- USE professional Markdown tables whenever presenting comparisons, timelines, fee structures, or structured data.\n"
        "- USE Markdown blockquotes (>) to highlight warnings, critical notifications, or essential cautions.\n"
        "- Keep paragraphs cohesive and short. Avoid dense blocks of text to maximize scannability.\n\n"
        "### STRUCTURAL GUIDELINES (Use these sections for a comprehensive answer):\n"
        "1. **### Executive Summary / Quick Answer**: Start with a concise, direct 2-3 sentence overview answering the user's core query immediately.\n"
        "2. **### Detailed Guidance**: Provide a thorough, structured breakdown of the legal concepts, rights, obligations, or processes. Use lists, bold key terms, and tables here for maximum readability.\n"
        "3. **### Practical Recommendations**: List actionable, clear steps the user can take (e.g., specific documents to gather, questions to ask, or registries to check).\n"
        "4. **### Jurisdiction & Legal Disclaimer**: Always include a standardized blockquote (>) emphasizing that your output is for educational and informational purposes only, does not constitute official legal counsel or establish an attorney-client relationship, and strongly advise consulting a qualified lawyer licensed in their specific jurisdiction."
    )


settings = Settings()

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, chat_id: str):
        await websocket.accept()
        if chat_id not in self.active_connections:
            self.active_connections[chat_id] = []
        self.active_connections[chat_id].append(websocket)

    def disconnect(self, websocket: WebSocket, chat_id: str):
        if chat_id in self.active_connections:
            if websocket in self.active_connections[chat_id]:
                self.active_connections[chat_id].remove(websocket)
            if not self.active_connections[chat_id]:
                del self.active_connections[chat_id]

    async def broadcast(self, message: dict, chat_id: str):
        if chat_id in self.active_connections:
            for connection in self.active_connections[chat_id]:
                try:
                    await connection.send_json(message)
                except Exception:
                    pass

manager = ConnectionManager()

app = FastAPI(title="LegalEase API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/ping")
async def ping():
    return {"status": "ok"}

mongo_client = AsyncIOMotorClient(settings.mongodb_uri)
db: AsyncIOMotorDatabase = mongo_client[settings.mongodb_db]


class CreateChatRequest(BaseModel):
    title: str = "New Chat"


class UpdateChatRequest(BaseModel):
    title: str | None = None
    is_pinned: bool | None = None
    is_shared: bool | None = None


class InviteCollaboratorRequest(BaseModel):
    username: str


class AddMessageRequest(BaseModel):
    user_id: str | None = None
    sender: str = Field(default="user", pattern="^(user|ai)$")
    content: str = Field(min_length=1)


class UpdateMessageRequest(BaseModel):
    content: str = Field(min_length=1)


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

def call_gemini_api_sync(prompt: str, system_prompt: str, chat_history: list, file_paths: list[str] = None) -> str:
    global _current_key_index
    if not API_KEYS:
        return "Error: No API keys configured in api_keys.csv."
    
    for _ in range(len(API_KEYS)):
        key = API_KEYS[_current_key_index]
        try:
            client = genai.Client(api_key=key)
            
            # Format history for the new SDK
            history = []
            for msg in chat_history:
                role = "user" if msg.get("sender") == "user" else "model"
                history.append(types.Content(
                    role=role, 
                    parts=[types.Part(text=msg.get("content", ""))]
                ))
            
            # Start chat session with account-specific model name
            chat_session = client.chats.create(
                model='gemini-flash-latest',
                config=types.GenerateContentConfig(
                    system_instruction=types.Content(parts=[types.Part(text=system_prompt)]),
                ),
                history=history
            )
            
            # Prepare message parts (text + files)
            message_parts = []
            if file_paths:
                for path in file_paths:
                    if os.path.exists(path):
                        # Upload file via SDK
                        uploaded_file = client.files.upload(file=path)
                        message_parts.append(uploaded_file)
            
            message_parts.append(prompt)
            
            # Send message
            response = chat_session.send_message(message=message_parts)
            return response.text

        except Exception as e:
            err = str(e).lower()
            if "429" in err or "quota" in err or "rate" in err:
                print(f"Key {_current_key_index} rate limited, rotating...")
                _current_key_index = (_current_key_index + 1) % len(API_KEYS)
                continue
            return f"Error: Gemini SDK call failed: {e}"
            
    return "Error: All keys exhausted or failed."

async def generate_ai_reply(prompt: str, system_prompt: str, chat_history: list, file_paths: list[str] = None) -> str:
    return await asyncio.to_thread(call_gemini_api_sync, prompt, system_prompt, chat_history, file_paths)


def chat_to_response(chat: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": chat["chat_id"],
        "user_id": chat["owner_id"],
        "collaborators": chat.get("collaborators", []),
        "title": chat.get("title", "New Chat"),
        "created_at": chat["created_at"],
        "updated_at": chat["updated_at"],
        "is_pinned": chat.get("is_pinned", False),
        "is_shared": chat.get("is_shared", False),
        "messages": chat.get("messages", []),
    }


async def ensure_indexes() -> None:
    """Create database indexes with error handling."""
    try:
        await db.users.create_index("user_id", unique=True)
        await db.users.create_index("email", unique=True, sparse=True)

        await db.chats.create_index("chat_id", unique=True)
        await db.chats.create_index([("owner_id", 1), ("updated_at", -1)])

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
    cursor = db.chats.find({"$or": [{"owner_id": user_id}, {"collaborators": user_id}]}).sort("updated_at", -1)
    chats = [chat_to_response(chat) async for chat in cursor]
    return {"items": chats}


@app.post("/users/{user_id}/chats")
async def create_chat(user_id: str, payload: CreateChatRequest) -> dict[str, Any]:
    chat_id = make_id("chat")
    created_at = now_iso()
    doc = {
        "chat_id": chat_id,
        "owner_id": user_id,
        "collaborators": [],
        "title": payload.title.strip() or "New Chat",
        "is_pinned": False,
        "is_shared": False,
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
    if payload.is_shared is not None:
        updates["is_shared"] = payload.is_shared

    await db.chats.update_one({"chat_id": chat_id}, {"$set": updates})
    updated = await db.chats.find_one({"chat_id": chat_id})
    if not updated:
        raise HTTPException(status_code=404, detail="Chat not found")
    return chat_to_response(updated)


@app.post("/chats/{chat_id}/invite")
async def invite_collaborator(chat_id: str, payload: InviteCollaboratorRequest) -> dict[str, Any]:
    chat = await db.chats.find_one({"chat_id": chat_id})
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
        
    user = await db.users.find_one({"username": payload.username})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user_id_to_add = user["user_id"]
    
    if user_id_to_add == chat.get("owner_id"):
        return {"success": True, "message": "User is already the owner."}
        
    collaborators = chat.get("collaborators", [])
    if user_id_to_add in collaborators:
        return {"success": True, "message": "User is already a collaborator."}
        
    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$push": {"collaborators": user_id_to_add},
            "$set": {
                "is_shared": True,
                "updated_at": now_iso()
            }
        }
    )
    
    return {"success": True, "message": f"User {payload.username} added as collaborator."}


@app.delete("/chats/{chat_id}")
async def delete_chat(chat_id: str) -> dict[str, bool]:
    # 1. Find and delete files from disk
    files_cursor = db.files.find({"chat_id": chat_id})
    async for file_doc in files_cursor:
        file_path = file_doc.get("file_path")
        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception as e:
                print(f"Error deleting file {file_path}: {e}")
    
    # 2. Delete file records from DB
    await db.files.delete_many({"chat_id": chat_id})
    
    # 3. Delete the chat itself
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

    await manager.broadcast({
        "type": "new_message",
        "chat_id": chat_id,
        "message": new_message
    }, chat_id)

    return {
        "chat_id": chat_id,
        "message": new_message,
    }


@app.websocket("/ws/chats/{chat_id}")
async def websocket_endpoint(websocket: WebSocket, chat_id: str):
    await manager.connect(websocket, chat_id)
    try:
        while True:
            # We don't process incoming messages from WS, only broadcast
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, chat_id)


class GenerateAiRequest(BaseModel):
    chat_id: str | None = None
    messages: list[dict[str, Any]] | None = None
    system_prompt: str | None = None
    update_context: bool = True
    use_context: bool = False


# --- Chat endpoints ---


async def update_user_context_from_interaction(owner_id: str, user_message: str, ai_reply: str):
    """
    Calls Gemini in the background to summarize and extract relevant user context details
    from a single message-reply turn, and appends it to the user's context in MongoDB.
    Checks existing context first to avoid duplicating known details.
    """
    try:
        # 1. Fetch existing user context first to check for duplicates
        user_doc = await db.users.find_one({"user_id": owner_id})
        if not user_doc:
            print(f"⚠️ Warning: User '{owner_id}' not found in the users collection. Context update skipped.")
            return
            
        existing_context = user_doc.get("context", "").strip()

        # 2. Build a specialized prompt that feeds in existing context
        summarizer_prompt = (
            "Analyze the following conversation turn between a user and their AI legal assistant. "
            "Identify and extract any new, specific facts about the user's individual profile (e.g., location/jurisdiction, "
            "occupation, specific legal disputes/cases, current business entities, assets, or immediate legal goals).\n\n"
            f"Here is the user's EXISTING KNOWN CONTEXT:\n{existing_context or 'None'}\n\n"
            "CRITICAL INSTRUCTIONS:\n"
            "- Extract ONLY specific facts that are completely NEW and not already documented or implied in the existing known context.\n"
            "- Focus purely on factual user profile data. Do not summarize general legal concepts or conversational filler.\n"
            "- Format the output as a single, extremely concise bullet point starting with a hyphen (e.g., '- User is a freelance graphic designer based in California').\n"
            "- The bullet point must be under 20 words.\n"
            "- If there are no new facts, or if all mentioned details are already represented in the existing context, you MUST return exactly the word 'None'.\n\n"
            "Current Conversation Turn:\n"
            f"User Message: {user_message}\n"
            f"AI Reply: {ai_reply}\n\n"
            "Return only the concise bullet point or 'None'. No introduction, no conversational text."
        )
        
        # 3. Call the Gemini API to get the unique summary
        extracted_info = await generate_ai_reply(
            prompt=summarizer_prompt,
            system_prompt="You are an expert fact extractor. Extract only specific, unique user profile facts as a single concise bullet point under 20 words, or return 'None'.",
            chat_history=[]
        )
        
        extracted_info = extracted_info.strip().strip('"').strip("'")
        if extracted_info.startswith("Error:"):
            print(f"⚠️ Warning: Context extraction failed with error: {extracted_info}")
            return
            
        if not extracted_info or extracted_info.lower() == "none" or "none." in extracted_info.lower():
            return
            
        # 4. Append to user context
        if existing_context:
            new_context = f"{existing_context}\n- {extracted_info}"
        else:
            new_context = f"- {extracted_info}"
            
        await db.users.update_one(
            {"user_id": owner_id},
            {"$set": {"context": new_context}}
        )
        print(f"✓ Updated context for user {owner_id}: appended '{extracted_info}'")
    except Exception as e:
        print(f"⚠️ Error updating user context: {e}")


@app.post("/api/generate_ai")
async def generate_ai(payload: GenerateAiRequest, request: Request, background_tasks: BackgroundTasks) -> dict[str, Any]:
    # 1. Gather Context
    chat_history = []
    system_prompt = payload.system_prompt or settings.default_system_prompt
    owner_id = None
    
    if payload.chat_id:
        chat = await db.chats.find_one({"chat_id": payload.chat_id})
        if chat:
            chat_history = chat.get("messages", [])
            owner_id = chat.get("owner_id")
    elif payload.messages is not None:
        chat_history = payload.messages

    # Try to extract user_id from Authorization header if owner_id is still None
    if not owner_id:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload_data = jwt.decode(token, "my_super_secret_jwt_key_for_legalease", algorithms=["HS256"])
                owner_id = payload_data.get("user_id")
            except Exception as e:
                print(f"Failed to decode token in generate_ai: {e}")

    # NEW: Fetch and inject user background context if requested and owner is present
    if payload.use_context and owner_id:
        user_doc = await db.users.find_one({"user_id": owner_id})
        if user_doc:
            user_context = user_doc.get("context", "").strip()
            if user_context:
                system_prompt = (
                    f"{system_prompt}\n\n"
                    "=== USER BACKGROUND DETAILS ===\n"
                    "You must tailor your legal analysis using the following facts about the user's specific context:\n"
                    f"{user_context}\n"
                    "================================="
                )

    # 2. Extract prompt and current files
    prompt = "Continue the conversation."
    context_history = chat_history
    file_paths = []
    
    if chat_history and chat_history[-1].get("sender") == "user":
        last_msg = chat_history[-1]
        prompt = last_msg.get("content", "")
        context_history = chat_history[:-1]
        
        # Check for file associated with this specific message
        file_id = last_msg.get("file_id")
        if file_id:
            file_doc = await db.files.find_one({"file_id": file_id})
            if file_doc and file_doc.get("file_path"):
                file_paths.append(file_doc["file_path"])
        
    # 3. Generate Reply
    ai_content = await generate_ai_reply(prompt, system_prompt, context_history, file_paths)
    
    assistant_message = {
        "id": make_id("msg"),
        "sender": "ai",
        "content": ai_content,
        "created_at": now_iso(),
    }
    
    # 4. If we have a valid owner and update_context is enabled, queue a background task (skip on errors)
    if owner_id and prompt and payload.update_context and not ai_content.startswith("Error:"):
        background_tasks.add_task(
            update_user_context_from_interaction,
            owner_id=owner_id,
            user_message=prompt,
            ai_reply=ai_content
        )
    
    # 5. Return without saving (App is responsible for persistence)
    if payload.chat_id:
        await manager.broadcast({
            "type": "new_message",
            "chat_id": payload.chat_id,
            "message": assistant_message
        }, payload.chat_id)
        
    return {
        "assistant_message": assistant_message,
    }


class GenerateLiveRequest(BaseModel):
    chat_id: str | None = None
    messages: list[dict[str, Any]] | None = None


@app.post("/api/generate_live")
async def generate_live(payload: GenerateLiveRequest) -> dict[str, Any]:
    """
    Specialized AI generation for Live Calls.
    Optimized for short, concise, and conversational legal guidance.
    """
    # Live call system prompt: keeps Gemini brief and natural, like a voice conversation
    live_system_prompt = (
        "You are LegalEase, a elite legal expert speaking directly with the user on a LIVE VOICE CALL.\n"
        "Because your response will be read aloud instantly by a Text-to-Speech (TTS) engine, you must adhere "
        "to these strict rules for oral delivery:\n"
        "- Respond in a warm, professional, highly natural, and conversational speaking voice. Imagine you are talking over the phone.\n"
        "- Keep it extremely brief: 1 to 3 short, easy-to-understand sentences. Never exceed 4 sentences.\n"
        "- ABSOLUTELY NO MARKDOWN. Never use bullet points, numbered lists, headings, bold asterisks (**), dashes, or special characters. Use plain, flowing text.\n"
        "- AVOID all introductory filler, transition words, or repetitious confirmations like 'Certainly!', 'That is a great question!', 'Sure, I can help with that.' Get straight to the substantive answer.\n"
        "- State legal concepts simply and naturally, ending with a quick, soft reminder to consult local counsel if complex details are involved.\n"
        "- If asked non-legal questions, respond naturally, warmly, and briefly."
    )

    # Resolve chat history from DB or from the payload directly
    chat_history = []
    if payload.chat_id:
        chat = await db.chats.find_one({"chat_id": payload.chat_id})
        if chat:
            chat_history = chat.get("messages", [])
    elif payload.messages is not None:
        chat_history = payload.messages

    # Extract the latest user message as the prompt, use the rest as history
    prompt = "Continue the conversation."
    context_history = chat_history
    if chat_history and chat_history[-1].get("sender") == "user":
        prompt = chat_history[-1].get("content", "")
        context_history = chat_history[:-1]

    # Call Gemini with the live conversation system prompt
    ai_content = await generate_ai_reply(prompt, live_system_prompt, context_history)

    assistant_message = {
        "id": make_id("msg"),
        "sender": "ai",
        "content": ai_content,
        "created_at": now_iso(),
    }

    return {
        "assistant_message": assistant_message,
    }


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


@app.post("/api/summarize")
async def summarize(payload: SummarizeRequest) -> dict[str, str]:
    """Summarize text to generate chat titles using Gemini (up to 6 words)."""
    text = payload.text.strip()
    
    # Skip very short messages
    if len(text.split()) < 2:
        return {"summary": text[:50]}
    
    try:
        prompt = (
            f"Generate a professional, short, and highly descriptive chat title representing the core topic of this message: \"{text}\".\n\n"
            "Format requirements:\n"
            "- The title MUST be between 2 and 4 words (e.g., 'Trademark Application Guide', 'NDA Breach Analysis', 'Tenant Rights Query').\n"
            "- Respond ONLY with the plain title text.\n"
            "- Do NOT include any quotation marks, markdown wrappers, prefixes, or end punctuation."
        )
        title = await generate_ai_reply(
            prompt,
            "You are an expert legal title generator. Your sole function is to produce concise, elegant 2-to-4 word titles with absolutely no conversational filler, quotes, or markdown.",
            []
        )
        if title.startswith("Error:"):
            return {"summary": text[:50] + "..." if len(text) > 50 else text}
        return {"summary": title.strip().strip('"').strip()}
    except Exception as e:
        return {"summary": text[:50] + "..." if len(text) > 50 else text}


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = "my_super_secret_jwt_key_for_legalease"
ALGORITHM = "HS256"

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str
    context: str = ""

class LoginRequest(BaseModel):
    username: str
    password: str

class UpdateUserContextRequest(BaseModel):
    context: str

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
        "context": payload.context,
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

@app.get("/users/{user_id}")
async def get_user_profile(user_id: str):
    user = await db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "user_id": user["user_id"],
        "username": user["username"],
        "email": user["email"],
        "context": user.get("context", "")
    }

@app.patch("/users/{user_id}/context")
async def update_user_context(user_id: str, payload: UpdateUserContextRequest):
    user = await db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    await db.users.update_one(
        {"user_id": user_id},
        {"$set": {"context": payload.context}}
    )
    return {"status": "success", "context": payload.context}

@app.delete("/users/{user_id}")
async def delete_user_account(user_id: str):
    user = await db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 1. Delete all user chats
    await db.chats.delete_many({"owner_id": user_id})
    
    # 2. Delete user account document
    await db.users.delete_one({"user_id": user_id})
    
    return {"status": "success", "message": "User account and all related chats deleted permanently."}

@app.delete("/users/{user_id}/chats")
async def clear_user_chats(user_id: str):
    user = await db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete all chats belonging to this user
    await db.chats.delete_many({"owner_id": user_id})
    return {"status": "success", "message": "All chat history cleared successfully."}

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
        
        # Ensure uploads directory exists
        upload_dir = os.path.join(os.path.dirname(__file__), "uploads")
        os.makedirs(upload_dir, exist_ok=True)
        
        # Save file to disk
        file_path = os.path.join(upload_dir, f"{file_id}_{file.filename}")
        with open(file_path, "wb") as f:
            f.write(await file.read())

        await db.files.insert_one({
            "file_id": file_id,
            "filename": file.filename,
            "file_path": file_path,
            "chat_id": chat_id,
            "uploaded_at": created_at
        })

    user_message = {
        "id": make_id("msg"),
        "sender": "user",
        "content": content,
        "file_id": file_id,
        "filename": file.filename if file else None,
        "created_at": created_at
    }

    await db.chats.update_one(
        {"chat_id": chat_id},
        {
            "$push": {"messages": user_message},
            "$set": {"updated_at": now_iso()},
        },
    )
    return {"chat_id": chat_id, "message": user_message}

@app.get("/users/{user_id}/search")
async def search_chats(user_id: str, query: str):
    # Searches chats where user messages contain the query
    cursor = db.chats.find({"owner_id": user_id, "messages.content": {"$regex": query, "$options": "i"}})
    chats = [chat_to_response(chat) async for chat in cursor]
    return {"items": chats}

from fastapi.responses import FileResponse
@app.get("/api/files/{file_id}")
async def download_file(file_id: str):
    file_doc = await db.files.find_one({"file_id": file_id})
    if not file_doc:
        raise HTTPException(status_code=404, detail="File record not found")
    
    file_path = file_doc.get("file_path")
    if not file_path or not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Physical file not found on server")
        
    return FileResponse(
        file_path, 
        filename=file_doc.get("filename", "download"),
        media_type='application/octet-stream'
    )
