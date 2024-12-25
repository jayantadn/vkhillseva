// Import scripts
importScripts("https://www.gstatic.com/firebasejs/9.21.0/firebase-app.js");
importScripts(
  "https://www.gstatic.com/firebasejs/9.21.0/firebase-messaging.js"
);

// Initialize Firebase
const firebaseConfig = {
  apiKey: "AIzaSyAs9y6fW9qc29_rLg8Uhhgj03WesQsy4U0",
  authDomain: "vkhillseva.firebaseapp.com",
  databaseURL:
    "https://vkhillseva-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "vkhillseva",
  storageBucket: "vkhillseva.firebasestorage.app",
  messagingSenderId: "129760746257",
  appId: "1:129760746257:web:ea4a401bcf3ee82beb8ab0",
  measurementId: "G-KFEN5QXPBM",
};
firebase.initializeApp(firebaseConfig);

// Handle background messages
const messaging = firebase.messaging();
messaging.onBackgroundMessage(function (payload) {
  console.log("Received background message: ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/firebase-logo.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
