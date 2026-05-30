# LegalEase Developer Guide

**Version**: 1.0  
**Last Updated**: May 20, 2026  
**Audience**: Developers working on LegalEase codebase

---

## Table of Contents

1. [Development Setup](#development-setup)
2. [Project Structure](#project-structure)
3. [Technology Stack](#technology-stack)
4. [Development Workflow](#development-workflow)
5. [Code Standards](#code-standards)
6. [API Development](#api-development)
7. [Mobile App Development](#mobile-app-development)
8. [Web Development](#web-development)
9. [Database Management](#database-management)
10. [Testing](#testing)
11. [Debugging](#debugging)
12. [Git Workflow](#git-workflow)
13. [Deployment](#deployment)

---

## Development Setup

### Prerequisites

**All Developers:**

- Git (version control)
- VS Code or preferred IDE
- Node.js 16+ (for web dev)
- Python 3.11+ (for API)

**Mobile Developers (Flutter):**

- Flutter SDK (stable channel)
- Android SDK (for Android emulator)
- Java Development Kit (JDK 11+)

**Database Developers:**

- MongoDB Community Server 5.0+
- MongoDB Compass (optional GUI)

### Initial Setup

1. **Clone Repository**:

```bash
git clone https://github.com/yourusername/legalease.git
cd legalease
```

2. **Configure Python Environment** (API):

```bash
cd api
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

3. **Setup MongoDB** (Database):

```bash
# Windows: Start MongoDB service
net start MongoDB

# Or run init script
cd db
pip install -r requirements.txt
python init_db.py
```

4. **Setup Flutter** (Mobile):

```bash
cd app
flutter pub get
```

5. **Setup Web** (Web):

```bash
cd web
# No installation needed - vanilla JS
# Just run HTTP server when ready
```

### Environment Variables

**API (.env file)**:

```
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=legalease
API_BASE_URL=http://127.0.0.1:8000
DEFAULT_SYSTEM_PROMPT=You are LegalEase...
GOOGLE_GEMINI_API_KEY=your_api_key_here
```

**Web (js/config.js)**:

```javascript
const DEFAULT_API_BASE_URL = "http://127.0.0.1:8000";
const API_TIMEOUT = 30000; // 30 seconds
```

---

## Project Structure

```
legalease/
├── api/                    # Backend FastAPI server
│   ├── main.py            # Application entry point
│   ├── requirements.txt    # Python dependencies
│   ├── api_keys.csv       # Google Gemini API keys
│   ├── .env               # Environment configuration
│   └── uploads/           # Temporary file storage
│
├── app/                   # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart      # App entry point
│   │   ├── models/        # Data models
│   │   ├── screens/       # UI screens
│   │   ├── services/      # Business logic
│   │   ├── theme/         # Theme configuration
│   │   └── widgets/       # Reusable UI components
│   ├── android/           # Android native code
│   ├── test/              # Unit tests
│   └── pubspec.yaml       # Dependencies
│
├── web/                   # Web application
│   ├── index.html         # Main HTML file
│   ├── styles.css         # Global styles
│   ├── index.js           # App initialization
│   ├── js/
│   │   ├── api.js         # API client
│   │   ├── chat.js        # Chat logic
│   │   ├── auth.js        # Authentication
│   │   ├── ui.js          # UI rendering
│   │   ├── config.js      # Configuration
│   │   └── utils.js       # Utilities
│   └── test.py            # API testing
│
├── db/                    # Database scripts
│   ├── init_db.py         # Initialization script
│   ├── requirements.txt    # Python dependencies
│   └── SCHEMA.md          # Schema documentation
│
├── docs/                  # Documentation
│   ├── SYSTEM_ARCHITECTURE.md
│   ├── API_DOCUMENTATION.md
│   ├── DATABASE_DESIGN.md
│   ├── USER_MANUAL.md
│   ├── DEVELOPER_GUIDE.md (this file)
│   ├── architecture.md
│   ├── contributing.md
│   └── deployment.md
│
├── README.md              # Project overview
├── LICENSE               # GPL v3 license
├── privacy_policy.md     # Privacy policy
└── terms_and_conditions.md # Terms of service
```

---

## Technology Stack

| Component        | Technology          | Version | Purpose              |
| ---------------- | ------------------- | ------- | -------------------- |
| Mobile           | Flutter             | 3.0+    | Cross-platform app   |
| Mobile Language  | Dart                | 3.0+    | App programming      |
| Backend          | FastAPI             | 0.100+  | REST API framework   |
| Backend Language | Python              | 3.11+   | Server programming   |
| Web              | JavaScript          | ES6+    | Client-side logic    |
| Database         | MongoDB             | 5.0+    | Document storage     |
| AI               | Google Gemini       | Latest  | LLM integration      |
| Async DB         | Motor               | Latest  | Async MongoDB driver |
| Validation       | Pydantic            | 2.0+    | Data validation      |
| Testing          | Pytest/Flutter Test | Latest  | Test framework       |
| Version Control  | Git                 | Latest  | Source management    |

---

## Development Workflow

### Local Development Environment

**Terminal 1 - MongoDB**:

```bash
net start MongoDB
# Verify: mongosh
```

**Terminal 2 - API Server**:

```bash
cd api
.venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Terminal 3 - Web Server**:

```bash
cd web
python -m http.server 8080
# Opens: http://localhost:8080
```

**Terminal 4 - Flutter/Mobile**:

```bash
cd app
flutter run
# Or: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### Feature Development Workflow

1. **Create Branch**:

```bash
git checkout -b feature/your-feature-name
# Example: feature/user-authentication
```

2. **Make Changes**:
   - Write code following standards
   - Add/update documentation
   - Write tests for new features

3. **Test Locally**:

```bash
# API
pytest api/tests/

# Flutter
flutter test

# Web
# Manual testing (no framework)
```

4. **Commit Changes**:

```bash
git add .
git commit -m "feat: add user authentication"
```

5. **Push to Remote**:

```bash
git push origin feature/your-feature-name
```

6. **Create Pull Request**:
   - Open on GitHub
   - Describe changes
   - Link related issues
   - Request review

7. **Merge to Main**:

```bash
git checkout main
git pull origin main
git merge feature/your-feature-name
git push origin main
```

---

## Code Standards

### Python (API)

**Style Guide**: PEP 8

**Key Rules**:

```python
# Good: Clear naming, type hints
async def get_user_chats(user_id: str) -> List[Chat]:
    """Retrieve all chats for a user."""
    chats = await db.chats.find({"ownerId": user_id}).to_list(None)
    return chats

# Bad: No type hints, unclear naming
async def get(u):
    return db.chats.find({"ownerId": u})
```

**Standards**:

- ✅ Type hints on all functions
- ✅ Docstrings for classes/functions
- ✅ Max line length: 100 characters
- ✅ 4-space indentation
- ✅ snake_case for variables/functions
- ✅ PascalCase for classes

### Dart/Flutter (Mobile App)

**Style Guide**: Dart Style Guide

**Key Rules**:

```dart
// Good: Clear naming, documentation
class ChatMessage {
  /// Unique message identifier
  final String messageId;

  /// User ID of message sender
  final String userId;

  /// Message content
  final String content;

  ChatMessage({
    required this.messageId,
    required this.userId,
    required this.content,
  });
}

// Bad: No documentation
class Message {
  final String id;
  final String uid;
  final String msg;
}
```

**Standards**:

- ✅ Comprehensive documentation
- ✅ camelCase for variables/functions
- ✅ PascalCase for classes
- ✅ Use const constructors where possible
- ✅ Null safety enabled
- ✅ Proper widget composition

### JavaScript (Web)

**Style Guide**: Airbnb JavaScript Style Guide

**Key Rules**:

```javascript
// Good: Clear naming, use const
const getUserChats = async (userId) => {
  const response = await fetch(`/users/${userId}/chats`);
  const data = await response.json();
  return data;
};

// Bad: Unclear naming, var usage
var getChats = function (u) {
  return fetch("/users/" + u + "/chats").then((r) => r.json());
};
```

**Standards**:

- ✅ Use const/let (no var)
- ✅ Arrow functions preferred
- ✅ camelCase for variables/functions
- ✅ JSDoc comments for functions
- ✅ Max line length: 100 characters
- ✅ Use async/await over promises when readable

---

## API Development

### Adding New Endpoints

**Step 1: Define Request/Response Models**:

```python
# In main.py or separate models file
class NewFeatureRequest(BaseModel):
    user_id: str = Field(..., min_length=1)
    data: str = Field(..., min_length=1)

class NewFeatureResponse(BaseModel):
    success: bool
    result: str
```

**Step 2: Implement Endpoint**:

```python
@app.post("/new-feature")
async def create_new_feature(request: NewFeatureRequest) -> NewFeatureResponse:
    """Create a new feature.

    Args:
        request: Request data containing user_id and feature data

    Returns:
        Response with success status and result

    Raises:
        HTTPException: If operation fails
    """
    try:
        # Validate user exists
        user = await db.users.find_one({"userId": request.user_id})
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Process feature
        result = process_feature(request.data)

        return NewFeatureResponse(success=True, result=result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

**Step 3: Test Endpoint**:

```python
# In tests/test_api.py
@pytest.mark.asyncio
async def test_new_feature():
    response = client.post("/new-feature", json={
        "user_id": "test_user",
        "data": "test data"
    })
    assert response.status_code == 200
    assert response.json()["success"] == True
```

**Step 4: Document Endpoint**:

- Update [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- Include request/response examples
- List error codes

### Error Handling

**Consistent error responses**:

```python
# Good: Specific error codes
if not valid_email(email):
    raise HTTPException(
        status_code=400,
        detail="Invalid email format"
    )

# Bad: Generic errors
if not valid_email(email):
    raise HTTPException(status_code=400)
```

### Database Queries

**Best Practices**:

```python
# Use async operations
chats = await db.chats.find({"ownerId": user_id}).to_list(None)

# Use indexes for fast queries
# Check query plan
await db.chats.find({"ownerId": user_id}).explain()

# Use appropriate operators
# Good: Indexed query
db.users.find_one({"email": email})

# Avoid: Full collection scans
db.users.find({"email": {"$regex": ".*pattern.*"}})
```

---

## Mobile App Development

### Project Structure

```
app/lib/
├── main.dart                   # Entry point
├── models/
│   ├── user.dart
│   ├── chat.dart
│   └── message.dart
├── screens/
│   ├── chat_screen.dart       # Main chat UI
│   ├── login_screen.dart      # Auth UI
│   ├── signup_screen.dart     # Registration
│   ├── settings_screen.dart   # Settings
│   └── live_call_screen.dart  # Calls
├── services/
│   ├── chat_service.dart      # Business logic
│   └── api_service.dart       # API calls
├── theme/
│   └── app_theme.dart         # Color scheme
└── widgets/
    ├── chat_drawer.dart       # Sidebar
    ├── message_bubble.dart    # Message UI
    ├── thinking_indicator.dart # Loading
    └── connectivity_banner.dart # Status
```

### Running the App

**Emulator**:

```bash
cd app
flutter run
```

**Physical Device**:

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d device_id

# With custom API
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

### State Management

**Using Provider**:

```dart
class ChatService extends ChangeNotifier {
  List<Chat> _chats = [];

  List<Chat> get chats => _chats;

  Future<void> loadChats(String userId) async {
    _chats = await api.getUserChats(userId);
    notifyListeners();
  }
}

// In UI:
Consumer<ChatService>(
  builder: (context, chatService, child) {
    return ListView(
      children: chatService.chats.map((chat) {
        return ChatTile(chat: chat);
      }).toList(),
    );
  },
)
```

### Adding New Screens

1. Create new file in `screens/`
2. Extend `StatefulWidget` or `StatelessWidget`
3. Use `Provider` for state
4. Navigate using `Navigator.push()`

```dart
class NewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Screen')),
      body: Center(child: Text('Content here')),
    );
  }
}
```

### Building Live Calls

Live Calls enable real-time voice interaction with the AI using Voice Activity Detection (VAD), transcription, and text-to-speech synthesis.

#### Key Components

**Voice Activity Detection (VAD)**

- Package: `vad` (Silero VAD engine)
- Asset: `assets/models/silero_vad_legacy.onnx`
- Detects speech automatically without manual triggering
- Low latency (60ms frame buffer)

**Audio Handling**

- Record: `permission_handler` for microphone permissions
- Playback: `audioplayers` for TTS audio
- Context: Android/iOS audio modes for concurrent recording/playback
- Allows user interruption while AI is speaking

**API Integration**

- Transcription endpoint: `POST /api/transcribe_raw` (sends audio bytes)
- Live call endpoint: `POST /api/live-call/record-interaction` (saves interaction)
- Returns: User text, AI response audio, metadata

#### Implementation Details

**State Variables** (in `live_call_screen.dart`):

```dart
late VadHandler _vadHandler;  // Voice detection handler
AudioPlayer _audioPlayer;      // Audio playback
double _micLevel = 0.0;        // Real-time microphone level
String _transcription = "";    // User's speech (text)
bool _isAiSpeaking = false;    // AI output state
bool _isThinking = false;      // Processing state
int _activeInteractionId = 0;  // ID for interruption tracking
```

**VAD Configuration**:

- `positiveSpeechThreshold: 0.55` - Higher threshold for accurate interruption
- `negativeSpeechThreshold: 0.35` - Hysteresis for stable detection
- `minSpeechFrames: 2` - Minimum frames to confirm speech
- `redemptionFrames: 30` - ~1 second pause allowed without cutting off

**User Interruption Logic**:

```dart
_vadHandler.onSpeechStart.listen((_) {
  _activeInteractionId++;  // Invalidate pending responses
  _audioPlayer.stop();     // Stop AI immediately
  _isAiSpeaking = false;
});

// Later: Check if user interrupted during transcription
if (myInteractionId != _activeInteractionId) {
  // Skip AI response - user was interrupted
  skipAiResponse = true;
}
```

**Audio Context Setup** (enables concurrent recording/playback):

```dart
_audioPlayer.setAudioContext(
  AudioContext(
    android: AudioContextAndroid(
      usageType: AndroidUsageType.voiceCommunication,
      audioMode: AndroidAudioMode.inCommunication,
      isSpeakerphoneOn: true,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: {
        AVAudioSessionOptions.defaultToSpeaker,
        AVAudioSessionOptions.allowBluetooth,
      },
    ),
  ),
);
```

#### Adding New Features to Live Calls

**Add Recording to File**:

```dart
// Store recordings for debugging
final File recordingFile = File('path/to/recording.wav');
await _audioPlayer.playToFile(recordingFile);
```

**Add Call History**:

```dart
// Save all live call interactions to local database
final callHistory = LiveCallInteraction(
  timestamp: DateTime.now(),
  userText: _transcription,
  aiResponse: aiText,
  duration: elapsedTime,
);
await localDb.saveLiveCallInteraction(callHistory);
```

**Implement Video Calls**:

```dart
// Requires WebRTC package integration
// Modify LiveCallScreen to include video widget
// Note: Not currently implemented
```

#### Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  vad: ^0.1.0 # Voice Activity Detection
  audioplayers: ^5.0.0 # Audio playback
  permission_handler: ^11.0.0 # Permissions
  http: ^1.1.0 # API calls
```

#### Permissions Required

In `android/app/build.gradle.kts`:

```gradle
manifestPlaceholders["PERMISSION_MICROPHONE"] = "android.permission.RECORD_AUDIO"
manifestPlaceholders["PERMISSION_INTERNET"] = "android.permission.INTERNET"
```

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## Web Development

### Project Setup

**No build tools needed** - vanilla JavaScript

**Development server**:

```bash
cd web
python -m http.server 8080
# Access at http://localhost:8080
```

### File Organization

```
web/
├── index.html     # DOM structure
├── styles.css     # All styles
├── index.js       # App startup
└── js/
    ├── api.js     # HTTP requests
    ├── chat.js    # Chat logic
    ├── auth.js    # Authentication
    ├── ui.js      # DOM manipulation
    ├── config.js  # Configuration
    └── utils.js   # Helpers
```

### Adding Features

**API Integration Example**:

```javascript
// In js/api.js
const API = {
  async getUserChats(userId) {
    const response = await fetch(
      `${CONFIG.API_BASE_URL}/users/${userId}/chats`,
    );
    return response.json();
  },
};

// In js/chat.js
async function loadChats() {
  const chats = await API.getUserChats(currentUserId);
  UI.renderChats(chats);
}

// In index.js
loadChats();
```

### DOM Manipulation

```javascript
// Good: Clear, reusable
const updateChatList = (chats) => {
  const list = document.getElementById("chat-list");
  list.innerHTML = chats
    .map(
      (chat) =>
        `<div class="chat-item" data-id="${chat.chatId}">${chat.title}</div>`,
    )
    .join("");
};

// Bad: Direct, hard to maintain
document.getElementById("chat-list").innerHTML =
  "<div>Chat 1</div><div>Chat 2</div>";
```

---

## Database Management

### Connecting to MongoDB

**Local Development**:

```bash
# Start MongoDB service (Windows)
net start MongoDB

# Verify connection
mongosh

# Show databases
show dbs

# Use LegalEase database
use legalease

# Show collections
show collections
```

### Running Database Scripts

```bash
# Initialize database
cd db
python init_db.py

# Backup
mongodump --db legalease --out backup_$(date +%Y%m%d)

# Restore
mongorestore --db legalease backup_20260520/legalease
```

### Common Queries

```javascript
// Create collection
db.createCollection("newCollection");

// Insert document
db.chats.insertOne({
  chatId: "chat_123",
  title: "New Chat",
  messages: [],
});

// Find documents
db.chats.find({ ownerId: "user_123" });

// Update document
db.chats.updateOne(
  { chatId: "chat_123" },
  { $set: { title: "Updated Title" } },
);

// Delete document
db.chats.deleteOne({ chatId: "chat_123" });

// Create index
db.chats.createIndex({ ownerId: 1 });
```

---

## Testing

### API Testing (Python)

**Using pytest**:

```bash
cd api
pip install pytest pytest-asyncio

# Run tests
pytest tests/

# Run with coverage
pytest --cov=. tests/
```

**Example test**:

```python
# tests/test_api.py
import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_health_check():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}
```

### Mobile Testing (Flutter)

**Run tests**:

```bash
cd app
flutter test
```

**Example test**:

```dart
// test/widget_test.dart
void main() {
  testWidgets('Chat message renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LegalEaseApp());

    expect(find.byType(ChatMessage), findsWidgets);
  });
}
```

### Web Testing

**Manual testing checklist**:

- [ ] Chats load correctly
- [ ] Messages send and receive
- [ ] Files upload successfully
- [ ] Responsive on mobile
- [ ] Dark theme applies
- [ ] API errors handled gracefully

---

## Debugging

### API Debugging

**Enable verbose logging**:

```python
# In main.py
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Check request/response**:

```python
@app.middleware("http")
async def log_requests(request, call_next):
    print(f"Request: {request.method} {request.url}")
    response = await call_next(request)
    print(f"Response: {response.status_code}")
    return response
```

**Test endpoints**:

```bash
# Simple GET
curl http://127.0.0.1:8000/health

# With JSON body
curl -X POST http://127.0.0.1:8000/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

### Flutter Debugging

**Enable verbose logging**:

```bash
flutter run -v
```

**Debug prints**:

```dart
print('Debug: User ID = $userId');
debugPrint('Message: $message'); // Doesn't truncate long strings
```

**DevTools**:

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Web Debugging

**Browser DevTools**:

- Open: F12 or Ctrl+Shift+I
- Console: Debug JavaScript
- Network: Monitor API calls
- Storage: View localStorage/sessionStorage

**Debug logging**:

```javascript
// Redirect console.log to custom handler
const originalLog = console.log;
console.log = function (...args) {
  originalLog(...args);
  // Send to server or display in UI
};
```

---

## Git Workflow

### Branching Strategy

**Branch naming**:

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation
- `test/description` - Testing improvements

**Example**:

```bash
# Create feature branch
git checkout -b feature/user-authentication

# Work and commit
git add .
git commit -m "feat: implement JWT authentication"

# Push to remote
git push origin feature/user-authentication
```

### Commit Messages

**Format**:

```
<type>: <subject>

<body>

<footer>
```

**Types**:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Code style (no logic change)
- `refactor:` - Code refactoring
- `test:` - Test updates
- `chore:` - Build/dependencies

**Examples**:

```
feat: add chat search functionality

Implement full-text search for user chats using MongoDB text indexes.
Improves chat discovery for users with many conversations.

Closes #123
```

### Code Review Checklist

Before merging, ensure:

- [ ] Code follows style guide
- [ ] Tests pass (100% coverage recommended)
- [ ] Documentation updated
- [ ] No hardcoded values
- [ ] Error handling complete
- [ ] Performance acceptable
- [ ] Security reviewed

---

## Deployment

### Development Deployment

**Local testing**:

```bash
# Terminal 1: MongoDB
net start MongoDB

# Terminal 2: API
cd api && uvicorn main:app --host 0.0.0.0 --port 8000

# Terminal 3: Web
cd web && python -m http.server 8080

# Terminal 4: Mobile
cd app && flutter run
```

### Production Deployment

**Backend (Docker)**:

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Database (MongoDB Atlas)**:

- Hosted cloud service
- Automatic backups
- Point-in-time recovery
- Monitoring and alerts

**Web (Vercel/Netlify)**:

- Deploy static files
- CDN distribution
- Automatic HTTPS
- Continuous deployment

**Mobile (Play Store)**:

- Build signed APK
- Submit to Google Play
- Beta testing program
- Staged rollout

---

## Performance Optimization

### API Optimization

```python
# Good: Indexed query, fast
db.chats.find({"ownerId": "user_123", "isPinned": True})

# Bad: Full collection scan, slow
db.chats.find({"title": {"$regex": "pattern"}})  # Without index
```

### Database Optimization

```javascript
// Create compound index for common queries
db.chats.createIndex({ ownerId: 1, createdAt: -1 });

// Use projection to reduce data
db.chats.find({}, { title: 1, createdAt: 1 }); // Exclude messages
```

### Frontend Optimization

```javascript
// Lazy load heavy components
const ChatComponent = React.lazy(() => import("./Chat"));

// Debounce expensive operations
const debounce = (fn, delay) => {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn(...args), delay);
  };
};

const handleSearch = debounce((query) => {
  // Search API call
}, 300);
```

---

## Resources

### Documentation

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Flutter Docs](https://flutter.dev/)
- [MongoDB Docs](https://docs.mongodb.com/)
- [MDN JavaScript](https://developer.mozilla.org/)

### Tools

- VS Code Extensions: Dart, Python, MongoDB
- Postman: API testing
- MongoDB Compass: Database GUI
- DevTools: Flutter debugging

### Community

- Stack Overflow (tag with framework)
- GitHub Issues (this repo)
- Official Discord communities
- YouTube tutorials

---

## Support

For questions or issues:

1. Check this guide
2. Search existing GitHub issues
3. Create new issue with details
4. Contact maintainers

Happy coding! 🚀
