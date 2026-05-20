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

**Current Implementation**: User ID-based tracking

All requests should include `user_id` in the request body or URL parameter.

**Future**: Implement JWT token-based authentication:

```
Authorization: Bearer <jwt_token>
```

**Password Security**:

- Passwords hashed with bcrypt (cost factor: 12)
- Never store plaintext passwords
- Client-side validation recommended

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

**Description**: Simple connectivity test (logged separately, not in general logs)

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

**Endpoint**: `POST /users`

**Description**: Register a new user account

**Request Body**:

```json
{
  "email": "user@example.com",
  "username": "john_doe",
  "password": "SecurePassword123!",
  "context": "I am a corporate attorney specializing in M&A"
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | Valid email address (must be unique) |
| username | string | Yes | Unique username (3-50 characters) |
| password | string | Yes | Password (min 8 characters, recommend strong) |
| context | string | No | User's professional context for AI personalization |

**Response** (201 Created):

```json
{
  "userId": "user_550f35068db3c8f5d3d8e4a2",
  "email": "user@example.com",
  "username": "john_doe",
  "context": "I am a corporate attorney specializing in M&A",
  "createdAt": "2026-05-20T10:00:00Z"
}
```

**Possible Errors**:

- 400 Bad Request: Invalid email format or duplicate email/username
- 409 Conflict: Email or username already exists
- 422 Unprocessable Entity: Validation error on input

---

### Get User Profile

**Endpoint**: `GET /users/{user_id}`

**Description**: Retrieve user account information

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Response** (200 OK):

```json
{
  "userId": "user_550f35068db3c8f5d3d8e4a2",
  "email": "user@example.com",
  "username": "john_doe",
  "context": "I am a corporate attorney specializing in M&A",
  "createdAt": "2026-05-20T10:00:00Z",
  "updatedAt": "2026-05-20T10:00:00Z"
}
```

**Possible Errors**:

- 404 Not Found: User does not exist

---

### Update User Profile

**Endpoint**: `PATCH /users/{user_id}`

**Description**: Update user information

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| user_id | string | Unique user identifier |

**Request Body** (all fields optional):

```json
{
  "username": "john_doe_updated",
  "context": "Updated professional context",
  "password": "NewSecurePassword123!"
}
```

**Response** (200 OK):

```json
{
  "userId": "user_550f35068db3c8f5d3d8e4a2",
  "email": "user@example.com",
  "username": "john_doe_updated",
  "context": "Updated professional context",
  "updatedAt": "2026-05-20T10:15:00Z"
}
```

**Possible Errors**:

- 400 Bad Request: Invalid input
- 404 Not Found: User does not exist
- 409 Conflict: Username already taken

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

## Message Endpoints

### Add Message to Chat

**Endpoint**: `POST /chats/{chat_id}/messages`

**Description**: Send a message and receive AI response

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Request Body**:

```json
{
  "user_id": "user_550f35068db3c8f5d3d8e4a2",
  "sender": "user",
  "content": "What are the key differences between an LLC and an S-Corp?",
  "attachments": []
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | string | Yes | ID of the user sending the message |
| sender | string | Yes | Either "user" or "ai" |
| content | string | Yes | Message content (min 1 character) |
| attachments | array | No | Array of file references |

**Response** (200 OK):

```json
{
  "messages": [
    {
      "messageId": "msg_001",
      "userId": "user_550f35068db3c8f5d3d8e4a2",
      "role": "user",
      "content": "What are the key differences between an LLC and an S-Corp?",
      "createdAt": "2026-05-20T10:10:00Z"
    },
    {
      "messageId": "msg_002",
      "userId": null,
      "role": "assistant",
      "content": "Great question! Here are the key differences:\n\n**LLC (Limited Liability Company)**\n- Pass-through taxation by default\n- Flexible management structure\n- Greater liability protection\n- Less complex formation\n\n**S-Corp (S Corporation)**\n- Must have 1-100 shareholders\n- More complex tax implications\n- Stricter operational requirements\n- Potential for greater tax savings\n\n**Key Differences**\n1. Taxation: LLCs offer flexibility, S-Corps have specific rules\n2. Ownership: S-Corps limited to 100 shareholders\n3. Compliance: S-Corps require more formal documentation",
      "createdAt": "2026-05-20T10:10:30Z"
    }
  ],
  "updatedAt": "2026-05-20T10:10:30Z"
}
```

**Possible Errors**:

- 400 Bad Request: Invalid sender or empty content
- 404 Not Found: Chat does not exist
- 500 Internal Server Error: AI API failure (returns demo response)

---

### Edit Message

**Endpoint**: `PATCH /chats/{chat_id}/messages/{message_id}`

**Description**: Edit existing message content

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
  "messageId": "msg_001",
  "content": "Updated message content",
  "updatedAt": "2026-05-20T10:30:00Z"
}
```

**Possible Errors**:

- 404 Not Found: Chat or message does not exist

---

### Delete Message

**Endpoint**: `DELETE /chats/{chat_id}/messages/{message_id}`

**Description**: Delete a message from chat

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |
| message_id | string | Unique message identifier |

**Response** (204 No Content): No response body

**Possible Errors**:

- 404 Not Found: Chat or message does not exist

---

## File Endpoints

### Upload File

**Endpoint**: `POST /files/upload`

**Description**: Upload a legal document

**Request Headers**:

```
Content-Type: multipart/form-data
```

**Request Body** (multipart):
| Field | Type | Description |
|-------|------|-------------|
| file | file | Document file (PDF, DOCX, TXT, PNG, JPG) |
| user_id | string | User uploading the file |

**Supported File Types**:

- PDF (`.pdf`) - Portable Document Format
- DOCX (`.docx`) - Microsoft Word
- TXT (`.txt`) - Plain text
- PNG (`.png`) - Image
- JPG (`.jpg`, `.jpeg`) - Image

**Response** (200 OK):

```json
{
  "fileId": "file_abc123xyz789",
  "filename": "contract.pdf",
  "mimeType": "application/pdf",
  "size": 256000,
  "uploadedAt": "2026-05-20T10:00:00Z"
}
```

**File Storage**:

- Location: `C:\legalEaseDB\{user_id}\{filename}`
- Size limits: 50MB per file (configurable)
- Retention: Until manually deleted

**Possible Errors**:

- 400 Bad Request: Invalid file type or missing fields
- 413 Payload Too Large: File exceeds size limit
- 500 Internal Server Error: Storage issue

---

### Get File Metadata

**Endpoint**: `GET /files/{file_id}`

**Description**: Retrieve file metadata

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| file_id | string | Unique file identifier |

**Response** (200 OK):

```json
{
  "fileId": "file_abc123xyz789",
  "userId": "user_550f35068db3c8f5d3d8e4a2",
  "filename": "contract.pdf",
  "filepath": "C:\\legalEaseDB\\user_550f35068db3c8f5d3d8e4a2\\contract.pdf",
  "mimeType": "application/pdf",
  "size": 256000,
  "uploadedAt": "2026-05-20T10:00:00Z"
}
```

**Possible Errors**:

- 404 Not Found: File does not exist

---

### Delete File

**Endpoint**: `DELETE /files/{file_id}`

**Description**: Delete a file

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| file_id | string | Unique file identifier |

**Response** (204 No Content): File deleted

**Possible Errors**:

- 404 Not Found: File does not exist

---

## AI Features

### Summarize Text

**Endpoint**: `POST /summarize`

**Description**: Generate a concise summary of legal text

**Request Body**:

```json
{
  "text": "Lengthy legal document text here...",
  "user_id": "user_550f35068db3c8f5d3d8e4a2"
}
```

**Request Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Text to summarize (min 100 characters) |
| user_id | string | Yes | User making the request |
| length | string | No | "short" (50-100 words) / "medium" (100-200) / "long" (200+) |

**Response** (200 OK):

```json
{
  "summary": "This contract outlines the terms of service between Party A and Party B. Key obligations include...",
  "original_length": 5000,
  "summary_length": 150,
  "timestamp": "2026-05-20T10:00:00Z"
}
```

**Possible Errors**:

- 400 Bad Request: Text too short or invalid input
- 500 Internal Server Error: AI API failure

---

### Real-time Chat (WebSocket)

**Endpoint**: `WS /ws/{chat_id}`

**Description**: Establish WebSocket connection for real-time messaging

**URL Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| chat_id | string | Unique chat identifier |

**Connection Flow**:

1. **Establish Connection**:

```
GET /ws/chat_a1b2c3d4e5f6g7h8
Upgrade: websocket
```

2. **Send Message** (JSON):

```json
{
  "user_id": "user_550f35068db3c8f5d3d8e4a2",
  "content": "Real-time message"
}
```

3. **Receive Message** (JSON):

```json
{
  "messageId": "msg_001",
  "role": "user",
  "content": "Real-time message",
  "timestamp": "2026-05-20T10:00:00Z"
}
```

**Connection Codes**:

- 1000: Normal closure
- 1006: Abnormal closure
- 1011: Server error

---

## Live Call Endpoints

### Transcribe Raw Audio

**Endpoint**: `POST /api/transcribe_raw`

**Description**: Convert raw audio data to text using speech-to-text

**Request Body**: Binary audio data (raw PCM or WAV format)

**Request Headers**:

```
Content-Type: application/octet-stream
```

**Response** (200 OK):

```json
{
  "text": "What are the tax implications of this clause?",
  "confidence": 0.98,
  "language": "en",
  "duration": 3.5,
  "timestamp": "2026-05-20T10:15:30Z"
}
```

**Response Parameters**:
| Field | Type | Description |
|-------|------|-------------|
| text | string | Transcribed text from audio |
| confidence | float | Confidence level (0.0 - 1.0) |
| language | string | Detected language code (e.g., "en") |
| duration | float | Audio duration in seconds |
| timestamp | string | ISO 8601 timestamp |

**Possible Errors**:

- 400 Bad Request: Invalid audio format
- 413 Payload Too Large: Audio file exceeds size limit
- 422 Unprocessable Entity: Audio too short or no speech detected
- 500 Internal Server Error: Transcription service unavailable

**Notes**:

- Supports concurrent recording and playback for user interruption
- Optimized for natural speech patterns
- Automatic silence detection

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
  "interaction_id": "interaction_x1y2z3a4b5c6",
  "chat_id": "chat_a1b2c3d4e5f6g7h8",
  "user_message": {
    "messageId": "msg_001",
    "role": "user",
    "content": "What are the tax implications of this clause?",
    "timestamp": "2026-05-20T10:15:32Z"
  },
  "ai_response": {
    "messageId": "msg_002",
    "role": "assistant",
    "content": "The tax implications include...",
    "audio_url": "/api/files/audio_a1b2c3d4.mp3",
    "timestamp": "2026-05-20T10:15:35Z"
  },
  "interrupted": false
}
```

**Response Parameters**:
| Field | Type | Description |
|-------|------|-------------|
| interaction_id | string | Unique interaction identifier |
| chat_id | string | Associated chat ID |
| user_message | object | User's message object with metadata |
| ai_response | object | AI's response (null if skipped due to interruption) |
| interrupted | boolean | Whether user interrupted the interaction |

**Possible Errors**:

- 400 Bad Request: Missing required fields or invalid chat_id
- 404 Not Found: Chat does not exist
- 422 Unprocessable Entity: User text empty or too short
- 500 Internal Server Error: AI processing failed

**Notes**:

- Saves both user text and AI response atomically
- If `skip_ai_response=true`, only saves user message
- AI response includes both text and audio URL
- Interaction tracked for user interruption scenarios
- Fully integrated with chat history

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
