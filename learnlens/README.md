# Learn Lens Flutter App

Mobile-first Flutter application for the Learn Lens AI learning platform.

## Setup

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Configure Firebase:**
```bash
# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

3. **Update API URL:**
Edit `lib/core/config.dart` and update `baseUrl` with your backend URL.

4. **Run the app:**
```bash
flutter run
```

## Project Structure

```
lib/
├── core/           # Configuration and API client
├── models/         # Data models
├── bloc/           # State management (BLoC)
├── screens/        # UI screens
└── main.dart       # App entry point
```

## Features

- Firebase Authentication
- Document upload (PDF/DOCX/TXT)
- Question generation and answering
- Performance analytics
- Mobile-first design

## Dependencies

- **flutter_bloc**: State management
- **dio**: HTTP client
- **firebase_auth**: Authentication
- **file_picker**: Document selection

## API Integration

The app communicates with the FastAPI backend via REST API. All API calls are handled through the `ApiClient` class in `lib/core/api_client.dart`.

## Building

```bash
# Android
flutter build apk

# iOS
flutter build ios
```
