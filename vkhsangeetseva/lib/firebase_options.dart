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
    apiKey: 'AIzaSyBkdNjHCo7gahfjEJRcGz64EQwsIkQYkFY',
    appId: '1:129760746257:web:46f4e6fa1a22ce7deb8ab0',
    messagingSenderId: '129760746257',
    projectId: 'vkhillseva',
    authDomain: 'vkhillseva.firebaseapp.com',
    databaseURL: 'https://vkhillseva-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'vkhillseva.firebasestorage.app',
    measurementId: 'G-QVKKNHS8ZS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcKPvG97ruORaBB0Qc8sVe4et9mjxe_V4',
    appId: '1:129760746257:android:4f5e903a18ad2886eb8ab0',
    messagingSenderId: '129760746257',
    projectId: 'vkhillseva',
    databaseURL: 'https://vkhillseva-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'vkhillseva.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_IOS_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MACOS_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  // Add configurations for other platforms if needed
}