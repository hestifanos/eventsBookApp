# Campus Events

A Flutter app for browsing and managing campus events, with Firebase-backed event data and media, map views, and scheduled event reminders.

## Requirements

- Flutter SDK (the version constraint is in `pubspec.yaml`)
- A Firebase project configured for the platforms you want to run
- Android Studio or Xcode for device/emulator builds

## Setup and run

```bash
flutter pub get
flutter test
flutter run
```

Review the Firebase configuration in `lib/firebase_options.dart` and the platform-specific Firebase setup before using a different Firebase project. Never add service-account keys or privileged credentials to the app.

## Project structure

```text
lib/models/       Event and user models
lib/screens/      Event, detail, and map screens
lib/services/     Authentication, event storage, and reminders
lib/widgets/      Reusable event UI
```

Firebase Auth, Firestore, and Storage rules should be configured and tested for the intended users before deployment.
