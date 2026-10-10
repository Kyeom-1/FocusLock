import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown by [AuthService.signInWithGoogle] when an account with the same
/// email already exists under a different sign-in method (e.g. the user
/// registered with email + password). The UI should ask for that account's
/// password and call [AuthService.linkGoogleToEmailAccount] so both methods
/// open the same account.
class GoogleLinkRequired implements Exception {
  final String email;
  final AuthCredential credential;
  const GoogleLinkRequired(this.email, this.credential);
}

/// Thin wrapper around FirebaseAuth + Google Sign-In.
///
/// Web uses FirebaseAuth's built-in signInWithPopup (no extra client-id
/// config needed). Mobile/desktop use the google_sign_in plugin, which
/// requires the app's SHA-1 fingerprint to be registered with the Firebase
/// project and Google to be enabled as a sign-in provider in the Firebase
/// console (see SETUP.md).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential' &&
            e.email != null &&
            e.credential != null) {
          throw GoogleLinkRequired(e.email!, e.credential!);
        }
        rethrow;
      }
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the picker.
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw GoogleLinkRequired(e.email ?? googleUser.email, credential);
      }
      rethrow;
    }
  }

  /// Signs in to the existing email/password account, then attaches the
  /// pending Google credential to it. Afterwards either method signs in to
  /// the same account (same uid, same tasks).
  Future<UserCredential> linkGoogleToEmailAccount({
    required String email,
    required String password,
    required AuthCredential googleCredential,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    try {
      await result.user!.linkWithCredential(googleCredential);
    } on FirebaseAuthException catch (e) {
      // Already linked is fine - the goal state is reached.
      if (e.code != 'provider-already-linked') rethrow;
    }
    return result;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}
