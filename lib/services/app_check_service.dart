import 'package:flutter/foundation.dart';

import '../config/app_flavor.dart';

/// App Check / Play Integrity boundary (PR 25).
///
/// Production: Play Integrity (Android) + App Attest/DeviceCheck (iOS) via
/// `firebase_app_check`. Staging: debug provider tokens.
///
/// This interface ships now so call sites exist; real provider activation
/// requires a linked Firebase project + native config.
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
    AppFlavor flavor = AppFlavor.prototype,
    bool forceEnforce = false,
  })  : _flavor = flavor,
        _forceEnforce = forceEnforce;

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
