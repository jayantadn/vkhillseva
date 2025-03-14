// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyA_RYw4ZaQs8GD_wJs_bGsNJPjpkKyL4yU",
    authDomain: "garuda-1ba07.firebaseapp.com",
    databaseURL: "https://garuda-1ba07-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "garuda-1ba07",
    storageBucket: "garuda-1ba07.firebasestorage.app",
    messagingSenderId: "683499127522",
    appId: "1:683499127522:web:97e1618cef14c36dc014bb",
    measurementId: "G-32PHS5XD9Z"
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});
