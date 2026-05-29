# LegalEase System Architecture

**Document Version**: 1.0 
**Last Updated**: May 20, 2026 
**Status**: Production-Ready

---

## 1. System Overview

LegalEase is a comprehensive AI-powered legal assistance platform designed to democratize legal access. The system comprises four interconnected components:

- **Mobile App** (Flutter): Native Android application with offline support
- **Web Interface** (Vanilla JS): Responsive web client for desktop and mobile browsers
- **Backend API** (FastAPI): RESTful API with AI and voice processing pipelines
- **Database** (MongoDB): NoSQL document store for users, chats, and file metadata

### System Architecture Diagram

```
+─────────────────────────────────────────────────────────────────+
|                        USER LAYER                               |
|--─────────────────────+──────────────────────────────────────────+
|   Mobile App         |         Web Browser                      |
|   (Flutter/Android)  |   (HTML/CSS/JavaScript)                |
+--─────────────+───────+──────────────────+───────────────────────+
               |                          |
               |         HTTP REST API    |
               |--─────────────────────────+
               v v
+─────────────────────────────────────────────────────────────────+
|              BACKEND API LAYER (FastAPI)                        |
|--────────────────────────────────────────────────────────────────+
|  • User Authentication & Authorization                          |
|  • Chat Management (CRUD Operations)                            |
|  • Live Call Voice Processing (Transcription, TTS)              |
|  • Message Processing & AI Integration                          |
|  • File Upload & Management                                     |
|  • CORS Middleware for Client Communication                     |
+--─────────────+──────────────────────────────────────────────────+
               |
               | MongoDB Driver (Motor)
               v
+─────────────────────────────────────────────────────────────────+
|              DATA PERSISTENCE LAYER (MongoDB)                   |
|--────────────────────────────────────────────────────────────────+
|  Collections:                                                   |
|  • users       - User accounts & authentication data            |
|  • chats       - Conversation metadata & embedded messages      |
|  • files       - File metadata & storage references             |
+--────────────────────────────────────────────────────────────────+
               |
               | File System
               v
+─────────────────────────────────────────────────────────────────+
|         LOCAL FILE STORAGE (C:\legalEaseDB)                     |
|  Document uploads organized by user directories                 |
+--────────────────────────────────────────────────────────────────+
```

---

## 2. Component Details

### 2.1 Mobile Application (Flutter)

**Purpose**: Native Android client providing full LegalEase functionality with offline support.

**Key Features**:

- User authentication (login/signup)
- Real-time chat interface
- Document upload and analysis
- Chat history management
- Settings and user preferences
- Live call capabilities
- Connectivity awareness

**Technology Stack**:

- Framework: Flutter (stable channel)
- Language: Dart
- State Management: Provider
- Local Storage: SharedPreferences & local file system
- Networking: HTTP client with Dio/http package

**Project Structure**:

```
app/
|--─ lib/
|   |--─ main.dart                 # Application entry point
|   |--─ models/                   # Data models (User, Chat, Message)
|   |--─ screens/
|   |   |--─ chat_screen.dart      # Main chat interface
|   |   |--─ login_screen.dart     # User authentication
|   |   |--─ signup_screen.dart    # User registration
|   |   |--─ settings_screen.dart  # User settings
|   |   +--─ live_call_screen.dart # Live call functionality
|   |--─ services/
|   |   +--─ chat_service.dart     # API communication & business logic
|   |--─ theme/
|   |   +--─ app_theme.dart        # Dark theme configuration
|   +--─ widgets/
|       |--─ chat_drawer.dart      # Chat history sidebar
|       |--─ message_bubble.dart   # Message UI component
|       |--─ thinking_indicator.dart # AI thinking animation
|       +--─ connectivity_banner.dart # Network status indicator
|--─ assets/
|   +--─ models/
|       +--─ silero_vad_legacy.onnx # Voice activity detection model
|--─ android/                      # Android native code
|--─ test/                         # Unit & integration tests
+--─ pubspec.yaml # Dependencies configuration
```

**Design System**:

- **Primary Color**: #131313 (Deep Black)
- **Accent Color**: #FCE566 (Golden Yellow)
- **Typography**: Consistent system fonts
- **Responsive**: Adapts to all device sizes

**API Integration**:

- Base URL: Configurable via Dart define
- Default: `http://127.0.0.1:8000`
- Android Emulator: `http://10.0.2.2:8000`
- Physical Device: Machine's LAN IP (e.g., `192.168.x.x:8000`)

---

### 2.2 Web Application (Vanilla JavaScript & Vite)

**Purpose**: Cross-platform web client providing full feature parity with the mobile app, optimized for touch-friendliness and high-performance rendering.

**Key Features**:
- Fully responsive design isolated within a mobile media query (`<1023px` for mobile/tablet, `>1024px` for persistent sidebar)
- Dark mode theme matching Flutter app colors (`#131313` background, `#FCE566` accents)
- Auto-scroll engine with requestAnimationFrame and delayed fallback offsets to support keyboard overlays
- Touch-friendly controls: `52px` card-style hamburger menu, `60px` action buttons, and `18px` bubble scales
- Pinned bottom-input layouts on empty chats and selective back-glow activations
- Interactive sidebar context menus mapped to mobile long-press behaviors

**Technology Stack**:
- Frontend: HTML5, CSS3 (Vanilla), Vanilla ES6 Modules
- Build Tool: Vite 5+ (for asset bundling, environment management, and hot module replacement)
- Deployment: Containerized or static hosting (npm script-driven)

**Project Structure**:

```
web/
|--─ index.html            # Main HTML document template
|--─ package.json          # Node dependency configuration & Vite scripts
|--─ vite.config.js        # Vite compiler and development configuration
|--─ run.bat               # Interactive dependency installer and launcher script
+--─ src/
    |--─ main.js           # Main application entry point & Event listeners
    |--─ app.js            # Core orchestration and application state managers
    |--─ styles.css        # Premium style declarations and media queries
    +--─ js/
        |--─ api.js        # HTTP client wrapper & request handler
        |--─ auth.js       # JWT login/signup controller
        |--─ chat.js       # Message mutation and active thread hooks
        |--─ config.js     # Default settings and global state objects
        |--─ ui.js         # Dynamic DOM renderer, scroll handlers, & context actions
        +--─ utils.js # Text formatting, escaping, and validation functions
```

**UI Components**:
- Glassmorphic card-style header menu button for mobile
- Slide-out responsive sidebar drawer for conversation navigation
- Contextual chat lists with pin/rename/delete long-press support
- Chat container with progressive-rendering bubbles and thinking dots
- Bottom message compose panel with file attachment pills and quick triggers

**Configuration**:
- Base API URL: Configured in `src/js/config.js` (`API_BASE_URL`) or overridden at runtime
- Runtime override: Query parameters (`?api_base_url=http://127.0.0.1:8000`)
- Authorization: Implicitly attached to `Authorization: Bearer <token>` requests via central `apiCall` wrapper

---

### 2.3 Backend API (FastAPI)

**Purpose**: Core server handling all business logic, user management, and AI integration.

**Key Features**:
- JWT Authentication & Session tokens
- Background User-Context Extractor (Gemini-driven fact extractor executed as an asynchronous background task on message turns)
- Gemini API generation `/api/generate_ai` with rotating keys and context injection
- Live Call conversational voice optimizations (`/api/generate_live`)
- Local Whisper-based Speech-To-Text GPU pipeline (`/api/transcribe_raw`)
- Local Kokoro-82M-based Text-To-Speech stream pipeline (`/api/tts`)
- Auto-indexes creator for unique lookups on MongoDB collections startup

**Technology Stack**:
- Framework: FastAPI (Python 3.11+)
- Database Driver: Motor (async MongoDB)
- AI SDKs: Google Generative AI SDK (Gemini Flash)
- Speech-to-Text: `faster-whisper` (CTranslate2 CUDA-accelerated, `int8` quantized)
- Text-to-Speech: `kokoro` (Kokoro-82M ONNX model)
- Quantization/GPU Support: NVIDIA CUDA dll linking on Windows host startup
- Async: asyncio and FastAPI BackgroundTasks

**Project Structure**:

```
api/
|--─ main.py             # FastAPI entrypoint, router, and AI Pipelines loaders
|--─ requirements.txt    # Python module dependencies
|--─ api_keys.csv        # Gemini API keys list (for automatic rate-limit rotation)
|--─ .env                # Port, URL, and system prompt configurations
|--─ uploads/            # Temporary attachment files storage
+--─ run.py # Uvicorn startup utility script
```

**API Endpoints**:

#### Health & Status
- `GET /health` - API server diagnostic check
- `GET /api/ping` - Silent diagnostic connectivity check

#### Authentication & Profiles
- `POST /auth/register` - Create user profile and store optional context
- `POST /auth/login` - Authenticate credentials and return signed JWT token
- `GET /users/{user_id}` - Retrieve username, email, and running personal context
- `PATCH /users/{user_id}/context` - Override/update personal context
- `DELETE /users/{user_id}` - Purge user profile, files, and chats permanently
- `DELETE /users/{user_id}/chats` - Clear user chat history only

#### Chat & AI Generation
- `GET /users/{user_id}/chats` - List user chats
- `POST /users/{user_id}/chats` - Create new empty chat
- `GET /chats/{chat_id}` - Retrieve chat details and message list
- `PATCH /chats/{chat_id}` - Rename or pin/unpin chat
- `DELETE /chats/{chat_id}` - Delete chat and remove physical files
- `POST /api/generate_ai` - Generate Gemini reply with context auto-updates

#### Messages & File Management
- `POST /chats/{chat_id}/messages` - Save message text to chat history
- `POST /chats/{chat_id}/messages_with_file` - Multipart upload file + save message
- `PATCH /chats/{chat_id}/messages/{message_id}` - Edit message content
- `DELETE /chats/{chat_id}/messages/{message_id}` - Delete message (trims future messages)
- `GET /api/files/{file_id}` - Stream download physical attachment file

#### Voice Call & Live Pipelines
- `POST /api/generate_live` - Specialized brief voice-optimized conversational reply
- `POST /api/transcribe_raw` - Transcribe PCM audio bytes to text (Whisper GPU)
- `POST /api/tts` - Stream human-like speech from text (Kokoro WAV stream)
- `POST /api/summarize` - Generate concise chat titles (from user query)

**CORS Configuration**:
- Allow origins: All (`*`)
- Allow methods: All
- Allow headers: All
- Allow credentials: Enabled

---

### 2.4 Database (MongoDB)

**Purpose**: Central data store with document-based schema for flexibility and scalability.

**Collections**:

#### Users Collection

```json
{
  "_id": ObjectId("..."),
  "userId": "user_123",
  "email": "user@example.com",
  "username": "john_doe",
  "passwordHash": "bcrypt_hash_...",
  "context": "I am a corporate attorney...",
  "createdAt": ISODate("2026-05-20T10:00:00Z"),
  "updatedAt": ISODate("2026-05-20T10:00:00Z")
}
```

**Indexes**:

- `{ userId: 1 }` - Unique, for fast user lookup
- `{ email: 1 }` - Unique, for authentication
- `{ createdAt: -1 }` - For user activity tracking

#### Chats Collection

```json
{
  "_id": ObjectId("..."),
  "chatId": "chat_abc123",
  "ownerId": "user_123",
  "title": "Contract Review - NDA",
  "isPinned": false,
  "isArchived": false,
  "messages": [
    {
      "messageId": "msg_001",
      "userId": "user_123",
      "role": "user",
      "content": "Review this NDA clause",
      "attachments": [
        {
          "fileId": "file_xyz",
          "filename": "contract.pdf"
        }
      ],
      "createdAt": ISODate("2026-05-20T10:05:00Z")
    },
    {
      "messageId": "msg_002",
      "userId": null,
      "role": "assistant",
      "content": "Analysis: The clause appears standard...",
      "createdAt": ISODate("2026-05-20T10:06:00Z")
    }
  ],
  "createdAt": ISODate("2026-05-20T10:00:00Z"),
  "updatedAt": ISODate("2026-05-20T10:06:00Z")
}
```

**Indexes**:

- `{ chatId: 1 }` - Unique, for chat lookup
- `{ ownerId: 1, createdAt: -1 }` - For user's chat history
- `{ isPinned: 1 }` - For pinned chat filtering

#### Files Collection

```json
{
  "_id": ObjectId("..."),
  "fileId": "file_xyz",
  "userId": "user_123",
  "filename": "contract.pdf",
  "filepath": "C:\\legalEaseDB\\user_123\\contract.pdf",
  "mimeType": "application/pdf",
  "size": 256000,
  "uploadedAt": ISODate("2026-05-20T10:00:00Z")
}
```

**Indexes**:

- `{ fileId: 1 }` - Unique, for file lookup
- `{ userId: 1, uploadedAt: -1 }` - For user's file history

**Data Relationships**:

```
users (1) ────────> (many) chats
  +-- userId +-- ownerId

chats (1) ────────> (many) messages
  +-- chatId +-- embedded in messages array

chats (1) ────────> (many) files
  +-- fileId +-- referenced in message attachments

files (1) ────────> (1) user
  +-- userId
```

**Storage**:

- MongoDB Database: `legalease`
- Local File Storage: `C:\legalEaseDB\{userId}\{filename}`
- Backup Strategy: Regular snapshots recommended

---

## 3. Communication Flows

### 3.1 User Registration Flow

```
Mobile/Web Client
    |
    +-> POST /users
    |   {email, username, password, context}
    |
    v
FastAPI Backend
    |
    +-> Validate input (email format, password strength)
    +-> Hash password with bcrypt
    +-> Generate unique userId
    |
    v
MongoDB
    |
    +-> Insert user document
    +-> Create indexes
    |
    v
FastAPI Backend (Response)
    |
    +-> 201 Created
        {userId, email, username, context}
```

### 3.2 Chat Message Flow

```
Mobile/Web Client
    |
    +-> POST /chats/{chat_id}/messages
    |   {user_id, sender: "user", content, attachments}
    |
    v
FastAPI Backend
    |
    +-> Generate message ID
    +-> Timestamp (UTC ISO)
    +-> Validate attachments (file existence)
    |
    +-> Append to chat.messages array
    +-> Call Google Gemini API (async)
    |   +-> Get AI response
    +-> Append assistant message to chat
    |
    v
MongoDB
    |
    +-> Update chats collection
    |   +-> Add user message + AI response
    |
    v
FastAPI Backend (Response)
    |
    +-> 200 OK
        {messages: [...], updatedAt}
```

### 3.3 File Upload Flow

```
Mobile/Web Client
    |
    +-> POST /files/upload
    |   multipart/form-data: {file, user_id}
    |
    v
FastAPI Backend
    |
    +-> Validate file type (PDF, DOCX, TXT, IMG)
    +-> Generate unique fileId
    +-> Save to C:\legalEaseDB\{userId}\{filename}
    |
    v
MongoDB
    |
    +-> Insert files collection document
    |   {fileId, userId, filepath, mimeType, size}
    |
    v
FastAPI Backend (Response)
    |
    +-> 200 OK
        {fileId, filename, size, uploadedAt}
```

### 3.4 Live Voice Call Audio Pipeline Flow

The Live Call feature processes voice streams with low latency using a decoupled background queue model for Text-to-Speech (TTS) alongside Voice Activity Detection (VAD) user interruption handling:

```
User Voice Input FastAPI Backend Pipeline Audio Output / UI
      |                                     |                                     |
      +-> PCM 16kHz audio stream | |
      +-> VAD registers speech end | |
      +-> POST /api/transcribe_raw ───────->| (GPU Whisper Speech-to-Text) |
      |                                     +-> Transcribed Text                  |
      |                                     +-> POST /api/generate_live           |
      |                                     |   (Gemini brief 1-3 sentences)      |
      |                                     v                                     |
      |                             AI Response Text                              |
      |                                     |                                     |
      |                                     +-> Split response into sentences     |
      |                                     +-> Fetch TTS waves concurrently      |
      |                                     |   via POST /api/tts (Kokoro ONNX)   |
      |                                     v                                     |
      |                                                                           +-> Play waves sequentially
      |                                                                           +-> Wave breathes on UI
      |                                                                               (Sinusoidal thinking aura)
      |                                                                           
  [USER INTERRUPTS (VAD)] 
      |                                                                           
      +-> VAD detects user speaking ──────────────────────────────────────────────+-> Stop active playback
      +-> Increment interaction ID ───────────────────────────────────────────────+-> Clear TTS download queue
      +-> Invalidate pending chunks ──────────────────────────────────────────────+-> Clear audio playback chunks
```

---

## 4. Data Flow Architecture

### 4.1 Request-Response Cycle

```
+────────────────────────────────────────────────────────────────+
|                     CLIENT (App/Web)                           |
|--───────────────────────────────────────────────────────────────+
|  • User interacts with UI                                       |
|  • Event triggers API call                                      |
|  • Local validation (if applicable)                             |
+--───────────+──────────────────────────────────────────────────+
             |
             | HTTP REST API
             v
+────────────────────────────────────────────────────────────────+
|                  FASTAPI BACKEND                               |
|--───────────────────────────────────────────────────────────────+
|  1. Route Handler receives request                              |
|  2. CORS Middleware validates origin                            |
|  3. Request validation (Pydantic models)                        |
|  4. Authentication check (if required)                          |
|  5. Business logic execution                                    |
|  6. Database operations (via Motor)                             |
|  7. AI API calls (if applicable)                                |
|  8. Response serialization                                      |
+--───────────+──────────────────────────────────────────────────+
             |
             | MongoDB Driver
             v
+────────────────────────────────────────────────────────────────+
|                      MONGODB                                   |
|--───────────────────────────────────────────────────────────────+
|  1. Document validation against schema                          |
|  2. CRUD operation execution                                    |
|  3. Index usage for optimization                                |
|  4. Transaction (if multi-document)                             |
|  5. Return results                                              |
+--───────────+──────────────────────────────────────────────────+
             |
             | Response
             v
+────────────────────────────────────────────────────────────────+
|                  FASTAPI BACKEND                               |
|--───────────────────────────────────────────────────────────────+
|  • Serialize response data                                      |
|  • Add headers (content-type, etc.)                             |
|  • Set status code                                              |
+--───────────+──────────────────────────────────────────────────+
             |
             | HTTP Response
             v
+────────────────────────────────────────────────────────────────+
|                  CLIENT (App/Web)                              |
|--───────────────────────────────────────────────────────────────+
|  • Receive response                                             |
|  • Parse JSON                                                   |
|  • Update local state                                           |
|  • Render UI                                                    |
|  • Show user feedback                                           |
+--───────────────────────────────────────────────────────────────+
```

---

## 5. Security Architecture

### 5.1 Authentication & Authorization

- **User Identification**: User ID tracked per request
- **Password Security**: Bcrypt hashing (recommended for implementation)
- **Session Management**: Ready for JWT token implementation
- **CORS**: Configured to allow all origins (review for production)

### 5.2 Data Protection

- **In Transit**: HTTPS recommended for production
- **At Rest**: MongoDB permissions and file system ACLs
- **API Keys**: Stored in `.env` and `.csv` files (not in version control)
- **File Access**: User-scoped file directory structure

### 5.3 API Security

- **Rate Limiting**: Not yet implemented (recommended)
- **Input Validation**: Pydantic models enforce types and constraints
- **SQL Injection**: N/A (MongoDB, no SQL)
- **CSRF**: Not applicable (stateless API)

---

## 6. Performance Architecture

### 6.1 Scalability Considerations

**Horizontal Scaling**:

- Stateless API design enables multiple backend instances
- Load balancer distributes requests
- MongoDB replication for data redundancy

**Vertical Scaling**:

- Async operations (Motor driver) handle high concurrency
- Message batching for bulk operations
- Index optimization for query performance

### 6.2 Caching Strategy

- **Future**: Redis for session and chat history caching
- **Local**: Browser local storage for UI state
- **API Response**: No caching configured (requests always fresh)

### 6.3 Database Optimization

- **Indexes**: Created on frequently queried fields
- **Aggregation Pipeline**: For complex queries
- **Sharding**: Ready for implementation at scale

---

## 7. Deployment Architecture

### 7.1 Development Environment

```
Local Machine
|--─ API Server (FastAPI + Uvicorn)
|   +--─ Port 8000
|--─ MongoDB Server
|   +--─ Port 27017
|--─ Web Server (Vite Development Server)
|   +--─ Port 8080
+--─ Mobile Emulator or Device
    +--─ Connects to API
```

### 7.2 Production Deployment (Recommended)

```
Cloud Infrastructure (e.g., AWS, Google Cloud, Azure)
|--─ API Tier
|   |--─ FastAPI containerized (Docker)
|   |--─ Multiple replicas behind load balancer
|   +--─ Auto-scaling based on CPU/Memory
|--─ Data Tier
|   |--─ MongoDB Atlas or self-managed cluster
|   |--─ Replication for HA
|   +--─ Automated backups
|--─ Storage Tier
|   |--─ Cloud Storage (S3, GCS, Azure Blob)
|   +--─ CDN for static files
+--─ Frontend Tier
    |--─ Static hosting (Vercel, Netlify)
    |--─ CDN distribution
    +--─ Mobile app distribution (Play Store, App Store)
```

---

## 8. Monitoring & Observability

### 8.1 Logging

- **API Logs**: Request/response logging (excluding `/api/ping`)
- **Error Tracking**: Exception logging to stdout
- **Database Logs**: MongoDB operation logs

### 8.2 Metrics

- **API Metrics**: Response time, request count, error rate
- **Database Metrics**: Query performance, index usage, storage size
- **Application Metrics**: Active users, chat count, message volume

### 8.3 Health Checks

- `/health` endpoint for API availability
- `/api/ping` endpoint for connectivity tests
- Database connection validation on startup

---

## 9. Technology Choices & Rationale

| Component      | Technology    | Rationale                                                    |
| -------------- | ------------- | ------------------------------------------------------------ |
| Mobile         | Flutter       | Cross-platform, fast development, strong ecosystem           |
| Web            | Vanilla JS + Vite | Modular ES6 modules, hot reloading, lightweight bundling     |
| Backend        | FastAPI       | Python async, automatic API docs, fast performance           |
| Database       | MongoDB       | Flexible schema, document storage, scalable                  |
| AI             | Google Gemini | Powerful LLM, affordable API, good for legal tasks           |
| Authentication | Bcrypt        | Industry standard, slow by design (resistant to brute force) |

---

## 10. Future Enhancements

### 10.1 Planned Features

- [ ] Advanced user authentication (OAuth2, SSO)
- [ ] End-to-end encryption for sensitive documents
- [ ] Advanced document OCR and extraction
- [ ] Template library for legal documents
- [ ] Advanced analytics dashboard
- [ ] Mobile app offline sync

### 10.2 Infrastructure Upgrades

- [ ] Redis caching layer
- [ ] Message queue (RabbitMQ, Kafka) for async tasks
- [ ] Elasticsearch for document search
- [ ] Vector database for semantic search
- [ ] CDN for static asset delivery
- [ ] Database sharding for horizontal scaling

### 10.3 Compliance & Security

- [ ] SOC2 compliance
- [ ] GDPR data handling
- [ ] Audit logging
- [ ] PII masking
- [ ] Rate limiting & DDoS protection

---

## 11. Troubleshooting Guide

### Common Issues

**API Connection Failure**

- Verify API server is running: `curl http://127.0.0.1:8000/health`
- Check firewall rules
- Verify correct API_BASE_URL for your environment

**Database Connection Error**

- Verify MongoDB is running: `mongosh`
- Check connection string in `.env`
- Verify database `legalease` exists

**File Upload Issues**

- Verify directory exists: `C:\legalEaseDB\`
- Check file permissions
- Verify file size within limits

**CORS Errors**

- Check API has CORS middleware configured
- Verify client origin is allowed
- Check browser console for detailed error

---

## 12. References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Google Generative AI Python SDK](https://ai.google.dev/tutorials/python_quickstart)
