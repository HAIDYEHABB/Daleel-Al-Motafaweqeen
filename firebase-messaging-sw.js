importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDgjlUkEWG0ic1fxT4iIpEvV8rJyr5EKQY",
  authDomain: "daleel-al-motafawqeen.firebaseapp.com",
  projectId: "daleel-al-motafawqeen",
  storageBucket: "daleel-al-motafawqeen.firebasestorage.app",
  messagingSenderId: "405166012261",
  appId: "1:405166012261:web:e9702eba33e786d707938c",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title ?? "دليل المتفوقين";
  const notificationOptions = {
    body: payload.notification?.body ?? "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data: payload.data,
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
