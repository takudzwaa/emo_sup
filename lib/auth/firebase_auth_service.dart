import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

/// Production auth via Firebase Auth — phone OTP or email/password only.
/// No Google / Facebook / Apple (those leak real identity signals).
///
/// Requires `Firebase.initializeApp` + platform config
/// (`flutterfire configure`). Until then, [createAuthService] uses
/// [PrototypeAuthService].
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      try {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return cred.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          final cred = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          final user = cred.user!;
          // Best-effort: raises the bar on throwaway spam signups without
          // blocking onboarding if sending happens to fail.
          unawaited(user.sendEmailVerification().catchError((_) {}));
          return user.uid;
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e));
    }
  }

  @override
  Future<PhoneVerificationStarted> startPhoneVerification({
    required String phoneNumber,
  }) async {
    final completer = Completer<PhoneVerificationStarted>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval on some Android devices — complete sign-in.
          try {
            final cred = await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(
                PhoneVerificationStarted(
                  verificationId: 'auto_${cred.user?.uid ?? ''}',
                ),
              );
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(
                AuthException('Could not verify phone automatically.'),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(AuthException(_mapFirebaseCode(e)));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationStarted(
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationStarted(verificationId: verificationId),
            );
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e));
    }

    return completer.future.timeout(
      const Duration(seconds: 70),
      onTimeout: () => throw AuthException(
        'Timed out waiting for a verification code. Try again.',
      ),
    );
  }

  @override
  Future<String> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId.startsWith('auto_')) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) return uid;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final cred = await _auth.signInWithCredential(credential);
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _mapFirebaseCode(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address does not look valid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'email-already-in-use':
        return 'That email is already registered. Try signing in.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'invalid-phone-number':
        return 'Enter a valid phone number with country code.';
      case 'invalid-verification-code':
        return 'That code is incorrect. Try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
