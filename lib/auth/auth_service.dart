import '../models/user_profile.dart';

/// Result of starting phone verification (SMS sent or prototype mock).
class PhoneVerificationStarted {
  const PhoneVerificationStarted({
    required this.verificationId,
    this.resendToken,
  });

  final String verificationId;
  final int? resendToken;
}

/// Auth boundary: Firebase Auth in production; prototype for local/tests.
///
/// Credential values (email/phone) live only in Firebase Auth — never on
/// [UserProfile].
abstract class AuthService {
  /// Signed-in Firebase (or prototype) uid, if any.
  String? get currentUid;

  /// Email + password create-or-sign-in via Firebase Auth.
  Future<String> signInWithEmail({
    required String email,
    required String password,
  });

  /// Start phone verification. Returns a verificationId for [confirmPhoneCode].
  Future<PhoneVerificationStarted> startPhoneVerification({
    required String phoneNumber,
  });

  /// Complete phone sign-in with the SMS (or prototype) code.
  Future<String> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}

/// In-memory auth for prototype / widget tests (no Firebase project required).
///
/// Mirrors the same method surface as [FirebaseAuthService] so screens
/// stay Firebase-shaped. Swap via [createAuthService].
class PrototypeAuthService implements AuthService {
  String? _uid;

  /// Any 6-digit code works in prototype; documented in UI helper text.
  static const prototypeOtpHint = '123456';

  @override
  String? get currentUid => _uid;

  @override
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw AuthException('Enter a valid email address.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _uid = 'proto_email_${trimmed.hashCode.abs()}';
    return _uid!;
  }

  @override
  Future<PhoneVerificationStarted> startPhoneVerification({
    required String phoneNumber,
  }) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.replaceAll('+', '').length < 8) {
      throw AuthException('Enter a valid phone number with country code.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return PhoneVerificationStarted(
      verificationId: 'proto_verify_${digits.hashCode.abs()}',
    );
  }

  @override
  Future<String> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    if (smsCode.trim().length < 6) {
      throw AuthException('Enter the 6-digit code from your messages.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _uid = 'proto_phone_${verificationId.hashCode.abs()}';
    return _uid!;
  }

  @override
  Future<void> signOut() async {
    _uid = null;
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Session state after credential auth, before profile is finalized.
class PendingAuthSession {
  const PendingAuthSession({
    required this.uid,
    required this.authMethod,
  });

  final String uid;
  final AuthMethod authMethod;
}
