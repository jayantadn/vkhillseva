# vkhillseva
Seva App for ISKCON Vaikuntha Hill

> **Disclaimer:** `main` branch is not maintained anymore. Please go to desired release branches to see the latest changes.

## Apps

| App | Description |
|-----|-------------|
| [vkhgaruda](vkhgaruda/README.md) | Garuda — the main seva management app |
| [vkhsangeetseva](vkhsangeetseva/README.md) | SangeetSeva — the music seva app |

## Pre-requisites
- Flutter SDK (3.6.0 or higher)
- Python 3.x (for build scripts)
- Firebase account with configured project
- Firebase CLI (`firebase`)
- FlutterFire CLI (`flutterfire`)

## Setup

### 1. Clone the Repository
```bash
git clone https://github.com/jayantadn/vkhillseva.git
cd vkhillseva
```

Add the secrets:
1. `google-services.json`
2. `garuda-1ba07-firebase-adminsdk-fbsvc-c07e3d6e0a.json`

Generate Firebase Dart config files (not committed to git):

```bash
# Install CLI tools once (if not already installed)
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Garuda
cd vkhgaruda
flutterfire configure --project=garuda-1ba07 --platforms=android,web --out=lib/firebase_options.dart

# SangeetSeva
cd ../vkhsangeetseva
flutterfire configure --project=garuda-1ba07 --platforms=android,web --out=lib/firebase_options.dart
```

If `flutterfire` is not found, ensure Dart pub global binaries are in your PATH.

### 2. Install Dependencies

```bash
cd vkhgaruda && flutter pub get && cd ..
cd vkhsangeetseva && flutter pub get
```

See each app's README for further setup and build instructions.

## Production Release (Using Release Script)

```bash
# From the root directory
python 02_release.py
```

When prompted:
- Enter `1` for Release build
- Enter `2` for Test build

The release script will:
1. ✓ Update changelog from git commits
2. ✓ Build web and Android versions
3. ✓ Deploy to Firebase Hosting (if configured)

## Security Notes

### Protected Files (Never Commit These):
- ✓ `key.properties` (contains signing keys)
- ✓ `.timetracker` (personal time tracking data)

These files are automatically ignored by `.gitignore`

## License

See [LICENSE](LICENSE) file for details.

