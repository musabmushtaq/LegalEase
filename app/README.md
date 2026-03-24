# app/

This folder contains the mobile application (Flutter) for LegalEase.

Purpose

- Mobile client for chat, file upload, and local document management.

Prerequisites

- Flutter SDK (stable)
- Android SDK (for Android builds)

Local development

```bash
cd app
flutter pub get
flutter run
```

Run with local API

- The app reads `API_BASE_URL` via Dart define.
- Default (no define): `http://127.0.0.1:8000`
- Android emulator: use `http://10.0.2.2:8000`
- Physical phone on same Wi-Fi: use your machine LAN IP (current Wi-Fi IPv4: `192.168.100.62`)

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Physical device on same network
flutter run --dart-define=API_BASE_URL=http://192.168.100.62:8000
```

Make sure the API is running first:

```bash
cd api
C:/source/Python312/python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --app-dir c:\repo\LegalEase\api
```

Build (Android)

```bash
cd app
flutter build apk
# The artifact will be at build/app/outputs/flutter-apk/app-release.apk
```

Notes

- See `../docs/deployment.md` and `../api/README.md` for guidance about API endpoints and secret management.
- The app should store user data locally when possible; AI calls should be proxied through the backend (`api/`) where API keys are kept secure.
- Add a more detailed `app/README.md` content when app features are implemented (screens, modules, key dependencies).
