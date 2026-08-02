import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../config/app_flavor.dart';

/// App Check / Play Integrity boundary (PR 25).
///
/// Production: Play Integrity (Android) + App Attest/DeviceCheck (iOS) via
/// `firebase_app_check`. Staging: debug provider tokens.
abstract class AppCheckService {
  /// Whether enforcement is active (reject unattested clients server-side).
  bool get enforcementEnabled;

  Future<void> activate();

  /// Optional token for debugging; never log in prod builds.
  Future<String?> getDebugTokenHint();
}

/// Prototype / unconfigured project: no-op with clear staging notes.
class MemoryAppCheckService implements AppCheckService {
  MemoryAppCheckService({
    this._flavor = AppFlavor.prototype,
    this._forceEnforce = false,
  });

  final AppFlavor _flavor;
  final bool _forceEnforce;
  bool _activated = false;

  @override
  bool get enforcementEnabled =>
      _forceEnforce || _flavor == AppFlavor.prod;

  bool get isActivated => _activated;

  @override
  Future<void> activate() async {
    _activated = true;
    if (_flavor == AppFlavor.staging) {
      debugPrint(
        'App Check: staging — use debug provider tokens '
        '(firebase_app_check + Play Integrity debug).',
      );
    } else if (_flavor == AppFlavor.prod) {
      debugPrint(
        'App Check: prod enforcement expected '
        '(Play Integrity / App Attest). Ensure providers are registered.',
      );
    } else {
      debugPrint('App Check: prototype — not enforced.');
    }
  }

  @override
  Future<String?> getDebugTokenHint() async {
    if (_flavor == AppFlavor.prod) return null;
    return 'debug-token-register-in-firebase-console';
  }
}

/// Real attestation via `firebase_app_check`.
///
/// Debug builds use the debug provider (token printed to console once —
/// register it under App Check > Debug tokens in the Firebase Console).
/// Release builds use Play Integrity / App Attest with DeviceCheck fallback.
class FirebaseAppCheckService implements AppCheckService {
  FirebaseAppCheckService({required this._flavor});

  final AppFlavor _flavor;

  @override
  bool get enforcementEnabled => _flavor == AppFlavor.prod;

  @override
  Future<void> activate() async {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider()
          : AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    debugPrint('App Check activated (${_flavor.name}).');
  }

  @override
  Future<String?> getDebugTokenHint() async {
    if (!kDebugMode || _flavor == AppFlavor.prod) return null;
    return 'Debug provider prints its token to the console on first launch — '
        'register it in Firebase Console > App Check > Debug tokens.';
  }
}
