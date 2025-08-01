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
    apiKey: 'AIzaSyA_RYw4ZaQs8GD_wJs_bGsNJPjpkKyL4yU',
    appId: '1:683499127522:web:97e1618cef14c36dc014bb',
    messagingSenderId: '683499127522',
    projectId: 'garuda-1ba07',
    authDomain: 'garuda-1ba07.firebaseapp.com',
    databaseURL: 'https://garuda-1ba07-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'garuda-1ba07.firebasestorage.app',
    measurementId: 'G-32PHS5XD9Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCI14SfgeCZEqo8LOVbTh8fxhNz4KZRk64',
    appId: '1:683499127522:android:ce092310e0b9ed01c014bb',
    messagingSenderId: '683499127522',
    projectId: 'garuda-1ba07',
    databaseURL: 'https://garuda-1ba07-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'garuda-1ba07.firebasestorage.app',
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