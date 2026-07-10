import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import 'anonymous_name_generator.dart';
import 'auth_service.dart';

/// Orchestrates onboarding: credentials → display name → consent → Home.
///
/// Profile is held in memory for the prototype. Later:
/// ```
/// users/{uid}  // UserProfile.toMap()
/// ```
class AuthController extends ChangeNotifier {
  AuthController({
    required this.authService,
    AnonymousNameGenerator? nameGenerator,
    UserProfile? initialProfile,
  })  : _nameGenerator = nameGenerator ?? AnonymousNameGenerator(),
        _profile = initialProfile;

  /// Underlying Firebase or prototype auth implementation.
  final AuthService authService;
  final AnonymousNameGenerator _nameGenerator;

  UserProfile? _profile;
  PendingAuthSession? _pending;
  String? _draftName;
  bool _hasRegeneratedName = false;
  bool _consentAccepted = false;

  UserProfile? get profile => _profile;
  bool get isAuthenticated => _profile != null;
  PendingAuthSession? get pendingSession => _pending;
  String get draftAnonymousName =>
      _draftName ?? (_draftName = _nameGenerator.generate());
  bool get canRegenerateName => !_hasRegeneratedName;
  bool get hasRegeneratedName => _hasRegeneratedName;
  bool get consentAccepted => _consentAccepted;

  /// Email / password path → pending session (name not confirmed yet).
  Future<void> authenticateWithEmail({
    required String email,
    required String password,
  }) async {
    final uid = await authService.signInWithEmail(
      email: email,
      password: password,
    );
    _pending = PendingAuthSession(uid: uid, authMethod: AuthMethod.email);
    _draftName ??= _nameGenerator.generate();
    _hasRegeneratedName = false;
    notifyListeners();
  }

  Future<PhoneVerificationStarted> startPhoneVerification(String phone) {
    return authService.startPhoneVerification(phoneNumber: phone);
  }

  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final uid = await authService.confirmPhoneCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    _pending = PendingAuthSession(uid: uid, authMethod: AuthMethod.phone);
    _draftName ??= _nameGenerator.generate();
    _hasRegeneratedName = false;
    notifyListeners();
  }

  /// Allowed once before confirming.
  void regenerateAnonymousName() {
    if (_hasRegeneratedName) return;
    _draftName = _nameGenerator.generateDifferentFrom(draftAnonymousName);
    _hasRegeneratedName = true;
    notifyListeners();
  }

  void confirmAnonymousName() {
    // Locks the current draft; regenerate disabled after confirm via flow.
    notifyListeners();
  }

  void setConsentAccepted(bool value) {
    _consentAccepted = value;
    notifyListeners();
  }

  /// Final step: write profile and grant Home access.
  UserProfile completeOnboarding() {
    final pending = _pending;
    if (pending == null) {
      throw AuthException('Sign in before finishing setup.');
    }
    if (!_consentAccepted) {
      throw AuthException('Please confirm the consent step to continue.');
    }

    final profile = UserProfile(
      uid: pending.uid,
      anonymousName: draftAnonymousName,
      authMethod: pending.authMethod,
      createdAt: DateTime.now(),
    );
    // Next step: firestore.collection('users').doc(profile.uid).set(profile.toMap());
    _profile = profile;
    _pending = null;
    notifyListeners();
    return profile;
  }

  Future<void> signOut() async {
    await authService.signOut();
    _profile = null;
    _pending = null;
    _draftName = null;
    _hasRegeneratedName = false;
    _consentAccepted = false;
    notifyListeners();
  }

  /// Test / seed helper — skip UI and land on Home.
  void setProfileForTesting(UserProfile profile) {
    _profile = profile;
    _pending = null;
    _consentAccepted = true;
    notifyListeners();
  }
}
