# LegalEase - Complete User Manual

**Version**: 1.0 
**Platforms**: Android (Mobile App) & Modern Web Browser (Vite Web App) 
**Last Updated**: May 31, 2026

---

## Table of Contents

1. [Getting Started & Overview](#getting-started)
2. [Installation & Setup](#installation)
3. [Main Interface Options](#main-interface-options)
   - [Modern Web Interface (Vite + Vanilla JS)](#modern-web-interface)
   - [Mobile Web Responsiveness & Touch Enhancements](#mobile-web-responsiveness--touch-enhancements)
4. [Chat & Session Management](#chat-management)
5. [Live Conversational Calls (Voice Support)](#live-calls)
6. [Document Upload & Intelligent Analysis](#document-upload--analysis)
7. [Context-Aware Personalization (Persona Mode)](#context-aware-personalization)
8. [Settings, Privacy, & Purging Profile Context](#settings--preferences)
9. [Frequently Asked Questions (FAQ)](#frequently-asked-questions)
10. [Troubleshooting & Support](#troubleshooting)
11. [Data Security & Privacy Protections](#privacy--security)

---

## Getting Started

### What is LegalEase?

LegalEase is a premium, AI-powered legal assistant accessible via a dynamic Web Application (Vite + Vanilla JS) and a robust Android Mobile App (Flutter). It helps you:

- Ask complex legal questions and receive intelligent, personalized responses
- Upload and inspect legal documents (contracts, leases, agreements)
- Generate legal templates, summaries, and audit reports
- Maintain persistent, contextual conversations across multiple devices
- Personalize responses automatically using a dynamic user background context
- Converse naturally in real-time via hands-free voice calls

**Perfect for:**
- Law students and academic researchers
- Business owners drafting or inspecting service contracts
- Legal professionals seeking prompt reference analysis
- Individuals needing clear, accessible explanations of legal jargon

### Key Features at a Glance

 **Modern Responsive UI** - Harmonious dark mode design with glassmorphic accents tailored for both desktop and mobile web viewports.
 **Context-Aware Personalization** - Transparent, automated profile building based on your chat history, allowing the AI to tailor legal advice to your specific profession or location.
 **Live Conversational Calls** - Real-time audio streams with Voice Activity Detection (VAD), Whisper-powered transcription, and Kokoro speech generation.
 **Intelligent Document Upload** - Direct extraction and analysis of PDFs, Word documents, images, and text attachments.
 **Offline Resilience** - Native caching mechanisms that allow you to read recent chats and queue message updates even when internet access is interrupted.
 **Key Rotation Protection** - Automatic, behind-the-scenes rotation of API credentials to ensure 100% service availability and zero rate-limiting interruptions.

---

## Installation & Setup

### System Requirements

#### Mobile Application (Android)
- **Android Version**: 8.0 (Oreo) or higher
- **Storage Space**: At least 100 MB free for app cache
- **Permissions Required**: Microphone (for Live Calls), Storage/Camera (for file uploads)

#### Web Application (Browser)
- **Supported Browsers**: Google Chrome, Mozilla Firefox, Apple Safari, Microsoft Edge (modern versions)
- **Platform**: Fully compatible with desktop, tablet, and mobile browsers
- **Vite Local Server (for Developers/Self-hosters)**: Node.js v18+ and npm installed

---

### Setup & Launch Steps

#### Web Interface (Recommended & Easiest)
For end-users accessing a deployed instance, simply navigate to the provided web address in your browser (e.g., `https://legalease.example.com`).

If you are running the Web Interface locally:
1. Open a terminal and navigate to the project directory:
   ```bash
   cd web
   ```
2. Install npm dependencies (compiles Vite scripts and bundles premium stylesheets):
   ```bash
   npm install
   ```
3. Run the Vite development server:
   ```bash
   npm run dev
   ```
4. Click or navigate to the localhost address reported in your terminal (typically `http://localhost:8080`).

---

#### Android Mobile App

##### Option 1: Play Store (Recommended)
1. Open the **Google Play Store** on your Android device.
2. Search for **"LegalEase AI"**.
3. Tap **Install** and accept basic runtime prompts.
4. Launch the application from your app drawer.

##### Option 2: Direct APK Installation
1. **Download**: Secure the `.apk` release file from the repository releases page.
2. **Enable Unknown Sources**: Navigate to your device settings -> Apps -> Special App Access -> Install Unknown Apps -> Allow from your browser.
3. **Install**: Tap the downloaded APK in your Downloads folder and follow installation steps.

---

### First Launch Checklist

On your first launch (whether on Web or Mobile):
1. **API Server Hook**: Verify the green status indicator. If self-hosting, click **Settings ()** and adjust the API Base URL (defaults to `http://127.0.0.1:8000`).
2. **Authentication**: Choose **Login / Sign Up** in the navigation bar to create a secure JWT-authenticated account.
3. **Microphone Permissions**: If you plan to use voice features, grant the browser or app access to your microphone when prompted.

---

## Main Interface Options

LegalEase offers a premium, modern user interface designed to maximize accessibility, readability, and speed across both desktop and handheld touch screens.

---

### Modern Web Interface (Vite + Vanilla JS)

The Vite-compiled SPA provides a desktop-class console with:
- **Glassmorphic Top Bar**: Displays your current authentication username (e.g., "Guest" or your custom username), diagnostic connection banner, and settings shortcuts.
- **Collapsible Sidebar (Drawer)**: Clean sliding list of past chats with a real-time responsive Search input. You can pin important chats (pinned items stay locked to the top with a star icon), rename chats, or purge individual threads.
- **Interactive Chat Container**: Implements progressive-rendering message bubbles, a dynamic typing "thinking dot" animation while the AI generates legal insights, and a separate typewriter display for fresh stream replies.
- **Attachment Drawer Console**: Floating glass panel that allows you to:
  - **Upload Files**: Browse device storage for PDFs, Word docs, images, or raw text.
  - **Toggle Persona Mode**: Turn on the context injection system.

---

### Mobile Web Responsiveness & Touch Enhancements

When accessed on a mobile web browser or handheld device, the interface automatically scales and shifts layouts using responsive CSS declarations to optimize touch interactions:
- **Collapsible Side-Drawer Navigation**: Accessed via a modern, glassmorphic cards-style header menu button on the top left.
- **Adaptive Welcome Greetings**: Displays a dynamic greetings banner that adapts automatically based on your device's current time of day (e.g., *"Good morning"*, *"Good afternoon"*, *"Good evening"*).
- **Oversized Thumb-Friendly Compose Console**: Features a massive 60px touch compose bar at the bottom, equipped with large, easy-to-tap circular buttons for sending messages and opening attachments.
- **Oversized Bubble Typography (18px)**: Chat bubbles automatically scale up their text content to a comfortable 18px font size, reducing optical fatigue and eye strain during detailed document reviews on smaller screens.
- **Touch-Friendly Drawer Actions**: Sidebar chat lists have expanded hit zones and intuitive controls for smooth management on mobile viewports.

---

### Context-Aware Personalization (Persona Mode)

Unlike traditional chatbots that treat every query in isolation, LegalEase features a background context-aggregation pipeline:
- **Transparent Learning**: When logged into your account, an asynchronous background task analyzes your chat topics (e.g., tenancy issues, corporate filings, intellectual property) and aggregates these facts into a unified **User Profile Context**.
- **Personalized Context Mode**: Toggle the "Persona / Context" pill in the attachment console. When active, the backend injects your aggregated persona details directly into the Gemini AI generation pipeline, ensuring suggestions are automatically tailored to your state/jurisdiction, professional role, and preferences.
- **Full Control & Purging**: Under the settings panel (), you can view your running personal context, manually override it, or permanently purge all stored inferred AI facts with a single click.

---

### Temporary & Offline Modes
- **Temporary Chat Mode**: Toggle this mode on/off instantly via the side drawer to conduct private legal queries. In temporary mode, chats are stored strictly in your local browser cache and never hit the MongoDB server databases.
- **Offline Resiliency Banner**: Displays an informative warning banner if API server connectivity is lost, switching the app automatically to offline view mode so you can browse existing chat threads.

---

**Available Settings:**

- **Theme**: Light/Dark mode
- **Notifications**: Enable/disable alerts
- **API Configuration**: Set custom API endpoint
- **About**: Version and app information
- **Help**: Access documentation
- **Logout**: Sign out of account

---

## Walkthrough: First Steps

### Step 1: Create a JWT-Authenticated Account
1. Open the **LegalEase Web App** in your browser or launch the **Mobile App**.
2. Click the **Login / Sign Up** button in the sidebar drawer or footer.
3. In the modal, select **Create one** (to toggle the Sign Up form).
4. Enter your preferred username, valid email, and a strong password. Click **Sign Up**.
5. Once registered, you will be automatically logged in, and your username will be displayed at the top right of the top bar.

---

### Step 2: Start Your First Conversational Thread
1. Once logged in, click the **+ New Chat** button (on web, located next to the menu drawer trigger in the top bar; on mobile, inside the sidebar drawer).
2. A clean chat interface opens, displaying the time-of-day greeting (e.g. *"Good afternoon!"*).
3. Type a query in the bottom compose console. For example:
   - *"What are the standard terms required in a commercial sublease agreement?"*
   - *"Explain the difference between indemnification and limitation of liability in simple terms."*
4. Tap **Send** (or press `Enter` on your physical keyboard).
5. The AI assistant progressive-renders its analysis, utilizing clean markdown formatting.

---

### Step 3: Analyze a Legal Document
1. Inside your active chat thread, click the ** Attach** icon on the left of the compose box.
2. In the attachment menu, select **File / Image**.
3. Browse and select your target document (PDF, Word, TXT, or JPEG/PNG photo).
4. An attachment preview pill will appear directly above the input box showing your file name.
5. In the compose input, type a prompt describing your request:
   - *"Please analyze this employment agreement for hidden liabilities and highlight any non-compete clauses."*
6. Click **Send**.
7. The file is uploaded directly to the backend MongoDB files server, and the Gemini AI inspects the document contents, generating a comprehensive compliance report.

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
- Warning: **Warning**: Deletion is permanent

### Renaming Chats

**Change chat title:**

1. Open the chat
2. Tap the chat title at the top
3. Enter new title
4. Tap **Save** or press Enter

### Searching Chats

**Find specific conversations instantly:**

- Click the search input field located at the top of the sidebar drawer.
- Type keywords. The system queries your message contents.
- The sidebar dynamically filters the conversation list to display matching chats. Clear the search input to restore the full list.

---

## Live Conversational Calls (Voice Support)

### What are Live Calls?

Live Calls is a high-performance **real-time voice interface** that leverages specialized local AI models hosted directly on the LegalEase backend. Instead of typing, you can speak naturally, and the AI will transcribe your voice, formulate legal context, and stream human-like synthesized voice responses back to you instantly.

Key speech assets running locally on the backend:
- **Speech-to-Text (STT)**: `faster-whisper` (utilizing CUDA-quantized Whisper large-v3-turbo GPU pipelines) transcribes your verbal inputs with extreme precision.
- **Text-to-Speech (TTS)**: `kokoro` (Kokoro-82M ONNX model) synthesizes human-like audio streams, bypassing cloud-based TTS latency.

---

### Key Voice Features

- **Hands-Free Operation**: Speak naturally without needing to tap send. Voice Activity Detection (VAD) automatically identifies when you start and stop talking.
- **Seamless Interruption**: Cut off the AI voice mid-sentence at any point. Simply start speaking a follow-up query, and the audio output immediately mutes, switching automatically to record your next question.
- **Dual Text + Audio Transcriptions**: As the AI speaks, the text transcription progressive-renders inside the active chat timeline.
- **Real-Time VAD Visualizers**: Beautiful animated wave indicators clearly illustrate who has the floor:
  - **Blue Waves**: App is actively listening to you speak (User turn).
  - **Golden/Orange Waves**: The AI is currently playing synthesized audio replies (AI turn).

---

### How to Use Live Calls

#### 1. Launching the Voice Console
- **Web App**: Click the ** Live Call** microphone button at the top right of the top bar (next to Settings).
- **Mobile App**: Tap the ** Call** icon in the upper right header within any active chat.

#### 2. Granting Microphone Permissions
- When prompted, grant your browser or Android OS permission to capture audio.
- *Note:* If you experience issues, verify that microphone access is permitted under your browser security settings (click the padlock icon in the URL bar) or under Android App Info Permissions.

#### 3. Conversing with the AI
- Start speaking. The visualizer will animate with **blue waves**, indicating signal level.
- When you pause naturally, the local Whisper model transcribes your query, and the Gemini assistant starts formulating its brief, conversation-tailored answer.
- The VAD indicator will switch to **golden waves** as the local Kokoro pipeline streams natural-sounding speech through your device speakers.
- **To interrupt the AI**: Simply speak. The golden visualizer immediately turns blue, and the audio playback halts to capture your new statement.

---
- Helps you verify accuracy before AI responds

#### Chat History

- All live call interactions are saved to chat
- Shows both:
  - Your spoken message (transcribed to text)
  - AI's response (both audio and text)
- You can refer back anytime

#### Audio Control

- Use phone volume buttons to adjust AI voice volume
- Speaker is active by default
- Can use headphones or earbuds

### Tips for Better Live Calls

**For Clear Recognition:**
 Speak in a normal conversational tone 
 Use clear, distinct words 
 Avoid background noise when possible 
 Let the app detect pauses naturally 
 Speak at a steady pace

**Talking Points:**
 "Explain tax implications of this contract" 
 "What are my rights if..." 
 "Summarize this employment agreement" 
 "What are the risks here?" 
 "Can you compare these two clauses?"

**Challenging Questions:**
 Legal jargon is understood 
 Complex scenarios work well 
 Follow-ups and clarifications supported 
 Interruption always works

### Live Call Limitations

Warning: **Background Noise**: High noise can reduce accuracy 
Warning: **Internet Required**: Real-time processing needs connection 
Warning: **Not for Emergencies**: Don't use for urgent legal matters 
Warning: **Audio Quality**: Very poor mic quality may affect transcription 
Warning: **Multiple Speakers**: Only single speaker recognized (your voice)

### Troubleshooting Live Calls

**"Microphone not working"**
-> Grant permission: Settings -> Apps -> LegalEase -> Permissions -> Microphone 
-> Restart app 
-> Check phone microphone (not damaged)

**"AI not responding"**
-> Check internet connection 
-> Wait 5-10 seconds (processing may take time) 
-> Tap the microphone icon to retry

**"Can't hear AI"**
-> Check phone volume (use volume buttons) 
-> Ensure speaker isn't muted 
-> Try with headphones

**"Transcription is inaccurate"**
-> Speak more clearly and slowly 
-> Reduce background noise 
-> Move microphone closer to mouth

**"Getting cut off mid-sentence"**
-> Pause briefly between thoughts 
-> App may think you're done (designed for natural pauses) 
-> Continue speaking - it will capture all speech

### Exiting Live Call

**To return to normal chat:**

1. Tap **<- Back** or **X** button
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
   - Tap attachment icon in chat
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

Pass POSITIVE ASPECTS
- Clear termination clause
- Standard benefits package
- Appropriate confidentiality provisions

Warning: ITEMS TO REVIEW
- Non-compete clause duration (3 years) - consider if appropriate
- Intellectual property assignment - review job duties
- Dispute resolution method - no arbitration clause specified

Warning: MISSING ITEMS
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

LegalEase values your data privacy and provides comprehensive settings to configure connectivity and manage your personal details.

---

### Accessing Settings
- **Web App**: Click the ** Settings** gear icon in the top right corner of the top bar.
- **Mobile App**: Tap the ** Menu** drawer -> **Settings ()**.

---

### Account & Session Settings

Under the **Account** tab, you can view your display details and take active control over your personal data footprint.

| Feature / Setting | Description | Privacy Action |
| --- | --- | --- |
| **Username** | Display name used in greeting banners. | Can be updated via profile form. |
| **Email** | Primary JWT authentication identifier. | Syncs with your account profile. |
| **Personal Context** | Review the compiled background facts inferred by the AI worker. | Can be overridden or manual text appended. |
| **Delete Personal Context** | Wipes the aggregated User Profile Context collection in MongoDB. | Critical: **Immediate Purge**: All learned AI preferences are deleted instantly. Irreversible. |
| **Clear All Chat History** | Clears the conversations list and removes all chat documents. | Critical: **Wipe History**: Deletes all threads permanently. |
| **Delete Account** | Purges your entire database footprint (profile, context, and files). | Critical: **Purge Profile**: Deletes the account and logged credentials permanently. |

---

### Network Configuration (API Endpoint)

If self-hosting the LegalEase FastAPI backend locally or deploying a custom instance, you can configure your connection base path:
1. Open the Settings modal and locate the **Network Configuration** section.
2. In the API URL field, type your custom base address (e.g. `http://192.168.1.15:8000`).
3. Click **Save Settings**.
4. The application will instantly test connectivity and switch to the new host.

---

### Theme & Layout Controls

- **Dark Theme**: The premium, ultra-dark layout (#131313 with yellow accents) is active by default on Web to reduce optic strain.
- **Font & Text Scaling**: On mobile web viewports, font size automatically scales up to 18px in chat bubbles for enhanced legibility.

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

- Warning: **Not a substitute for real lawyers**
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

- View chat history offline
- Read previous responses
- Compose new messages
- No AI responses require internet
- No Document upload requires internet
- Messages sync when you reconnect

### Q6: How do I delete my account?

**A:**

1. Tap ** Settings** -> **Account**
2. Scroll to bottom
3. Tap **Delete Account**
4. Confirm deletion (irreversible)
5. All data will be permanently removed

### Q7: What file types are supported?

**A:**

- PDF, DOCX, TXT (documents)
- PNG, JPG (images)
- JPEG (photos)
- No XLS, PPT, ZIP (not yet supported)
- No Executable files (for security)

### Q8: How do I report a bug?

**A:**

1. Tap ** Settings** -> **Help**
2. Select **Report Bug**
3. Describe the issue
4. Include screenshots if possible
5. Submit (automatically includes logs)

### Q9: Is there a web version?

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

1. Tap ** Settings** -> **Permissions**
2. Verify **Storage** is enabled
3. Verify **Camera** is enabled (if uploading via camera)

### Slow Performance

**Problem**: "App is slow or laggy"

**Solutions:**

1. Close other apps (free up RAM)
2. Clear app cache:
   - Settings -> Apps -> LegalEase -> Storage -> Clear Cache
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
   - Settings -> Apps -> LegalEase -> Force Stop
   - Reopen app

2. **Clear Cache**:
   - Settings -> Apps -> LegalEase -> Storage -> Clear Cache
   - Reopen app

3. **Reinstall**:
   - Uninstall LegalEase
   - Restart device
   - Reinstall from Play Store

4. **Check Storage**:
   - Ensure at least 100 MB free storage
   - Delete unused apps/files

**Report persistent crashes:**

- Tap ** Settings** -> **Help** -> **Report Bug**

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

- View all your data
- Edit profile information
- Delete chats
- Download your data
- Delete your account

### Privacy Policy

For full details, see [Privacy Policy](../privacy_policy.md)

### Terms of Service

For legal terms, see [Terms & Conditions](../terms_and_conditions.md)

---

## Getting Help

### Support Resources

1. **In-App Help**:
   - Tap ** Settings** -> **Help**
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

1. Tap ** Settings** -> **Feedback**
2. Rate your experience
3. Share suggestions
4. Submit

---

## Tips & Tricks

### Pro Tips

1. **Effective Prompts**: Be specific in your questions
   - "Review this employee termination agreement for potential issues"
   - No "Is this contract okay?"

2. **Organize with Titles**: Give chats descriptive names
   - "Lease Review - Commercial Property"
   - No "Chat 1"

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
