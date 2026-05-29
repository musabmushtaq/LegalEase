# LegalEase Mobile App (Flutter)

**Status**: Production Ready | Android App | Fully Featured

This folder contains the mobile application (Flutter) for LegalEase - an AI-powered legal assistant with chat, document analysis, and offline support.

## Purpose

The Flutter mobile app provides full LegalEase functionality with:

- Intuitive chat interface for legal Q&A
- Document upload and analysis (PDF, DOCX, TXT, images)
- Chat history and organization
- Offline support for viewing history
- Real-time AI responses
- File management
- User authentication
- Settings and preferences
- Live call functionality (with VAD, transcription, TTS, user interruption)
- Connectivity awareness

## Features

### Core Features

- **Chat Interface**: Multi-turn conversations with AI legal assistant
- **Document Analysis**: Upload and analyze legal documents
- **Chat Management**: Create, organize, pin, and archive chats
- **File Storage**: Store documents securely on device and backend
- **User Accounts**: Secure authentication and user profiles
- **Settings**: Customize preferences and appearance

### UI Components

- **Chat Screen**: Main interface with message bubbles
- **Login/Signup**: User authentication screens
- **Settings Screen**: User preferences and configuration
- **Live Call Screen**: Real-time voice interaction with AI, VAD-based detection, automatic transcription, and interruption handling
- **Chat Drawer**: Sidebar navigation for chat history
- **Message Bubbles**: User and AI message display
- **Thinking Indicator**: AI processing animation
- **Connectivity Banner**: Network status indicator

### Technology Stack

| Component  | Technology        | Purpose                    |
| ---------- | ----------------- | -------------------------- |
| Framework  | Flutter (stable)  | Cross-platform development |
| Language   | Dart 3.0+         | App logic and UI           |
| State Mgmt | Provider          | State management           |
| UI         | Material Design   | User interface             |
| Storage    | SharedPreferences | Local data cache           |
| Networking | HTTP/Dio          | API communication          |
| AI Model   | Silero VAD        | Voice activity detection   |

## Project Structure

```
app/
|--─ lib/
|   |--─ main.dart                    # Application entry point
|   |
|   |--─ models/                      # Data models
|   |   |--─ user.dart               # User model
|   |   |--─ chat.dart               # Chat model
|   |   +--─ message.dart            # Message model
|   |
|   |--─ screens/                     # UI screens
|   |   |--─ chat_screen.dart        # Main chat interface
|   |   |--─ login_screen.dart       # User login
|   |   |--─ signup_screen.dart      # User registration
|   |   |--─ settings_screen.dart    # Settings
|   |   +--─ live_call_screen.dart   # Live calls
|   |
|   |--─ services/
|   |   +--─ chat_service.dart       # Business logic & API
|   |
|   |--─ theme/
|   |   +--─ app_theme.dart          # Dark theme configuration
|   |
|   +--─ widgets/                     # Reusable UI components
|       |--─ chat_drawer.dart        # Chat history sidebar
|       |--─ message_bubble.dart     # Message UI
|       |--─ thinking_indicator.dart # Loading animation
|       +--─ connectivity_banner.dart # Network status
|
|--─ assets/
|   +--─ models/
|       +--─ silero_vad_legacy.onnx  # Voice detection model
|
|--─ android/                         # Android native code
|   |--─ app/
|   |   +--─ build.gradle.kts        # Android build config
|   +--─ build.gradle.kts            # Gradle settings
|
|--─ pubspec.yaml                     # Dependencies
+--─ README.md # This file
```

## Prerequisites

- **Flutter SDK**: Version 3.0+ (stable channel)
  ```bash
  flutter --version
  ```
- **Android SDK**: Android 8.0 or higher
  ```bash
  flutter doctor
  ```
- **Java Development Kit**: JDK 11+
- **API Server**: Running on localhost:8000 or custom endpoint

## Local Development

### Setup

1. **Install Flutter**:

   ```bash
   # Download from flutter.dev
   # Add to PATH
   flutter pub get
   ```

2. **Get Dependencies**:

   ```bash
   cd app
   flutter pub get
   ```

3. **Verify Setup**:
   ```bash
   flutter doctor
   ```

### Running the App

**Android Emulator**:

```bash
cd app
flutter run
```

**Android Emulator with Custom API**:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Physical Device (same network)**:

```bash
# Get your machine's IP
ipconfig

# Find IPv4 Address (e.g., 192.168.100.62)
flutter run --dart-define=API_BASE_URL=http://192.168.100.62:8000
```

**Physical Device (over USB)**:

```bash
flutter run
```

## Configuration

### API Endpoint

**Default**: `http://127.0.0.1:8000`

**Override at runtime** with Dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://your-server-ip:8000
```

**Environment-specific**:

- **Development**: `http://127.0.0.1:8000` (localhost)
- **Emulator**: `http://10.0.2.2:8000` (special Android emulator IP)
- **Physical Device**: `http://192.168.x.x:8000` (LAN IP)
- **Production**: `https://api.legalease.com`

### Make sure the API is running first:

```bash
cd api
# Activate virtual environment
.venv\Scripts\activate

# Start API server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Building

### Android APK

**Development Build** (debug):

```bash
cd app
flutter build apk
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

**Release Build** (optimized):

```bash
cd app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Size info**:

- Debug APK: ~200 MB (includes symbols)
- Release APK: ~50 MB (optimized)

### App Signing (for Play Store)

1. **Create keystore**:

   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```

2. **Configure signing** in `android/app/build.gradle.kts`

3. **Build signed APK**:
   ```bash
   flutter build apk --release
   ```

## Design System

### Colors

- **Primary**: #131313 (Deep Black)
- **Accent**: #FCE566 (Golden Yellow)
- **Text**: White/Light Gray
- **Background**: #1A1A1A

### Typography

- **Display**: System fonts (Roboto on Android)
- **Body**: Consistent sizing
- **Emphasis**: Accent color (#FCE566)

### Responsive Design

- **Mobile**: 360px - 599px
- **Tablet**: 600px+
- **Layouts**: Adaptive based on screen size

## Testing

### Run Tests

```bash
cd app
flutter test
```

### Unit Tests

```dart
// test/chat_service_test.dart
void main() {
  test('Chat creation test', () {
    // Test logic
  });
}
```

### Widget Tests

```dart
void main() {
  testWidgets('Message renders correctly', (tester) async {
    await tester.pumpWidget(const LegalEaseApp());
    expect(find.byType(MessageBubble), findsWidgets);
  });
}
```

## Debugging

### Verbose Output

```bash
flutter run -v
```

### Connect DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Check Device Logs

```bash
flutter logs
```

### Force Stop & Clear

```bash
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

### API Connection Issues

**Error**: "Cannot connect to API"

**Solutions**:

1. Verify API is running: `curl http://127.0.0.1:8000/health`
2. Check API_BASE_URL is correct
3. Verify firewall allows connections
4. Try different network (WiFi vs mobile)

### Build Issues

**Error**: "Build failed"

**Solutions**:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Check Android SDK installation
4. Run `flutter doctor` to diagnose

### Performance Issues

**Sluggish app**:

1. Close other apps
2. Rebuild in release mode
3. Check device storage
4. Update dependencies

## Dependencies

Main packages:

- **provider**: State management
- **http**: API communication
- **google_generative_ai**: AI integration
- **image_picker**: File uploads
- **permission_handler**: System permissions
- **connectivity_plus**: Network detection
- **record_android**: Audio recording
- **audioplayers_android**: Audio playback

## Features & Status

| Feature         | Status         | Notes                                                                       |
| --------------- | -------------- | --------------------------------------------------------------------------- |
| Chat Interface  |  Complete    | Full messaging                                                              |
| Document Upload |  Complete    | PDF, DOCX, images                                                           |
| Chat History    |  Complete    | Persistent storage                                                          |
| User Auth       |  Complete    | Login/Signup                                                                |
| Dark Theme      |  Complete    | Full dark mode                                                              |
| Offline Mode    |  Complete    | View history offline                                                        |
| Voice Input     |  Complete    | Continuous VAD audio capture and GPU Whisper transcriptions                 |
| Live Calls      |  Complete    | Full voice interaction with VAD, transcription, TTS, interruption detection |
| AI Analysis     |  Complete    | Integration ready                                                           |

## Performance

- **App Size**: ~50 MB (release)
- **Startup Time**: <2 seconds
- **Memory Usage**: ~100 MB typical
- **Battery**: Optimized for background use

## Contributing

See [CONTRIBUTING.md](../docs/contributing.md) for guidelines.

## Documentation

For more information:

- [System Architecture](../docs/SYSTEM_ARCHITECTURE.md)
- [API Documentation](../docs/API_DOCUMENTATION.md)
- [User Manual](../docs/USER_MANUAL.md)
- [Developer Guide](../docs/DEVELOPER_GUIDE.md)
