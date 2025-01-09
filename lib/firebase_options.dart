// firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAs9y6fW9qc29_rLg8Uhhgj03WesQsy4U0',
    appId: '1:129760746257:web:ea4a401bcf3ee82beb8ab0',
    messagingSenderId: '129760746257',
    projectId: 'vkhgaruda',
    authDomain: 'vkhgaruda.firebaseapp.com',
    databaseURL:
        'https://vkhgaruda-default-rtdb.asia-southeast1.firebasedatabase.app/',
    storageBucket: 'vkhgaruda.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAs9y6fW9qc29_rLg8Uhhgj03WesQsy4U0',
    appId: '1:129760746257:web:ea4a401bcf3ee82beb8ab0',
    messagingSenderId: '129760746257',
    projectId: 'vkhgaruda',
    authDomain: 'vkhgaruda.firebaseapp.com',
    databaseURL:
        'https://vkhgaruda-default-rtdb.asia-southeast1.firebasedatabase.app/',
    storageBucket: 'vkhgaruda.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_IOS_MESSAGING_SENDER_ID',
    projectId: 'YOUR_IOS_PROJECT_ID',
    storageBucket: 'YOUR_IOS_STORAGE_BUCKET',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MACOS_MESSAGING_SENDER_ID',
    projectId: 'YOUR_MACOS_PROJECT_ID',
    storageBucket: 'YOUR_MACOS_STORAGE_BUCKET',
  );

  // Add configurations for other platforms if needed
}
