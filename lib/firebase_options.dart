import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDBc8ansI-TteUqtcoIwchLhlnmT8IsZ3w',
    appId: '1:9716153561:web:f6053d21f9db53ed44d2c8',
    messagingSenderId: '9716153561',
    projectId: 'sahayak-ai-47dcb',
    authDomain: 'sahayak-ai-47dcb.firebaseapp.com',
    storageBucket: 'sahayak-ai-47dcb.firebasestorage.app',
    measurementId: 'G-4ER4FRDNXF',
  );

  // ── Paste your Firebase Console values here ──

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDwXXFJU4CFbip4dvST3AMxkUKJJe_o8O4",
    authDomain: "sahayak-ai-47dcb.firebaseapp.com",
    projectId: "sahayak-ai-47dcb",
    storageBucket: "sahayak-ai-47dcb.firebasestorage.app",
    messagingSenderId: "9716153561",
    appId: "1:9716153561:android:2b05a7eb6b21f52144d2c8",
  );
}
