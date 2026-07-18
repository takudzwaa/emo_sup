/// Listener access gate (PR 20).
///
/// Production: Firebase Auth custom claim `role: "listener"` set via Admin SDK.
/// Prototype: `--dart-define=LISTENER_CLAIM=true` or [ListenerRoleGate.grantForTesting].
class ListenerRoleGate {
  ListenerRoleGate({bool? claimOverride})
      : _hasClaim = claimOverride ?? _fromEnv;

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

  /// Test / local demo helper.
  void grantForTesting() {
    _hasClaim = true;
  }

  void revokeForTesting() {
    _hasClaim = false;
  }
}
