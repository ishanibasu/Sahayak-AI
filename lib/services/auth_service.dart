import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    await _db.collection('users').doc(cred.user!.uid).set({
      'displayName': displayName,
      'email': email,
      'isVerifiedResponder': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  // ── Google Sign-In ─────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    late UserCredential cred;

    if (kIsWeb) {
      // ✅ Web: Firebase popup — google_sign_in not used at all
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      cred = await _auth.signInWithPopup(provider);
    } else {
      // ✅ Mobile: google_sign_in v7 flow
      final googleUser = await GoogleSignIn.instance.authenticate();
      final authClient = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);
      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: authClient.accessToken,
      );
      cred = await _auth.signInWithCredential(credential);
    }

    // Create Firestore doc on first login
    final docRef = _db.collection('users').doc(cred.user!.uid);
    if (!(await docRef.get()).exists) {
      await docRef.set({
        'displayName': cred.user!.displayName ?? '',
        'email': cred.user!.email ?? '',
        'photoURL': cred.user!.photoURL ?? '',
        'isVerifiedResponder': false,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': 'google',
      });
    }

    return cred;
  }

  Future<void> signOut() async {
    if (!kIsWeb) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
