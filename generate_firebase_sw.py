"""
Generate firebase-messaging-sw.js from .env file
This script reads Firebase configuration from .env and generates the service worker file
"""
import os
import sys
from pathlib import Path


def load_env_file(env_path):
    """Load environment variables from .env file"""
    env_vars = {}
    try:
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
    except FileNotFoundError:
        print(f"Error: .env file not found at {env_path}")
        sys.exit(1)
    return env_vars


def generate_service_worker(env_vars, output_path):
    """Generate firebase-messaging-sw.js file"""
    template = '''// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

firebase.initializeApp({{
    apiKey: "{api_key}",
    authDomain: "{auth_domain}",
    databaseURL: "{database_url}",
    projectId: "{project_id}",
    storageBucket: "{storage_bucket}",
    messagingSenderId: "{messaging_sender_id}",
    appId: "{app_id}",
    measurementId: "{measurement_id}"
}});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {{
  console.log("onBackgroundMessage", message);
}});
'''

    content = template.format(
        api_key=env_vars.get('FIREBASE_WEB_API_KEY', ''),
        auth_domain=env_vars.get('FIREBASE_AUTH_DOMAIN', ''),
        database_url=env_vars.get('FIREBASE_DATABASE_URL', ''),
        project_id=env_vars.get('FIREBASE_PROJECT_ID', ''),
        storage_bucket=env_vars.get('FIREBASE_STORAGE_BUCKET', ''),
        messaging_sender_id=env_vars.get('FIREBASE_MESSAGING_SENDER_ID', ''),
        app_id=env_vars.get('FIREBASE_WEB_APP_ID', ''),
        measurement_id=env_vars.get('FIREBASE_MEASUREMENT_ID', '')
    )

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(content)
    print(f"Generated: {output_path}")


def main():
    if len(sys.argv) > 1:
        app_name = sys.argv[1]
    else:
        print("Usage: python generate_firebase_sw.py <app_name>")
        print("Example: python generate_firebase_sw.py vkhgaruda")
        sys.exit(1)

    # Get the root directory
    root_dir = Path(__file__).parent
    app_dir = root_dir / app_name

    # Load .env file
    env_path = app_dir / '.env'
    env_vars = load_env_file(env_path)

    # Generate service worker
    output_path = app_dir / 'web' / 'firebase-messaging-sw.js'
    generate_service_worker(env_vars, output_path)

    print(f"✓ Successfully generated firebase-messaging-sw.js for {app_name}")


if __name__ == '__main__':
    main()
