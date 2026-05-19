# LegalEase API (Local Dev)

This folder contains the local FastAPI server for LegalEase.

## Stack

- Python + FastAPI
- MongoDB (local)

## Prerequisites

- Python 3.11+
- MongoDB running on `mongodb://localhost:27017`

## Setup

1. **Initialize database** (if you haven't already):

   ```bash
   cd ../db
   pip install -r requirements.txt
   python init_db.py
   ```

   See [db/README.md](../db/README.md) for detailed database setup.

2. **Set up API**:
   ```bash
   cd ../api
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   copy .env.example .env
   ```

## Run Server

```bash
cd api
.venv\Scripts\activate
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Or from the repository root:

```bash
python -m uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

Server URL: `http://127.0.0.1:8000`

## Health Check

```bash
curl http://127.0.0.1:8000/health
```

Expected response:

```json
{ "status": "ok" }
```

## Endpoints

- `GET /health`
- `GET /users/{user_id}/chats`
- `POST /users/{user_id}/chats`
- `GET /chats/{chat_id}`
- `PATCH /chats/{chat_id}`
- `DELETE /chats/{chat_id}`
- `POST /chats/{chat_id}/messages`
- `POST /chats/{chat_id}/share`
- `GET /share/{share_token}`

## Example Flow

1. Create chat:

```bash
curl -X POST http://127.0.0.1:8000/users/user1/chats -H "Content-Type: application/json" -d "{\"title\":\"New Chat\"}"
```

2. Add message:

```bash
curl -X POST http://127.0.0.1:8000/chats/<chat_id>/messages -H "Content-Type: application/json" -d "{\"user_id\":\"user1\",\"sender\":\"user\",\"content\":\"Hello\"}"
```

3. List chats:

```bash
curl http://127.0.0.1:8000/users/user1/chats
```

## Notes

- This is local-first demo infrastructure.
- AI response is currently a demo backend response. Replace `build_demo_reply()` in `main.py` with Gemini integration.
- Files are expected to be stored locally under `C:\legalEaseDB`.
