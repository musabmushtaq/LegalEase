# LegalEase Mobile App - User Manual

**Version**: 1.0  
**Platform**: Android  
**Last Updated**: May 20, 2026

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Installation](#installation)
3. [Main Features](#main-features)
4. [Walkthrough: First Steps](#walkthrough-first-steps)
5. [Chat Management](#chat-management)
6. [Live Calls](#live-calls)
7. [Document Upload & Analysis](#document-upload--analysis)
8. [Settings & Preferences](#settings--preferences)
9. [Frequently Asked Questions](#frequently-asked-questions)
10. [Troubleshooting](#troubleshooting)
11. [Privacy & Security](#privacy--security)

---

## Getting Started

### What is LegalEase?

LegalEase is an AI-powered legal assistant that helps you:

- Ask legal questions and get intelligent responses
- Upload and analyze legal documents
- Generate legal templates and summaries
- Manage conversations about legal matters
- Export and share your work

**Perfect for:**

- Students studying law
- Legal professionals seeking a second opinion
- Business owners managing contracts
- Anyone needing accessible legal information

### Key Features at a Glance

✅ **Chat-Based Interface** - Intuitive conversation with an AI legal assistant  
✅ **Live Voice Calls** - Real-time audio conversation with AI, voice-to-text, automatic responses  
✅ **Document Upload** - Analyze PDFs, Word docs, images, and text files  
✅ **Smart Summaries** - Get concise summaries of complex legal documents  
✅ **Chat History** - Never lose important conversations  
✅ **Offline Support** - Some features work without internet  
✅ **Dark Theme** - Easy on the eyes for extended use  
✅ **Export & Share** - Save and share your legal analysis

---

## Installation

### System Requirements

- **Android Version**: 8.0 or higher
- **Storage Space**: At least 100 MB free
- **RAM**: 2 GB minimum
- **Internet**: Required for AI features (some offline support available)

### Installation Steps

#### Option 1: Play Store (Recommended)

1. Open **Google Play Store**
2. Search for **"LegalEase"**
3. Tap **Install**
4. Grant permissions when prompted
5. Tap **Open** once installation completes

#### Option 2: Direct APK Installation

1. **Download**: Get the APK file from the download link
2. **Enable Installation**: Go to Settings → Security → Unknown Sources → Enable
3. **Install**: Locate the APK and tap to install
4. **Permissions**: Grant requested permissions
5. **Launch**: Find LegalEase in your app drawer

#### Option 3: Development Installation (Developers)

```bash
# Build APK locally
cd app
flutter build apk

# Install on device
flutter install

# Or use ADB directly
adb install build/app/outputs/flutter-apk/app-release.apk
```

### First Launch

On first launch, LegalEase will:

1. Ask for necessary permissions (camera, storage, microphone)
2. Display a quick tutorial (can be skipped)
3. Take you to the login screen

---

## Main Features

### 1. Chat Interface

The main screen where you interact with LegalEase.

**Components:**

- **Message Area**: Read your conversation history
- **Input Box**: Type questions or legal queries
- **Send Button**: Submit your message
- **Attachment Icon**: Upload documents
- **Menu Icon**: Access settings and options

**How to Chat:**

1. Tap the input box at the bottom
2. Type your legal question
3. Press **Send** (or swipe up if keyboard doesn't show button)
4. Wait for AI response
5. Continue the conversation as needed

### 2. Document Upload

Analyze your legal documents with AI.

**Supported Formats:**

- PDF (`.pdf`) - Portable Document Format
- Word (`.docx`) - Microsoft Word documents
- Text (`.txt`) - Plain text files
- Images (`.png`, `.jpg`) - Screenshots of documents

**File Limits:**

- Maximum 50 MB per file
- Recommended: Keep files under 10 MB for faster processing

**How to Upload:**

1. In a chat, tap the **📎 Attachment** button
2. Choose file source:
   - **Gallery**: Select existing file
   - **Files**: Browse device storage
   - **Camera**: Photograph a document
3. Select file and confirm
4. Ask LegalEase to analyze it
5. Receive AI analysis and insights

### 3. Chat History

Access all your past conversations.

**Left Sidebar:**

- Shows all your chats
- Pinned chats appear at top
- Recent chats listed below
- Search chats (future feature)

**How to Use:**

1. **View Chat**: Tap any chat to open it
2. **Pin Chat**: Long-press → Pin (keeps at top)
3. **Archive Chat**: Long-press → Archive
4. **Delete Chat**: Long-press → Delete
5. **New Chat**: Tap **+ New Chat** button

### 4. Live Calls

Have real-time voice conversations with the AI assistant.

**Features:**

- 🎙️ **Voice Input**: Speak instead of typing
- 👂 **Audio Response**: Hear AI answers immediately
- ⚡ **Interruption**: Cut off AI anytime to ask follow-ups
- 📝 **Transcription**: See what was said in text
- 🔇 **Mute Control**: Toggle microphone on/off

**How to Start:**

1. Tap **🎤 Live Call** button or **☰ Menu** → **Live Call**
2. Grant microphone permission if first time
3. Start speaking naturally
4. App detects when you finish and gets AI response
5. Continue conversation or interrupt AI anytime

**Perfect for:**

- Hands-free conversation
- Complex questions better explained verbally
- Natural back-and-forth discussion
- When typing is inconvenient

### 5. Settings

Personalize your LegalEase experience.

**Available Settings:**

- **Theme**: Light/Dark mode
- **Notifications**: Enable/disable alerts
- **API Configuration**: Set custom API endpoint
- **About**: Version and app information
- **Help**: Access documentation
- **Logout**: Sign out of account

---

## Walkthrough: First Steps

### Step 1: Create an Account

**First-time users:**

1. Launch LegalEase
2. Tap **Sign Up**
3. Enter your details:
   - **Email**: Valid email address
   - **Username**: Display name (3-50 characters)
   - **Password**: Strong password (8+ characters)
   - **Professional Context**: (Optional) Tell us your role (e.g., "I'm a real estate attorney")
4. Tap **Create Account**
5. Welcome! You're now ready to start

### Step 2: Start Your First Chat

**After login:**

1. You'll see the main chat screen
2. Tap the input box at the bottom
3. Ask a legal question, for example:
   - "What is the difference between an LLC and an S-Corp?"
   - "Explain intellectual property rights in simple terms"
   - "What should I know about non-disclosure agreements?"
4. Tap **Send**
5. LegalEase will respond with a detailed answer

**Example Conversation:**

```
You: "I'm starting a small business. What legal structure should I choose?"

LegalEase: "Great question! Here are the main options:

**Sole Proprietorship**
- Simplest form
- Full liability
- Easy to start

**LLC (Limited Liability Company)**
- Personal liability protection
- Flexible taxation
- Requires registration

**S-Corporation**
- Professional structure
- Tax benefits
- More compliance required

I'd recommend consulting with a lawyer for your specific situation."
```

### Step 3: Upload a Document

**Add a contract for analysis:**

1. In your chat, tap the **📎 Attachment** icon
2. Choose **Gallery** or **Files**
3. Select a PDF or document
4. Ask: "Please review this contract and identify potential issues"
5. LegalEase analyzes and provides insights

### Step 4: Export Your Chat

**Save important conversations:**

1. Open any chat
2. Tap the **⋮ Menu** (three dots)
3. Select **Export**
4. Choose format:
   - **PDF**: For printing and sharing
   - **Text**: For editing
5. Save to your device

---

## Chat Management

### Creating Chats

**Start a new conversation:**

1. Tap **+ New Chat** on the home screen
2. (Optional) Enter a title
3. Start typing your first message
4. Default title: "New Chat" (can be renamed)

### Organizing Chats

**Pin Important Chats:**

- Long-press any chat
- Select **Pin**
- Pinned chats stay at the top for quick access

**Archive Completed Chats:**

- Long-press any chat
- Select **Archive**
- Archived chats are hidden but not deleted
- View archived chats in Settings

**Delete Chats:**

- Long-press any chat
- Select **Delete**
- ⚠️ **Warning**: Deletion is permanent

### Renaming Chats

**Change chat title:**

1. Open the chat
2. Tap the chat title at the top
3. Enter new title
4. Tap **Save** or press Enter

### Searching Chats

**Find specific conversations** (Future feature):

- Tap **🔍 Search** icon
- Enter keywords
- Browse results

---

## Live Calls

### What are Live Calls?

Live Calls is a **voice interaction feature** that lets you have real-time conversations with LegalEase's AI assistant. Instead of typing, you can:

- 🎙️ **Speak naturally** - Talk to the AI about legal questions
- 👂 **Hear responses** - Get immediate audio answers
- ⚡ **Interrupt seamlessly** - Cut off the AI anytime to ask follow-up questions
- 📝 **See transcriptions** - Written record of what was said appears on screen

**Best for:**

- Hands-free questions while busy
- Natural conversation flow
- Difficult-to-type questions
- Testing complex legal scenarios verbally

### Getting Started with Live Calls

**Requirements:**
✅ Microphone permission granted  
✅ Good internet connection  
✅ Android 8.0+  
✅ At least 100 MB free storage

### Starting a Live Call

**Method 1: From Home Screen**

1. Tap **🎤 Live Call** button (if visible on home)
2. Or tap **☰ Menu** → **Live Call**

**Method 2: From Chat Screen**

1. Open any chat
2. Tap **🎤 Call** icon (top right)
3. Live Call screen opens in that chat

### How to Use Live Calls

#### Step 1: Grant Microphone Permission

- First use will prompt for microphone access
- Tap **Allow**
- If denied, go to Settings → Apps → LegalEase → Permissions → Grant Microphone

#### Step 2: Start Speaking

- Tap the **microphone icon** or simply start speaking
- The app automatically detects speech using Voice Activity Detection (VAD)
- Visual indicator shows:
  - 🔵 **Blue wave** = You're speaking (user turn)
  - 🟡 **Golden wave** = AI is speaking (AI turn)

#### Step 3: Let AI Respond

- After you finish speaking, the app:
  1. Transcribes your speech to text (visible on screen)
  2. Sends to AI for processing (shows "🤔 Thinking...")
  3. Generates audio response
  4. Plays response back with text visible

#### Step 4: Interrupt or Continue

- **To ask a follow-up**: Just start speaking while AI is responding
  - AI will stop immediately
  - Your new question is recorded
  - Process repeats
- **To let AI finish**: Wait for response to complete
  - Tap microphone when ready to speak next

### Live Call Features Explained

#### 🎙️ Microphone Level Indicator

- **Animated wave visualization** shows audio levels
- Helps you know if mic is picking up your voice
- Green/blue wave = Good signal
- Flat line = Not detecting speech (try speaking louder)

#### 🤐 Mute Function

- **Tap 🔇 Mute button** to temporarily disable microphone
- Button shows **🔊 Unmute** when muted
- Useful if background noise is present
- AI can still speak while muted

#### 📝 Live Transcription

- Your speech appears as text in real-time
- Shows what the AI "heard" from you
- Helps you verify accuracy before AI responds

#### 💬 Chat History

- All live call interactions are saved to chat
- Shows both:
  - Your spoken message (transcribed to text)
  - AI's response (both audio and text)
- You can refer back anytime

#### 🎵 Audio Control

- Use phone volume buttons to adjust AI voice volume
- Speaker is active by default
- Can use headphones or earbuds

### Tips for Better Live Calls

**For Clear Recognition:**
✅ Speak in a normal conversational tone  
✅ Use clear, distinct words  
✅ Avoid background noise when possible  
✅ Let the app detect pauses naturally  
✅ Speak at a steady pace

**Talking Points:**
✅ "Explain tax implications of this contract"  
✅ "What are my rights if..."  
✅ "Summarize this employment agreement"  
✅ "What are the risks here?"  
✅ "Can you compare these two clauses?"

**Challenging Questions:**
✅ Legal jargon is understood  
✅ Complex scenarios work well  
✅ Follow-ups and clarifications supported  
✅ Interruption always works

### Live Call Limitations

⚠️ **Background Noise**: High noise can reduce accuracy  
⚠️ **Internet Required**: Real-time processing needs connection  
⚠️ **Not for Emergencies**: Don't use for urgent legal matters  
⚠️ **Audio Quality**: Very poor mic quality may affect transcription  
⚠️ **Multiple Speakers**: Only single speaker recognized (your voice)

### Troubleshooting Live Calls

**"Microphone not working"**
→ Grant permission: Settings → Apps → LegalEase → Permissions → Microphone  
→ Restart app  
→ Check phone microphone (not damaged)

**"AI not responding"**
→ Check internet connection  
→ Wait 5-10 seconds (processing may take time)  
→ Tap the microphone icon to retry

**"Can't hear AI"**
→ Check phone volume (use volume buttons)  
→ Ensure speaker isn't muted  
→ Try with headphones

**"Transcription is inaccurate"**
→ Speak more clearly and slowly  
→ Reduce background noise  
→ Move microphone closer to mouth

**"Getting cut off mid-sentence"**
→ Pause briefly between thoughts  
→ App may think you're done (designed for natural pauses)  
→ Continue speaking - it will capture all speech

### Exiting Live Call

**To return to normal chat:**

1. Tap **← Back** or **X** button
2. All interactions are saved automatically
3. Can continue with typed messages if preferred

---

## Document Upload & Analysis

### What You Can Upload

| Format  | Use Case                               | Max Size |
| ------- | -------------------------------------- | -------- |
| PDF     | Contracts, agreements, court documents | 50 MB    |
| DOCX    | Word documents, templates              | 50 MB    |
| TXT     | Plain text documents                   | 10 MB    |
| PNG/JPG | Document photos, screenshots           | 20 MB    |

### Upload Process

**Step-by-step:**

1. **Initiate Upload**
   - Tap 📎 attachment icon in chat
   - Select **Gallery**, **Files**, or **Camera**

2. **Select File**
   - Browse to document
   - Tap to select
   - Confirm selection

3. **Upload Confirmation**
   - File preview appears
   - Confirm to proceed
   - Upload begins

4. **Processing**
   - Progress indicator shows upload status
   - Once complete, file is added to message

5. **Analysis**
   - Ask LegalEase to analyze the document
   - Receive AI-powered insights

### Example Document Analysis

**"Please review this employment contract and highlight potential issues"**

```
LegalEase Analysis:

✓ POSITIVE ASPECTS
- Clear termination clause
- Standard benefits package
- Appropriate confidentiality provisions

⚠️ ITEMS TO REVIEW
- Non-compete clause duration (3 years) - consider if appropriate
- Intellectual property assignment - review job duties
- Dispute resolution method - no arbitration clause specified

⚠️ MISSING ITEMS
- Remote work policy
- Professional development provisions
- Performance review schedule

Recommendation: Have legal counsel review before signing.
```

### Document Storage

**Where documents are stored:**

- Local device storage (encrypted)
- Your LegalEase account (synced)
- Associated with relevant chats

**Security:**

- Files never shared without permission
- Deletion removes all copies
- Private by default

---

## Settings & Preferences

### Account Settings

**Access:** Tap **⚙️ Settings** → **Account**

- **Username**: Change display name
- **Email**: Update email address (primary login)
- **Password**: Change account password
- **Context**: Update professional background
- **Delete Account**: Permanently remove all data

### App Settings

**Access:** Tap **⚙️ Settings** → **App**

| Setting         | Options              | Default |
| --------------- | -------------------- | ------- |
| Theme           | Light, Dark, Auto    | Auto    |
| Notifications   | On, Off              | On      |
| Font Size       | Small, Normal, Large | Normal  |
| Auto-save Chats | On, Off              | On      |
| Offline Mode    | On, Off              | On      |

### API Configuration

**For power users/developers:**

1. Tap **⚙️ Settings** → **Developer**
2. Enter custom API endpoint (if hosting locally)
3. Default: Production server
4. Changes apply after app restart

**Example Custom Endpoint:**

```
http://192.168.1.100:8000
```

### Notification Settings

**Customize alerts:**

1. Tap **⚙️ Settings** → **Notifications**
2. Enable/disable:
   - **Message Alerts**: New AI responses
   - **Email Notifications**: Digest emails
   - **Sound**: Alert sound on/off
   - **Vibration**: Vibration feedback

---

## Frequently Asked Questions

### Q1: Is my data private?

**A:** Yes! LegalEase prioritizes privacy:

- Your chats and documents are stored securely
- Only you can access your data
- AI analysis is processed securely
- We don't sell or share your information
- See Privacy Policy for details

### Q2: How accurate is the AI advice?

**A:** LegalEase provides educated suggestions, but:

- ⚠️ **Not a substitute for real lawyers**
- Always consult qualified legal professionals
- Use for learning and initial analysis
- Verify important information independently

### Q3: Can I access my chats on multiple devices?

**A:** Yes!

- Sign in on any device
- Chats sync automatically
- Access your account from web or app
- Chats update in real-time

### Q4: What if I lose my password?

**A:**

1. Tap **Forgot Password?** on login screen
2. Enter your email
3. Check your email for reset link
4. Follow link to create new password
5. Return to app and log in

### Q5: Can I use LegalEase offline?

**A:** Partially:

- ✅ View chat history offline
- ✅ Read previous responses
- ✅ Compose new messages
- ❌ AI responses require internet
- ❌ Document upload requires internet
- Messages sync when you reconnect

### Q6: How do I delete my account?

**A:**

1. Tap **⚙️ Settings** → **Account**
2. Scroll to bottom
3. Tap **Delete Account**
4. Confirm deletion (irreversible)
5. All data will be permanently removed

### Q7: Can I share chats with others?

**A:** Coming soon!

- Generate shareable links
- Grant read-only access
- Revoke access anytime
- Future release

### Q8: What file types are supported?

**A:**

- ✅ PDF, DOCX, TXT (documents)
- ✅ PNG, JPG (images)
- ✅ JPEG (photos)
- ❌ XLS, PPT, ZIP (not yet supported)
- ❌ Executable files (for security)

### Q9: How do I report a bug?

**A:**

1. Tap **⚙️ Settings** → **Help**
2. Select **Report Bug**
3. Describe the issue
4. Include screenshots if possible
5. Submit (automatically includes logs)

### Q10: Is there a web version?

**A:** Yes!

- Access LegalEase from any web browser
- Same account as mobile app
- Synchronized chats
- Visit: `https://legalease.example.com`

---

## Troubleshooting

### Connection Issues

**Problem**: "Cannot connect to server"

**Solutions:**

1. Check internet connection (WiFi or mobile data)
2. Verify API server is running
3. Check firewall settings
4. Restart the app
5. Restart your device
6. Try switching networks (WiFi ↔ Mobile)

**For developers**:

```bash
# Check if API is running
curl http://127.0.0.1:8000/health

# For custom endpoint
curl http://your-ip:8000/health
```

### File Upload Problems

**Problem**: "File upload failed"

**Solutions:**

1. Check file size (max 50 MB)
2. Verify file format is supported
3. Check storage permissions granted
4. Try again with smaller file
5. Free up device storage

**Permissions check:**

1. Tap **⚙️ Settings** → **Permissions**
2. Verify **Storage** is enabled
3. Verify **Camera** is enabled (if uploading via camera)

### Slow Performance

**Problem**: "App is slow or laggy"

**Solutions:**

1. Close other apps (free up RAM)
2. Clear app cache:
   - Settings → Apps → LegalEase → Storage → Clear Cache
3. Update to latest app version
4. Restart your device
5. Free up device storage (if <1GB free)

### Login Issues

**Problem**: "Cannot log in"

**Solutions:**

1. Verify email and password
2. Check **Caps Lock** isn't on
3. Use **Forgot Password** if unsure
4. Ensure internet connection
5. Clear app cache and try again

**Still stuck?**

- Contact support@legalease.example.com
- Include error message and device info

### Crashes or Freezes

**Problem**: "App crashes or becomes unresponsive"

**Solutions:**

1. **Force Close**:
   - Settings → Apps → LegalEase → Force Stop
   - Reopen app

2. **Clear Cache**:
   - Settings → Apps → LegalEase → Storage → Clear Cache
   - Reopen app

3. **Reinstall**:
   - Uninstall LegalEase
   - Restart device
   - Reinstall from Play Store

4. **Check Storage**:
   - Ensure at least 100 MB free storage
   - Delete unused apps/files

**Report persistent crashes:**

- Tap **⚙️ Settings** → **Help** → **Report Bug**

---

## Privacy & Security

### Data Protection

**Your information is protected by:**

1. **Encryption**
   - Data encrypted in transit (SSL/TLS)
   - Passwords hashed with bcrypt
   - Documents encrypted at rest

2. **Access Control**
   - Only you access your data
   - No sharing without permission
   - API authentication required

3. **Security Measures**
   - Regular security audits
   - Vulnerability scanning
   - Staff access logging

### What Data We Collect

**Essential:**

- Email address (login)
- Username (display)
- Password hash (authentication)
- Chat content (your conversations)
- Uploaded documents
- Professional context (your input)

**Optional:**

- Device info (for diagnostics)
- IP address (connection logging)
- Usage analytics (if enabled)

### Data You Control

You can:

- ✅ View all your data
- ✅ Edit profile information
- ✅ Delete chats
- ✅ Download your data
- ✅ Delete your account

### Privacy Policy

For full details, see [Privacy Policy](../privacy_policy.md)

### Terms of Service

For legal terms, see [Terms & Conditions](../terms_and_conditions.md)

---

## Getting Help

### Support Resources

1. **In-App Help**:
   - Tap **⚙️ Settings** → **Help**
   - Browse FAQ
   - Contact support

2. **Documentation**:
   - Visit [LegalEase Docs](../docs/)
   - Read architecture and guides

3. **Contact Support**:
   - Email: support@legalease.example.com
   - Response time: 24-48 hours
   - Include device model and app version

### Provide Feedback

Help us improve!

1. Tap **⚙️ Settings** → **Feedback**
2. Rate your experience
3. Share suggestions
4. Submit

---

## Tips & Tricks

### Pro Tips

1. **Effective Prompts**: Be specific in your questions
   - ✅ "Review this employee termination agreement for potential issues"
   - ❌ "Is this contract okay?"

2. **Organize with Titles**: Give chats descriptive names
   - ✅ "Lease Review - Commercial Property"
   - ❌ "Chat 1"

3. **Use Attachments**: Include documents in questions
   - Ask LegalEase to analyze your specific documents
   - Get context-specific advice

4. **Pin Important Chats**: Keep frequently used templates accessible

5. **Export as Backup**: Regularly export important chats

### Keyboard Shortcuts

- **Send Message**: Tap send button
- **New Line**: Shift + Enter
- **Clear Input**: Swipe left on input box

---

## Version History

| Version     | Date     | Changes                      |
| ----------- | -------- | ---------------------------- |
| 1.0         | May 2026 | Initial release              |
| Coming: 1.1 | Q3 2026  | Chat sharing, templates      |
| Coming: 1.2 | Q4 2026  | Voice input, advanced search |

---

## Acknowledgments

Thank you for using LegalEase! We're committed to providing accessible legal assistance to everyone.

For more information, visit [LegalEase.com](https://legalease.example.com)
