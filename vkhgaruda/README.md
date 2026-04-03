# vkhgaruda — Garuda App

Garuda is the main seva management app for ISKCON Vaikuntha Hill.

See the [root README](../README.md) for project-wide pre-requisites and setup.

## Setup

### 1. Install Dependencies

```bash
cd vkhgaruda
flutter pub get
```

### 2. Configure Android Signing (for Release Builds)

Create `key.properties` in `vkhgaruda/android/`:

```
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

**Note:** This file is already excluded from git via `.gitignore`

### 3. Update google-services.json

Download `google-services.json` from the Firebase console into `vkhgaruda/android/app/`.

### 4. Generate lib/firebase_options.dart (Required)

`lib/firebase_options.dart` is intentionally not committed. Generate it before running or building:

```bash
cd vkhgaruda
flutterfire configure --project=garuda-1ba07 --platforms=android,web --out=lib/firebase_options.dart
```

If needed, install tools first:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

## Build

### Local Development / Testing

```bash
cd vkhgaruda
flutter run
```

### Web Build

```bash
cd vkhgaruda
flutter build web
```

### Android APK

```bash
cd vkhgaruda
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Firebase Security Checklist

Before going public, ensure:
- [ ] Firebase Realtime Database Rules are configured (not in public read/write mode)
- [ ] Firebase Storage Rules are configured
- [ ] Firebase Authentication is properly set up
- [ ] API keys are restricted in Google Cloud Console:
  - [ ] Add your website domain to allowed domains
  - [ ] Add your Android app SHA-1 fingerprint
- [ ] Enable Firebase App Check for web and mobile
- [ ] Review all Firebase project IAM permissions
