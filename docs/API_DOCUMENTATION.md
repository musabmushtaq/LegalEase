# LegalEase API Documentation

**Version**: 1.0  
**Base URL**: `http://127.0.0.1:8000` (local development)  
**Authentication**: User ID based (expandable to JWT)  
**Response Format**: JSON

---

## Table of Contents

1. [Authentication](#authentication)
2. [Status Endpoints](#status-endpoints)
3. [User Endpoints](#user-endpoints)
4. [Chat Endpoints](#chat-endpoints)
5. [Message Endpoints](#message-endpoints)
6. [File Endpoints](#file-endpoints)
7. [AI Features](#ai-features)
8. [Live Call Endpoints](#live-call-endpoints)
9. [Sharing & Collaboration](#sharing--collaboration)
10. [Error Handling](#error-handling)
11. [Request/Response Examples](#requestresponse-examples)

---

## Authentication

**Current Implementation**: JWT Token-Based Authentication

All authenticated requests must include the JWT token in the `Authorization` header:

```
Authorization: Bearer <jwt_token>
```

The JWT token contains the user's ID and username, cryptographically signed with a secure key.

**Password Security**:
- Passwords are hashed with bcrypt (cost factor: 12) before persistence in MongoDB
- Plaintext passwords are never stored
- Password length is limited to 72 characters for secure hashing

---

## Status Endpoints

### Health Check

**Endpoint**: `GET /health`

**Description**: Verify API is running

**Response**:

```json
{
  "status": "ok"
}
```

**Status Code**: 200 OK

---

### Ping Endpoint

**Endpoint**: `GET /api/ping`

**Description**: Simple connectivity test (logged separately, bypasses general logs)

**Response**:

```json
{
  "status": "ok"
}
```

**Status Code**: 200 OK

---

## User Endpoints

### Create User (Register)

**Endpoint**: `POST /auth/register`

**Description**: Register a new user account with secure credentials and optional professional context

**Request Body**:

```json
{
  "username": "john_doe",
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "context": "I am a corporate attorney specializing in M&A"
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| username | string | Yes | Unique username (must be unique) |
| email | string | Yes | Valid email address (must be unique) |
| password | string | Yes | Password (will be securely hashed) |
| context | string | No | User's professional context for personalized AI interactions |

**Response** (200 OK):

```json
{
  "user_id": "user_550f35068db3c8f5d3d8e4a2",
  "username": "john_doe"
}
```

**Possible Errors**:
- 400 Bad Request: Username or email already taken
- 422 Unprocessable Entity: Validation error on email format or password

---

### User Login

**Endpoint**: `POST /auth/login`

**Description**: Authenticate user credentials and return a signed JWT access token

**Request Body**:

```json
{
  "username": "john_doe",
  "password": "SecurePassword123!"
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| username | string | Yes | Registered username |
| password | string | Yes | Plaintext password |

**Response** (200 OK):

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user_id": "user_550f35068db3c8f5d3d8e4a2"
}
```

**Possible Errors**:
- 401 Unauthorized: Invalid username or password
- 422 Unprocessable Entity: Validation error on input

---

### Get User Profile

**Endpoint**: `GET /users/{user_id}`

**Description**: Retrieve user account details (username, email, and personal AI context)

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Response** (200 OK):

```json
{
  "user_id": "user_550f35068db3c8f5d3d8e4a2",
  "username": "john_doe",
  "email": "user@example.com",
  "context": "I am a corporate attorney specializing in M&A"
}
```

**Possible Errors**:
- 404 Not Found: User does not exist

---

### Update User Personal Context

**Endpoint**: `PATCH /users/{user_id}/context`

**Description**: Manually override or update the personalized AI background context for this user

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Request Body**:

```json
{
  "context": "- User is a freelance graphic designer based in California.\n- User is facing a copyright infringement issue."
}
```

**Response** (200 OK):

```json
{
  "status": "success",
  "context": "- User is a freelance graphic designer based in California.\n- User is facing a copyright infringement issue."
}
```

**Possible Errors**:
- 404 Not Found: User does not exist
- 422 Unprocessable Entity: Validation error on input

---

### Permanently Delete Account

**Endpoint**: `DELETE /users/{user_id}`

**Description**: Wipe out the user profile, all associated documents/files, and all persistent chat history permanently

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "User account and all related chats deleted permanently."
}
```

**Possible Errors**:
- 404 Not Found: User does not exist

---

### Clear All Chat History

**Endpoint**: `DELETE /users/{user_id}/chats`

**Description**: Wipe all persistent conversation histories from the user's account (retaining profile and context)

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "All chat history cleared successfully."
}
```

**Possible Errors**:
- 404 Not Found: User does not exist

---

## Chat Endpoints

### List User's Chats

**Endpoint**: `GET /users/{user_id}/chats`

**Description**: Retrieve all chats for a user

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Query Parameters** (optional):
| Parameter | Type | Description |
|-----------|------|-------------|
| limit | integer | Max chats to return (default: 100) |
| skip | integer | Offset for pagination (default: 0) |
| pinned_only | boolean | Return only pinned chats (default: false) |

**Response** (200 OK):

```json
{
  "total": 5,
  "chats": [
    {
      "chatId": "chat_a1b2c3d4e5f6g7h8",
      "title": "Contract Review - NDA",
      "isPinned": true,
      "isArchived": false,
      "messageCount": 12,
      "createdAt": "2026-05-20T10:00:00Z",
      "updatedAt": "2026-05-20T10:15:00Z",
      "lastMessage": "Here are my final thoughts on the clause..."
    }
  ]
}
```

**Possible Errors**:

- 404 Not Found: User does not exist

---

### Create New Chat

**Endpoint**: `POST /users/{user_id}/chats`

**Description**: Create a new chat conversation

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Request Body**:

```json
{
  "title": "Contract Review - NDA"
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | No | Chat title (default: "New Chat") |

**Response** (201 Created):

```json
{
  "chatId": "chat_a1b2c3d4e5f6g7h8",
  "ownerId": "user_550f35068db3c8f5d3d8e4a2",
  "title": "Contract Review - NDA",
  "isPinned": false,
  "isArchived": false,
  "messages": [],
  "createdAt": "2026-05-20T10:00:00Z",
  "updatedAt": "2026-05-20T10:00:00Z"
}
```

**Possible Errors**:

- 404 Not Found: User does not exist

---

### Get Chat Details

**Endpoint**: `GET /chats/{chat_id}`

**Description**: Retrieve full chat with all messages

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Response** (200 OK):

```json
{
  "chatId": "chat_a1b2c3d4e5f6g7h8",
  "ownerId": "user_550f35068db3c8f5d3d8e4a2",
  "title": "Contract Review - NDA",
  "isPinned": true,
  "isArchived": false,
  "messages": [
    {
      "messageId": "msg_001",
      "userId": "user_550f35068db3c8f5d3d8e4a2",
      "role": "user",
      "content": "Please review this NDA clause for potential risks.",
      "attachments": [
        {
          "fileId": "file_xyz123",
          "filename": "nda_clause.pdf"
        }
      ],
      "createdAt": "2026-05-20T10:05:00Z"
    },
    {
      "messageId": "msg_002",
      "userId": null,
      "role": "assistant",
      "content": "I've reviewed the NDA clause. Here are my findings:\n\n1. **Standard Language**: The clause uses fairly standard NDA language...",
      "createdAt": "2026-05-20T10:06:00Z"
    }
  ],
  "createdAt": "2026-05-20T10:00:00Z",
  "updatedAt": "2026-05-20T10:06:00Z"
}
```

**Possible Errors**:

- 404 Not Found: Chat does not exist

---

### Update Chat

**Endpoint**: `PATCH /chats/{chat_id}`

**Description**: Update chat title or pin status

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Request Body** (both fields optional):

```json
{
  "title": "Updated Chat Title",
  "is_pinned": true
}
```

**Response** (200 OK):

```json
{
  "chatId": "chat_a1b2c3d4e5f6g7h8",
  "title": "Updated Chat Title",
  "isPinned": true,
  "updatedAt": "2026-05-20T10:30:00Z"
}
```

**Possible Errors**:

- 400 Bad Request: Invalid input
- 404 Not Found: Chat does not exist

---

### Delete Chat

**Endpoint**: `DELETE /chats/{chat_id}`

**Description**: Delete a chat and all its messages

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Response** (204 No Content): No response body

**Possible Errors**:

- 404 Not Found: Chat does not exist

---

### Message Endpoints

### Add Message to Chat

**Endpoint**: `POST /chats/{chat_id}/messages`

**Description**: Persist a user or AI message to the database for a specific chat conversation

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Request Body**:

```json
{
  "user_id": "user_550f35068db3c8f5d3d8e4a2",
  "sender": "user",
  "content": "What are the key differences between an LLC and an S-Corp?"
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | string | No | User identifier |
| sender | string | Yes | Sender role, must be either `"user"` or `"ai"` |
| content | string | Yes | Message text content (min 1 character) |

**Response** (200 OK):

```json
{
  "chat_id": "chat_a1b2c3d4e5f6g7h8",
  "message": {
    "id": "msg_f35068db3c8f5",
    "chat_id": "chat_a1b2c3d4e5f6g7h8",
    "sender": "user",
    "content": "What are the key differences between an LLC and an S-Corp?",
    "created_at": "2026-05-31T12:00:00Z",
    "user_id": "user_550f35068db3c8f5d3d8e4a2"
  }
}
```

**Possible Errors**:
- 404 Not Found: Chat does not exist
- 422 Unprocessable Entity: Validation error on input

---

### Add Message with File (Multipart)

**Endpoint**: `POST /chats/{chat_id}/messages_with_file`

**Description**: Persist a user message along with an uploaded legal document attachment (PDF, DOCX, TXT, or images)

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Request Headers**:

```
Content-Type: multipart/form-data
```

**Request Body** (form-data):
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| content | string | Yes | Message text (e.g., "See attachment") |
| file | file | No | Multipart file data |

**Response** (200 OK):

```json
{
  "chat_id": "chat_a1b2c3d4e5f6g7h8",
  "message": {
    "id": "msg_f35068db3c8f5",
    "sender": "user",
    "content": "See attachment",
    "file_id": "file_abc123xyz789",
    "filename": "contract.pdf",
    "created_at": "2026-05-31T12:00:00Z"
  }
}
```

**Possible Errors**:
- 404 Not Found: Chat does not exist
- 400 Bad Request: File upload error

---

### Edit Message

**Endpoint**: `PATCH /chats/{chat_id}/messages/{message_id}`

**Description**: Edit the text content of a user message. Editing AI messages is disabled.

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |
| message_id | string | Unique message identifier |

**Request Body**:

```json
{
  "content": "Updated message content"
}
```

**Response** (200 OK):

```json
{
  "chat_id": "chat_a1b2c3d4e5f6g7h8",
  "message_id": "msg_f35068db3c8f5",
  "content": "Updated message content",
  "edited_at": "2026-05-31T12:05:00Z"
}
```

**Possible Errors**:
- 400 Bad Request: Attempted to edit an AI message
- 404 Not Found: Chat or message does not exist

---

### Delete Message

**Endpoint**: `DELETE /chats/{chat_id}/messages/{message_id}`

**Description**: Delete a specific message and all subsequent messages in the conversation (standard branch truncation behavior)

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |
| message_id | string | Unique message identifier |

**Response** (200 OK):

```json
{
  "deleted": true
}
```

**Possible Errors**:
- 404 Not Found: Chat or message does not exist

---

## File Endpoints

### Download/View File

**Endpoint**: `GET /api/files/{file_id}`

**Description**: Stream the binary data of an uploaded attachment directly with its proper content-type header

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| file_id | string | Unique file identifier |

**Response**: Binary file stream (with `application/octet-stream` or native MIME)

**Possible Errors**:
- 404 Not Found: File record or physical file on disk does not exist

---

## AI & Generation Endpoints

### Generate AI Reply

**Endpoint**: `POST /api/generate_ai`

**Description**: Call the Gemini AI to generate a legal reply. Automatically reads chat history from DB if `chat_id` is passed, or accepts inline messages. Supports personalized background user-context injection and updating.

**Request Body**:

```json
{
  "chat_id": "chat_a1b2c3d4e5f6g7h8",
  "messages": null,
  "system_prompt": "You are a professional legal contract reviewer...",
  "update_context": true,
  "use_context": true
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| chat_id | string | No | Unique chat identifier. Reads history and file attachments from DB |
| messages | array | No | Inline message array (`[{"sender": "user", "content": "..."}]`) if no `chat_id` |
| system_prompt | string | No | Override system guidance prompt |
| update_context | boolean | No | If `true`, runs a background task to extract user facts from this turn (default: `true`) |
| use_context | boolean | No | If `true`, fetches and injects the user's background details into the system instruction (default: `false`) |

**Response** (200 OK):

```json
{
  "assistant_message": {
    "id": "msg_ai_987654321",
    "sender": "ai",
    "content": "Based on the NDA provided, the liability limitation clause is standard but...",
    "created_at": "2026-05-31T12:00:30Z"
  }
}
```

**Notes**:
- Gemini API errors (rate limits, key exhaustions) are caught and returned safely as an error payload without updating database context.

---

### Summarize Chat Title

**Endpoint**: `POST /api/summarize`

**Description**: Generate a short, descriptive 2-to-4 word conversation title representing the topic of the user's initial message

**Request Body**:

```json
{
  "text": "What are the requirements for starting a trademark application in California?"
}
```

**Response** (200 OK):

```json
{
  "summary": "Trademark Application Requirements"
}
```

**Notes**:
- Falls back to a clean text slice of the query if the AI summarization fails.

---

## Live Call / Voice Endpoints

### Conversational Voice Generator

**Endpoint**: `POST /api/generate_live`

**Description**: Specialized, high-performance Gemini API reply generator tailored for real-time Live Calls. Optimizes outputs to be short, natural, conversational, and list-free for speech synthesis.

**Request Body**:

```json
{
  "chat_id": "chat_a1b2c3d4e5f6g7h8",
  "messages": null
}
```

**Response** (200 OK):

```json
{
  "assistant_message": {
    "id": "msg_live_777",
    "sender": "ai",
    "content": "An LLC protects your personal assets, while an S-Corp offers potential self-employment tax savings. I recommend consulting a CPA for details.",
    "created_at": "2026-05-31T12:00:32Z"
  }
}
```

---

### Transcribe Raw Audio (Whisper)

**Endpoint**: `POST /api/transcribe_raw`

**Description**: Transcribe raw 16kHz float32 binary audio stream directly into text using local **Whisper large-v3-turbo** on GPU

**Request Headers**:

```
Content-Type: application/octet-stream
```

**Request Body**: Raw float32 PCM audio stream bytes

**Response** (200 OK):

```json
{
  "text": "what are the tax differences"
}
```

---

### Text-To-Speech Stream (Kokoro)

**Endpoint**: `POST /api/tts`

**Description**: Generate premium, natural-sounding audio for legal guidance text using local **Kokoro-82M** speech synthesis pipeline

**Request Body**:

```json
{
  "text": "An LLC protects your personal assets."
}
```

**Response** (200 OK): Binary streaming audio chunk (`audio/wav`)

---

### Record Live Call Interaction

**Endpoint**: `POST /api/live-call/record-interaction`

**Description**: Save a voice interaction (transcribed text + AI response) to chat history

**Request Body**:

```json
{
  "chat_id": "chat_a1b2c3d4e5f6g7h8",
  "user_id": "user_550f35068db3c8f5d3d8e4a2",
  "user_text": "What are the tax implications of this clause?",
  "skip_ai_response": false
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| chat_id | string | No | Chat to save to (if null, creates new chat) |
| user_id | string | Yes | User making the request |
| user_text | string | Yes | Transcribed user speech |
| skip_ai_response | boolean | No | If true, save user text only (user interrupted) |

**Response** (200 OK):

```json
{
---

## Sharing & Collaboration

### Generate Share Token

**Endpoint**: `POST /chats/{chat_id}/share`

**Description**: Create a shareable link for a chat

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Request Body** (optional):

```json
{
  "expiration_hours": 24
}
```

**Response** (200 OK):

```json
{
  "shareToken": "share_abc123xyz789",
  "chatId": "chat_a1b2c3d4e5f6g7h8",
  "shareUrl": "http://127.0.0.1:8000/share/share_abc123xyz789",
  "expiresAt": "2026-05-21T10:00:00Z"
}
```

**Possible Errors**:

- 404 Not Found: Chat does not exist

---

### Access Shared Chat

**Endpoint**: `GET /share/{share_token}`

**Description**: Access a shared chat (read-only)

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| share_token | string | Unique share token |

**Response** (200 OK):

```json
{
  "chatId": "chat_a1b2c3d4e5f6g7h8",
  "title": "Contract Review - NDA",
  "sharedBy": "user_550f35068db3c8f5d3d8e4a2",
  "messages": [
    {
      "messageId": "msg_001",
      "role": "user",
      "content": "Please review this clause",
      "createdAt": "2026-05-20T10:00:00Z"
    }
  ]
}
```

**Possible Errors**:

- 404 Not Found: Share token does not exist
- 410 Gone: Share token expired

---

## Error Handling

### Error Response Format

All errors follow this structure:

```json
{
  "detail": "Error description",
  "status_code": 400,
  "timestamp": "2026-05-20T10:00:00Z"
}
```

### HTTP Status Codes

| Code | Meaning              | Example                            |
| ---- | -------------------- | ---------------------------------- |
| 200  | OK                   | Successful GET/PATCH               |
| 201  | Created              | Successful POST (resource created) |
| 204  | No Content           | Successful DELETE                  |
| 400  | Bad Request          | Invalid input parameters           |
| 401  | Unauthorized         | Missing authentication             |
| 404  | Not Found            | Resource doesn't exist             |
| 409  | Conflict             | Duplicate email/username           |
| 413  | Payload Too Large    | File exceeds limit                 |
| 422  | Unprocessable Entity | Validation error                   |
| 500  | Server Error         | Unexpected server error            |

### Common Error Messages

```json
{
  "detail": "Invalid email format",
  "status_code": 400
}
```

```json
{
  "detail": "Email already registered",
  "status_code": 409
}
```

```json
{
  "detail": "Chat not found",
  "status_code": 404
}
```

---

## Request/Response Examples

### Example 1: Complete Chat Flow

**1. Register User**

```bash
curl -X POST http://127.0.0.1:8000/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "lawyer@example.com",
    "username": "john_doe",
    "password": "SecurePass123!",
    "context": "Corporate attorney"
  }'
```

**2. Create Chat**

```bash
curl -X POST http://127.0.0.1:8000/users/user_123/chats \
  -H "Content-Type: application/json" \
  -d '{"title": "Contract Review"}'
```

**3. Send Message**

```bash
curl -X POST http://127.0.0.1:8000/chats/chat_123/messages \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_123",
    "sender": "user",
    "content": "Please review this contract"
  }'
```

**4. List Chats**

```bash
curl http://127.0.0.1:8000/users/user_123/chats
```

---

## Rate Limiting (Future)

**Planned Implementation**:

- 100 requests per minute per user
- 10 file uploads per hour per user
- 50 summarizations per day per user

---

## API Versioning

**Current Version**: 1.0

**Future Versions**:

- v2: Enhanced authentication, webhooks
- v3: GraphQL support, advanced filtering

---

## Support & Issues

For API issues or questions:

1. Check this documentation
2. Review error messages carefully
3. Check MongoDB connection
4. Verify API keys in `.env`
5. Check backend logs
