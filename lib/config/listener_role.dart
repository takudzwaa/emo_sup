import 'package:flutter/foundation.dart';

/// Listener access gate (PR 20).
///
/// Staging/prod: resolved from the Firebase Auth custom claim
/// `role: "listener"` via [claimResolver] (set by the bootstrap); the
/// `LISTENER_CLAIM` dart-define is ignored whenever a resolver is present.
/// Prototype: `--dart-define=LISTENER_CLAIM=true` or [grantForTesting].
class ListenerRoleGate extends ChangeNotifier {
  ListenerRoleGate({bool? claimOverride, this.claimResolver})
      : _hasClaim = claimOverride ?? (claimResolver == null && _fromEnv);

  /// Async source of truth for the role claim (Firebase ID token in prod).
  final Future<bool> Function()? claimResolver;

  static const String _raw = String.fromEnvironment(
    'LISTENER_CLAIM',
    defaultValue: 'false',
  );

  static bool get _fromEnv {
    final v = _raw.toLowerCase().trim();
    return v == 'true' || v == '1' || v == 'yes';
  }

  bool _hasClaim;

  bool get isListener => _hasClaim;

  /// Re-read the claim from [claimResolver] (e.g. after sign-in / token
  /// refresh). No-op when no resolver is configured.
  Future<void> refresh() async {
    final resolver = claimResolver;
    if (resolver == null) return;
    bool value;
    try {
      value = await resolver();
    } catch (e) {
      debugPrint('ListenerRoleGate: claim refresh failed ($e); denying.');
      value = false;
    }
    if (value != _hasClaim) {
      _hasClaim = value;
      notifyListeners();
    }
  }

  /// Test / local demo helper.
  void grantForTesting() {
    _hasClaim = true;
    notifyListeners();
  }

  void revokeForTesting() {
    _hasClaim = false;
    notifyListeners();
  }
}
