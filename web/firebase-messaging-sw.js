importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCJu9pRhFqDoaCmIFc6JCOYuy6CalEyc3Q",
  appId: "1:31612694618:web:f5401978d2bc4be262e863",
  messagingSenderId: "31612694618",
  projectId: "devmob-apvpedagogie",
  authDomain: "devmob-apvpedagogie.firebaseapp.com",
  storageBucket: "devmob-apvpedagogie.firebasestorage.app",
  measurementId: "G-4JBYWNRX0M",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  console.log("Background message received:", message);
});
