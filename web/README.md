# LegalEase Web Interface

**Status**: 🚀 In Development | Core Features Implemented | Beta Ready

A responsive web version of the LegalEase AI-powered legal assistant, built with vanilla HTML, CSS, and JavaScript.

## Overview

This web interface replicates the functionality and design of the Flutter mobile app:

- Dark theme matching the app's aesthetic (background: #131313, highlight: #FCE566)
- Chat-based interface with message bubbles
- Collapsible sidebar with chat history
- Real-time API integration with the LegalEase backend
- Fully responsive design (mobile, tablet, desktop)
- No build tools needed - pure vanilla JavaScript

## Features

✅ **Chat Management**

- Create new chats
- View chat history in sidebar
- Switch between chats
- Messages stored on backend (MongoDB)

✅ **Messaging**

- Send text messages
- Receive AI responses (AI integration ready)
- Auto-scrolling to latest messages
- Message persistence via API

✅ **UI/UX**

- Dark theme with yellow accents
- Responsive layout (mobile-first)
- Smooth animations
- Auto-expanding text input
- Drawer sidebar on mobile

✅ **API Integration**

- Connected to LegalEase backend (`http://127.0.0.1:8000`)
- Endpoints used:
  - `GET /users/{user_id}/chats` - Load all chats
  - `POST /users/{user_id}/chats` - Create new chat
  - `POST /chats/{chat_id}/messages` - Send message

### Planned Features (In Development)

🔄 **File Upload** - Document analysis and management  
🔄 **Authentication** - User login/signup flow  
🔄 **Chat Search** - Find conversations by keywords  
🔄 **Export** - Download chats as PDF/text  
🔄 **Share** - Generate shareable links  
🔄 **Voice Input** - Speech-to-text support  
🔄 **Real-time Sync** - WebSocket integration

## Development Status

| Feature             | Status         | Notes                                 |
| ------------------- | -------------- | ------------------------------------- |
| Chat Interface      | ✅ Complete    | Core chat UI functional               |
| Message Display     | ✅ Complete    | Supports text messages                |
| Sidebar Navigation  | ✅ Complete    | Chat list with switching              |
| API Integration     | ✅ Complete    | Backend connected                     |
| Responsive Design   | ✅ Complete    | Works on mobile/tablet/desktop        |
| Dark Theme          | ✅ Complete    | Consistent with brand colors          |
| File Upload         | 🚧 In Progress | UI ready, backend integration pending |
| User Auth           | 🚧 In Progress | Login UI drafted                      |
| Chat Export         | 🔲 Not Started | Planned for v1.1                      |
| Real-time WebSocket | 🔲 Not Started | Planned for v1.1                      |

## Recent Updates

- **v1.0 Alpha**: Core chat and messaging functionality
- **Responsive Layout**: Full mobile support added
- **Dark Theme**: Brand color implementation completed
- **API Integration**: Backend connection working
- **Message Persistence**: Chat history syncs with backend

## Files Included

| File           | Purpose                                           |
| -------------- | ------------------------------------------------- |
| `index.html`   | Main HTML structure (single page)                 |
| `styles.css`   | Styling and responsive layout                     |
| `index.html`   | Main HTML structure (single page)                 |
| `styles.css`   | Styling and responsive layout                     |
| `index.js`     | Main application bootstrapping and UI integration |
| `js/config.js` | Runtime configuration and API endpoint settings   |
| `js/api.js`    | API wrapper for backend communication             |
| `test.py`      | Python script to test all API endpoints           |
| `run.bat`      | Windows batch script to start HTTP server         |
| `README.md`    | This file                                         |

## How to Start

### Prerequisites

- Backend API running on `http://127.0.0.1:8000`
- MongoDB running with initialized database

### Option 1: Simple HTTP Server (Recommended)

**Using Python 3:**

```bash
cd web
python -m http.server 8080
```

**Using Python 2:**

```bash
cd web
python -m SimpleHTTPServer 8080
```

**Using Node.js (if installed):**

```bash
cd web
npx http-server -p 8080
```

Then open browser to: `http://localhost:8080`

### Option 2: Direct File

Simply open `index.html` in a web browser (works offline for UI, but won't connect to API).

**Warning:** CORS may block API calls if opening file directly. Use an HTTP server instead.

## Configuration

To change the API endpoint, edit `js/config.js`:

```javascript
const DEFAULT_API_BASE_URL = "http://127.0.0.1:8002";
```

You can also override the endpoint at runtime by opening the web app with a query string, for example:

```text
http://localhost:8080/?api_base_url=http://127.0.0.1:8002
```

To change the user ID, edit `js/config.js` and update the `DEFAULT_USER_ID` constant.

## API Endpoints

All endpoints use user ID: `user1` (configurable)

| Method | Endpoint                    | Purpose                                                 |
| ------ | --------------------------- | ------------------------------------------------------- |
| GET    | `/users/{user_id}/chats`    | Get all chats with messages                             |
| POST   | `/users/{user_id}/chats`    | Create new chat (body: `{"title": "..."}`)              |
| POST   | `/chats/{chat_id}/messages` | Send message (body: `{"user_id", "sender", "content"}`) |

## How It Works

1. **Load Chats**: App fetches all chats from backend on startup
2. **Select Chat**: Click chat in sidebar to view messages
3. **Send Message**: Type message and press Enter or click send
4. **Store**: Messages saved to MongoDB via API
5. **Refresh**: Chat list updates after each message

## Architecture

```
Web Interface (HTML/CSS/JS)
        ↓
    API (FastAPI)
        ↓
   MongoDB
```

- Web: Handles UI and user interactions
- API: Routes requests, handles business logic
- Database: Stores chats and messages

## Mobile Responsive

- **Mobile** (<768px): Drawer slides out, full-width messages
- **Tablet** (768px-1024px): Fixed sidebar, responsive layout
- **Desktop** (>1024px): Fixed sidebar, full layout

## Styling Notes

- **Colors**: See `styles.css` `:root` variables
- **Font**: Uses system fonts (no external dependencies)
- **Icons**: Inline SVGs (fast loading)
- **Layout**: Flexbox-based (IE11 compatible)

## Limitations & Future Work

- ❌ File upload not yet implemented (UI placeholder in place)
- ❌ AI responses currently mock/placeholder (replace `generateAiResponse()` in app.js)
- ❌ No user authentication (fixed user ID)
- ❌ No message editing/deletion (API ready for this)

## Troubleshooting

| Issue                   | Solution                                                 |
| ----------------------- | -------------------------------------------------------- |
| "Cannot connect to API" | Ensure backend is running: `python api/main.py`          |
| Chats not loading       | Check MongoDB is running: `mongosh`                      |
| CORS errors             | Use HTTP server instead of file:// URL                   |
| Styles not loading      | Verify `styles.css` is in same directory as `index.html` |

## Development

To modify the AI response, edit `generateAiResponse()` function in `app.js`:

```javascript
async function generateAiResponse(userQuery) {
  // Replace this with real AI API call
  // e.g., call Google Gemini, OpenAI, or custom backend AI
}
```

## Performance

- **Bundle Size**: 0 external dependencies (< 50KB total)
- **Load Time**: < 1s on typical connections
- **Browser Support**: Chrome, Firefox, Safari, Edge (last 2 versions)

## Development Notes

### API Alignment Fixes

The web interface was updated to match the actual API implementation:

1. **Field Names:** Changed `chat_id` → `id` in chat objects
2. **Message Handling:** API automatically creates both user + AI messages on POST to `/messages`
3. **Response Structure:** Updated to handle `{"user_message", "assistant_message"}` response format
4. **AI Responses:** Removed client-side AI generation (handled by backend)

### Testing

Both servers should be running:

- **API:** `http://127.0.0.1:8000` (uvicorn)
- **Web:** `http://localhost:8080` (python http.server)

Test endpoints:

```bash
# Health check
curl http://127.0.0.1:8000/health

# Get chats
curl http://127.0.0.1:8000/users/user1/chats

# Create chat
curl -X POST http://127.0.0.1:8000/users/user1/chats -H "Content-Type: application/json" -d '{"title":"Test Chat"}'
```

### Automated Testing

Run the comprehensive API test script:

```bash
cd web
python test.py
```

This script tests all endpoints used by the web interface:

- Health check
- Chat creation and retrieval
- Message sending and AI responses
- Data persistence verification

## License

Same as LegalEase: GNU General Public License v3.0
