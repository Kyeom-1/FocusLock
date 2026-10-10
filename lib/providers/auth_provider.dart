import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _loading = false;
  String? _errorMessage;

  // Set when Google sign-in found an existing email/password account with the
  // same address; cleared once the accounts are linked or the user cancels.
  AuthCredential? _pendingGoogleCredential;
  String? _pendingLinkEmail;

  AuthProvider(this._authService) {
    _user = _authService.currentUser;
    _sub = _authService.authStateChanges.listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get uid => _user?.uid;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  bool get hasPendingGoogleLink => _pendingGoogleCredential != null;
  String? get pendingLinkEmail => _pendingLinkEmail;

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on GoogleLinkRequired catch (e) {
      _pendingGoogleCredential = e.credential;
      _pendingLinkEmail = e.email;
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e);
      return false;
    } on PlatformException catch (e) {
      debugPrint('Auth platform error: ${e.code} | ${e.message}');
      _errorMessage = _mapPlatformError(e);
      return false;
    } catch (e, st) {
      // Log the real error instead of hiding it; show it on screen in debug.
      debugPrint('Auth error: $e\n$st');
      _errorMessage = kDebugMode
          ? 'Something went wrong: $e'
          : 'Something went wrong. Please try again.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _authService.signInWithEmail(email.trim(), password));

  Future<bool> signUp(String email, String password) =>
      _run(() => _authService.signUpWithEmail(email.trim(), password));

  Future<bool> signInWithGoogle() {
    _pendingGoogleCredential = null;
    _pendingLinkEmail = null;
    return _run(() => _authService.signInWithGoogle());
  }

  /// Finishes a pending Google sign-in by proving ownership of the existing
  /// email/password account, then linking Google to it.
  Future<bool> completeGoogleLink(String password) {
    final credential = _pendingGoogleCredential;
    final email = _pendingLinkEmail;
    if (credential == null || email == null) return Future.value(false);
    return _run(() async {
      await _authService.linkGoogleToEmailAccount(
        email: email,
        password: password,
        googleCredential: credential,
      );
      _pendingGoogleCredential = null;
      _pendingLinkEmail = null;
    });
  }

  void cancelGoogleLink() {
    _pendingGoogleCredential = null;
    _pendingLinkEmail = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) =>
      _run(() => _authService.sendPasswordReset(email.trim()));

  Future<void> signOut() => _authService.signOut();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapPlatformError(PlatformException e) {
    final msg = e.message ?? '';
    if (msg.contains('ApiException: 10')) {
      return 'Google sign-in is not set up for this build. Add this app\u2019s '
          'SHA-1 fingerprint in Firebase, then re-download google-services.json.';
    }
    if (msg.contains('ApiException: 12500')) {
      return 'Google sign-in is misconfigured (check the OAuth consent '
          'screen / support email in Firebase).';
    }
    if (e.code == 'network_error' || msg.contains('ApiException: 7')) {
      return 'Network error. Check your connection and try again.';
    }
    if (e.code == 'sign_in_canceled') return 'Google sign-in was cancelled.';
    return kDebugMode
        ? 'Google sign-in failed (${e.code}): $msg'
        : 'Google sign-in failed. Please try again.';
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Please choose a stronger password (6+ characters).';
      case 'credential-already-in-use':
        return 'That Google account is already linked to a different FocusLock account.';
      case 'account-exists-with-different-credential':
        return 'An account with that email already exists. Sign in with your password first.';
      case 'sign-in-cancelled':
        return 'Google sign-in was cancelled.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
