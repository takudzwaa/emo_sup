import 'package:flutter/foundation.dart';

import '../domain/repositories/user_profile_repository.dart';
import '../data/repositories/memory_user_profile_repository.dart';
import '../models/user_profile.dart';
import 'anonymous_name_generator.dart';
import 'auth_service.dart';

/// Orchestrates onboarding: credentials → display name → consent → Home.
///
/// Profiles persist via [UserProfileRepository] (`users/{uid}`).
class AuthController extends ChangeNotifier {
  AuthController({
    required this.authService,
    UserProfileRepository? profileRepository,
    AnonymousNameGenerator? nameGenerator,
    UserProfile? initialProfile,
  })  : profileRepository =
            profileRepository ?? MemoryUserProfileRepository(),
        _nameGenerator = nameGenerator ?? AnonymousNameGenerator(),
        _profile = initialProfile;

  /// Underlying Firebase or prototype auth implementation.
  final AuthService authService;
  final UserProfileRepository profileRepository;
  final AnonymousNameGenerator _nameGenerator;

  UserProfile? _profile;
  PendingAuthSession? _pending;
  String? _draftName;
  bool _hasRegeneratedName = false;
  bool _consentAccepted = false;
  bool _ageConfirmed = false;
  bool _restoring = false;

  UserProfile? get profile => _profile;
  bool get isAuthenticated => _profile != null;
  PendingAuthSession? get pendingSession => _pending;
  String get draftAnonymousName =>
      _draftName ?? (_draftName = _nameGenerator.generate());
  bool get canRegenerateName => !_hasRegeneratedName;
  bool get hasRegeneratedName => _hasRegeneratedName;
  bool get consentAccepted => _consentAccepted;
  bool get ageConfirmed => _ageConfirmed;
  bool get isRestoring => _restoring;

  /// If Auth has a uid and a stored profile exists, land on Home (session restore).
  Future<void> tryRestoreSession() async {
    final uid = authService.currentUid;
    if (uid == null || _profile != null) return;
    _restoring = true;
    notifyListeners();
    try {
      final existing = await profileRepository.getProfile(uid);
      if (existing != null) {
        _profile = existing;
        _consentAccepted = true;
        _ageConfirmed = true;
      }
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  /// Email / password path → pending session (name not confirmed yet).
  Future<void> authenticateWithEmail({
    required String email,
    required String password,
  }) async {
    final uid = await authService.signInWithEmail(
      email: email,
      password: password,
    );
    // Returning user: load profile and skip onboarding.
    final existing = await profileRepository.getProfile(uid);
    if (existing != null) {
      _profile = existing;
      _pending = null;
      _consentAccepted = true;
      _ageConfirmed = true;
      notifyListeners();
      return;
    }
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
    final existing = await profileRepository.getProfile(uid);
    if (existing != null) {
      _profile = existing;
      _pending = null;
      _consentAccepted = true;
      _ageConfirmed = true;
      notifyListeners();
      return;
    }
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
    notifyListeners();
  }

  void setConsentAccepted(bool value) {
    _consentAccepted = value;
    notifyListeners();
  }

  void setAgeConfirmed(bool value) {
    _ageConfirmed = value;
    notifyListeners();
  }

  /// Final step: write profile and grant Home access.
  UserProfile completeOnboarding() {
    final pending = _pending;
    if (pending == null) {
      throw AuthException('Sign in before finishing setup.');
    }
    if (!_ageConfirmed) {
      throw AuthException('Please confirm you are 18 or older to continue.');
    }
    if (!_consentAccepted) {
      throw AuthException('Please confirm the consent step to continue.');
    }

    final profile = UserProfile(
      uid: pending.uid,
      anonymousName: draftAnonymousName,
      authMethod: pending.authMethod,
      createdAt: DateTime.now(),
      ageConfirmedAt: DateTime.now(),
    );
    // Persist (memory or Firestore adapter).
    profileRepository.upsertProfile(profile);
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
    _ageConfirmed = false;
    notifyListeners();
  }

  /// Test / seed helper — skip UI and land on Home.
  void setProfileForTesting(UserProfile profile) {
    _profile = profile;
    _pending = null;
    _consentAccepted = true;
    _ageConfirmed = true;
    profileRepository.upsertProfile(profile);
    notifyListeners();
  }
}
