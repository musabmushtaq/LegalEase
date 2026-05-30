# LegalEase API (FastAPI Backend)

**Status**: 🚀 Production Ready | Python FastAPI | Fully Featured

This folder contains the production-ready FastAPI server for LegalEase, providing REST endpoints for chat management, AI integration, and data persistence.

## Stack

- **Framework**: Python + FastAPI
- **Database**: MongoDB (NoSQL)
- **AI Integration**: Google Generative AI (Gemini)
- **Async**: asyncio + Motor (async MongoDB driver)
- **Validation**: Pydantic
- **API**: RESTful with WebSocket support

## Prerequisites

- **Python**: 3.11 or higher
  ```bash
  python --version
  ```
- **MongoDB**: Running on `mongodb://localhost:27017`
  ```bash
  mongosh  # Verify connection
  ```
- **Google Gemini API**: API keys for AI integration
- **pip**: Python package manager

## Setup

### 1. Initialize Database (If Not Done)

```bash
cd ../db
pip install -r requirements.txt
python init_db.py
```

See [db/README.md](../db/README.md) for detailed database setup.

### 2. Setup Python Virtual Environment

**Windows**:

```bash
cd api
python -m venv .venv
.venv\Scripts\activate
```

**macOS/Linux**:

```bash
cd api
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

**Key packages**:

- fastapi - Web framework
- uvicorn - ASGI server
- motor - Async MongoDB driver
- pydantic - Data validation
- google-generativeai - Gemini API
- python-multipart - File upload support

### 4. Configure Environment

```bash
copy .env.example .env
```

**Edit .env**:

```
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=legalease
API_BASE_URL=http://127.0.0.1:8000
DEFAULT_SYSTEM_PROMPT=You are LegalEase...
GOOGLE_GEMINI_API_KEY=your_key_here
```

### 5. Add API Keys

Create or edit `api_keys.csv`:

```csv
# Google Gemini API Keys (one per line)
AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

⚠️ **Never commit .env or api_keys.csv to version control**

## Run Server

### Development (with auto-reload)

```bash
.venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Output**:

```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Press CTRL+C to quit
```

### Production (no reload)

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Using run.py script

```bash
python run.py
# Automatically activates venv and starts server
```

### Using run.bat (Windows)

```bash
run.bat
```

## Health Check

Verify server is running:

```bash
# Simple status check
curl http://127.0.0.1:8000/health

# Expected response
{"status": "ok"}
```

## API Endpoints

### Core Endpoints

**Status**:

- `GET /health` - Health check
- `GET /api/ping` - Connectivity test

**Users**:

- `POST /users` - Create user account
- `GET /users/{user_id}` - Get user profile
- `PATCH /users/{user_id}` - Update user profile

**Chats**:

- `GET /users/{user_id}/chats` - List user chats
- `POST /users/{user_id}/chats` - Create new chat
- `GET /chats/{chat_id}` - Get chat details
- `PATCH /chats/{chat_id}` - Update chat
- `DELETE /chats/{chat_id}` - Delete chat

**Messages**:

- `POST /chats/{chat_id}/messages` - Add message
- `PATCH /chats/{chat_id}/messages/{message_id}` - Edit message
- `DELETE /chats/{chat_id}/messages/{message_id}` - Delete message

**Files**:

- `POST /files/upload` - Upload document
- `GET /files/{file_id}` - Get file metadata
- `DELETE /files/{file_id}` - Delete file

**Sharing**:

- `POST /chats/{chat_id}/share` - Generate share token
- `GET /share/{share_token}` - Access shared chat

**AI Features**:

- `POST /summarize` - Summarize text
- `WS /ws/{chat_id}` - WebSocket real-time chat

Full endpoint documentation: [API_DOCUMENTATION.md](../docs/API_DOCUMENTATION.md)

## Example Usage

### 1. Create User

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

**Response** (201 Created):

```json
{
  "userId": "user_abc123",
  "email": "lawyer@example.com",
  "username": "john_doe",
  "context": "Corporate attorney",
  "createdAt": "2026-05-20T10:00:00Z"
}
```

### 2. Create Chat

```bash
curl -X POST http://127.0.0.1:8000/users/user_abc123/chats \
  -H "Content-Type: application/json" \
  -d '{"title": "Contract Review"}'
```

### 3. Send Message (Get AI Response)

```bash
curl -X POST http://127.0.0.1:8000/chats/chat_xyz789/messages \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_abc123",
    "sender": "user",
    "content": "What is the difference between an LLC and an S-Corp?"
  }'
```

**Response**:

```json
{
  "messages": [
    {
      "messageId": "msg_001",
      "role": "user",
      "content": "What is the difference between an LLC and an S-Corp?",
      "createdAt": "2026-05-20T10:00:00Z"
    },
    {
      "messageId": "msg_002",
      "role": "assistant",
      "content": "LLC vs S-Corp: Here are the key differences...",
      "createdAt": "2026-05-20T10:00:05Z"
    }
  ]
}
```

### 4. List Chats

```bash
curl http://127.0.0.1:8000/users/user_abc123/chats
```

### 5. Upload File

```bash
curl -X POST http://127.0.0.1:8000/files/upload \
  -F "file=@contract.pdf" \
  -F "user_id=user_abc123"
```

## Project Structure

```
api/
├── main.py                  # FastAPI application & endpoints
├── requirements.txt         # Python dependencies
├── api_keys.csv            # Google Gemini API keys
├── .env.example            # Environment template
├── .env                    # Local environment config
├── run.py                  # Development runner script
├── run.bat                 # Windows batch script
├── uploads/                # Temporary file uploads
├── tests/                  # Test files (if present)
└── README.md               # This file
```

## Configuration

### Environment Variables

| Variable              | Description               | Default                   |
| --------------------- | ------------------------- | ------------------------- |
| MONGODB_URI           | MongoDB connection string | mongodb://localhost:27017 |
| MONGODB_DB            | Database name             | legalease                 |
| API_BASE_URL          | Public API URL            | http://127.0.0.1:8000     |
| DEFAULT_SYSTEM_PROMPT | AI system prompt          | "You are LegalEase..."    |

### CORS Configuration

Currently allows all origins (`*`). For production:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["*"],
)
```

### API Key Rotation

Edit `api_keys.csv` to add/remove keys:

```csv
# Primary key
AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Backup key
AIzaSyDyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
```

Server automatically rotates keys on failures.

## Features

### Core Features

- ✅ User authentication (expandable to JWT)
- ✅ Chat CRUD operations
- ✅ Message management with AI responses
- ✅ File upload and storage
- ✅ Google Gemini AI integration
- ✅ WebSocket real-time communication
- ✅ Chat sharing with tokens
- ✅ MongoDB integration

### Advanced Features

- ✅ Async operations (non-blocking)
- ✅ Error handling & validation
- ✅ CORS middleware
- ✅ Request logging
- ✅ Health monitoring
- 🚧 Rate limiting (planned)
- 🚧 API key management (planned)
- 🚧 Audit logging (planned)

## Database

**Collections**:

- `users` - User accounts
- `chats` - Conversations (with embedded messages)
- `files` - Document metadata

**Connection**: Motor (async MongoDB driver)

For schema details, see [DATABASE_DESIGN.md](../docs/DATABASE_DESIGN.md)

## Error Handling

**Standard error response**:

```json
{
  "detail": "Error description",
  "status_code": 400
}
```

**Common errors**:

- 400 Bad Request - Invalid input
- 404 Not Found - Resource doesn't exist
- 409 Conflict - Duplicate email/username
- 500 Internal Server Error - Unexpected error

## Testing

### Run Tests

```bash
pip install pytest pytest-asyncio
pytest tests/
```

### Test API Manually

Use included `test.py` in web folder:

```bash
cd web
python test.py
```

Or use Postman/Insomnia for interactive testing.

## Deployment

### Local Deployment

```bash
# Terminal setup
.venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY main.py .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]
```

**Build and run**:

```bash
docker build -t legalease-api .
docker run -p 8000:8000 legalease-api
```

### Cloud Deployment (AWS Example)

1. Deploy to EC2 or ECS
2. Use RDS or MongoDB Atlas for database
3. Configure security groups
4. Set up load balancer
5. Enable HTTPS/SSL

## Performance

### Optimization Tips

1. **Use indexes** on frequently queried fields

   ```javascript
   db.chats.createIndex({ ownerId: 1, createdAt: -1 });
   ```

2. **Limit query results** for large datasets

   ```python
   chats = await db.chats.find(query).limit(50).to_list(None)
   ```

3. **Cache responses** where appropriate

   ```python
   # Future: Implement Redis caching
   ```

4. **Monitor query performance**
   ```bash
   mongosh
   db.setProfilingLevel(1)
   ```

## Troubleshooting

### MongoDB Connection Failed

```
ConnectionFailure: cannot connect to server
```

**Solutions**:

1. Start MongoDB: `net start MongoDB` (Windows)
2. Verify connection string in .env
3. Check MongoDB is listening on port 27017

### API Key Errors

```
Could not authenticate with the Gemini API
```

**Solutions**:

1. Verify API keys in `api_keys.csv`
2. Check keys are not expired
3. Ensure internet connection
4. Check API quota limits

### CORS Errors

```
Access to XMLHttpRequest has been blocked by CORS policy
```

**Solutions**:

1. Verify CORS middleware is configured
2. Check client origin is allowed
3. Use development server without CORS issues

### Port Already in Use

```
Address already in use
```

**Solutions**:

```bash
# Windows: Find process using port 8000
netstat -ano | findstr :8000

# Kill process
taskkill /PID <PID> /F

# Or use different port
uvicorn main:app --port 8001
```

## Documentation

- [System Architecture](../docs/SYSTEM_ARCHITECTURE.md)
- [API Documentation](../docs/API_DOCUMENTATION.md)
- [Database Design](../docs/DATABASE_DESIGN.md)
- [Developer Guide](../docs/DEVELOPER_GUIDE.md)

## Security Best Practices

1. **Secrets Management**:
   - Never commit `.env` or `api_keys.csv`
   - Use environment variables in production
   - Rotate API keys regularly

2. **Input Validation**:
   - Pydantic validates all requests
   - Sanitize file uploads
   - Prevent SQL injection (N/A - MongoDB)

3. **Authentication**:
   - Passwords hashed with bcrypt
   - Plan JWT migration
   - Implement rate limiting

4. **HTTPS**:
   - Use in production
   - Valid SSL certificates
   - Redirect HTTP to HTTPS

## Version History

| Version | Date     | Changes                 |
| ------- | -------- | ----------------------- |
| 1.0     | May 2026 | Initial release         |
| 1.1     | Planning | JWT auth, rate limiting |
| 2.0     | Planning | Advanced AI features    |

## Contributing

See [CONTRIBUTING.md](../docs/contributing.md)

## Support

For issues:

1. Check this documentation
2. Review error messages
3. Check MongoDB connection
4. Check API keys configuration
5. Create GitHub issue with details

---

**Ready to start? Run `uvicorn main:app --reload` and visit http://127.0.0.1:8000/docs** for interactive API explorer!
