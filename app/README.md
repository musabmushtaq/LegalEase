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
