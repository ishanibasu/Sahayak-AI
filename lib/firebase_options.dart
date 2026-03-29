import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Paste your Firebase Console values here ──
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyD2ow-Cc0YOWgn6Og2JzaCm9_yisn1p-IY",
    authDomain: "sahayak-ai-47dcb.firebaseapp.com",
    projectId: "sahayak-ai-47dcb",
    storageBucket: "sahayak-ai-47dcb.firebasestorage.app",
    messagingSenderId: "9716153561",
    appId: "1:9716153561:web:bebeeb209827bce044d2c8",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyD2ow-Cc0YOWgn6Og2JzaCm9_yisn1p-IY",
    authDomain: "sahayak-ai-47dcb.firebaseapp.com",
    projectId: "sahayak-ai-47dcb",
    storageBucket: "sahayak-ai-47dcb.firebasestorage.app",
    messagingSenderId: "9716153561",
    appId: "1:9716153561:web:bebeeb209827bce044d2c8",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyD2ow-Cc0YOWgn6Og2JzaCm9_yisn1p-IY",
    authDomain: "sahayak-ai-47dcb.firebaseapp.com",
    projectId: "sahayak-ai-47dcb",
    storageBucket: "sahayak-ai-47dcb.firebasestorage.app",
    messagingSenderId: "9716153561",
    appId: "1:9716153561:web:bebeeb209827bce044d2c8",
    iosBundleId: 'com.example.myApp',
  );
}