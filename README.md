# vkhillseva
Seva App for ISKCON Vaikuntha Hill

# How to Build

## Pre-requisites
- Flutter SDK (3.6.0 or higher)
- Python 3.x (for build scripts)
- Firebase account with configured project

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/jayantadn/vkhillseva.git
cd vkhillseva
```

### 2. Configure Environment Variables

#### For vkhgaruda:
```bash
cd vkhgaruda
cp .env.example .env
```

#### For vkhsangeetseva:
```bash
cd vkhsangeetseva
cp .env.example .env
```

Edit the `.env` file in each project folder with your Firebase credentials:
```plaintext
# Firebase Web Configuration
FIREBASE_WEB_API_KEY=your_web_api_key_here
FIREBASE_WEB_APP_ID=your_web_app_id_here
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_AUTH_DOMAIN=your_auth_domain
FIREBASE_DATABASE_URL=your_database_url
FIREBASE_STORAGE_BUCKET=your_storage_bucket
FIREBASE_MEASUREMENT_ID=your_measurement_id

# Firebase Android Configuration
FIREBASE_ANDROID_API_KEY=your_android_api_key_here
FIREBASE_ANDROID_APP_ID=your_android_app_id_here
```

**Where to find these values:**
- Go to Firebase Console → Project Settings → Your Apps
- Copy the values from your Firebase Web and Android app configurations

### 3. Install Dependencies

#### For vkhgaruda:
```bash
cd vkhgaruda
flutter pub get
```

#### For vkhsangeetseva:
```bash
cd vkhsangeetseva
flutter pub get
```

### 4. Configure Android Signing (for Release Builds)

Create `key.properties` file in `vkhgaruda/android/` directory:
```
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

**Note:** This file is already excluded from git via `.gitignore`

### 5. Generate Firebase Service Worker (for Web)

The `firebase-messaging-sw.js` file is automatically generated during the release process.
For manual generation:

```bash
# From the root directory
python generate_firebase_sw.py vkhgaruda
# or
python generate_firebase_sw.py vkhsangeetseva
```

## Build Steps

### Local Development/Testing

```bash
# For vkhgaruda
cd vkhgaruda
flutter run

# For vkhsangeetseva
cd vkhsangeetseva
flutter run
```

The app will automatically load configuration from your `.env` file.

### Production Release (Using Release Script)

```bash
# From the root directory
python 02_release.py
```

When prompted:
- Enter `1` for Release build
- Enter `2` for Test build

The release script will:
1. ✓ Generate `firebase-messaging-sw.js` from your `.env` file
2. ✓ Update changelog from git commits
3. ✓ Build web and Android versions
4. ✓ Deploy to Firebase Hosting (if configured)

### Manual Build Commands

#### Web Build:
```bash
cd vkhgaruda  # or vkhsangeetseva
flutter build web
```

#### Android APK:
```bash
cd vkhgaruda  # or vkhsangeetseva
flutter build apk --release
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

## Security Notes

### Protected Files (Never Commit These):
- ✓ `.env` files (contain Firebase credentials)
- ✓ `key.properties` (contains signing keys)
- ✓ `firebase-messaging-sw.js` (auto-generated from .env)
- ✓ `.timetracker` (personal time tracking data)

These files are automatically ignored by `.gitignore`

### Safe to Commit:
- ✓ `.env.example` (template with placeholder values)
- ✓ `generate_firebase_sw.py` (build script)
- ✓ All source code files

### Before Making Repository Public:
1. ✓ Ensure `.env` files are not committed
2. ✓ Verify Firebase Security Rules are properly configured
3. ✓ Add API restrictions in Google Cloud Console
4. ✓ Review all committed files for sensitive data
5. ✓ Enable Firebase App Check for additional security

## Project Structure

```
vkhillseva/
├── vkhgaruda/              # Main Garuda seva app
│   ├── .env               # Firebase config (not in git)
│   ├── .env.example       # Template for contributors
│   └── lib/
│       ├── main.dart      # Entry point (loads .env)
│       └── firebase_options.dart  # Reads from .env
├── vkhsangeetseva/        # Sangeet seva app
│   ├── .env               # Firebase config (not in git)
│   └── .env.example       # Template for contributors
├── vkhpackages/           # Shared packages
├── generate_firebase_sw.py  # Generates web service worker
├── 02_release.py          # Release automation script
└── README.md             # This file
```

## Troubleshooting

### "Error loading .env file"
- Ensure `.env` file exists in the app directory
- Check that all required variables are defined
- Verify `.env` is listed in `pubspec.yaml` assets

### "Firebase initialization failed"
- Verify credentials in `.env` are correct
- Check internet connection
- Ensure Firebase project is active

### Web build missing firebase-messaging-sw.js
- Run: `python generate_firebase_sw.py vkhgaruda`
- Or use the release script which auto-generates it

### Local testing not working after changes
- The `.env` file is loaded at app startup
- Local development works seamlessly - just run `flutter run`
- The app automatically reads from `.env` each time it starts
- No special configuration needed for local testing

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

## Contributing

1. Fork the repository
2. Create `.env` from `.env.example` with your Firebase credentials
3. Make your changes
4. Test locally with `flutter run`
5. Ensure you don't commit `.env` files
6. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.
