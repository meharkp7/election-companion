import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In + Firebase Auth integration.
///
/// Provides a one-tap sign-in flow that:
/// 1. Opens the Google account picker
/// 2. Exchanges the Google ID token for a Firebase credential
/// 3. Signs the user into Firebase Auth
///
/// Usage:
/// ```dart
/// final user = await GoogleAuthService.instance.signIn();
/// if (user != null) { /* proceed */ }
/// ```
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google. Returns the Firebase [User] on success, null on cancel.
  Future<User?> signIn() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      if (kDebugMode) debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out from both Google and Firebase.
  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      FirebaseAuth.instance.signOut(),
    ]);
  }

  /// Returns true if a Google account is currently signed in.
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  /// The currently signed-in Google account, or null.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
