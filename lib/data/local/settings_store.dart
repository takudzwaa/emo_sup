/// Local device settings (PR 21).
///
/// Prototype uses [MemorySettingsStore]. Production should back PIN with
/// platform secure storage (`flutter_secure_storage`) and flags with
/// `shared_preferences` — same interface, different adapter.
abstract class SettingsStore {
  Future<bool> getDiscreetMode();
  Future<void> setDiscreetMode(bool value);

  Future<String?> getPinHash();
  Future<void> setPinHash(String? hash);

  Future<bool> getAppLockEnabled();
  Future<void> setAppLockEnabled(bool value);
}

/// In-memory settings for tests + prototype without extra packages.
class MemorySettingsStore implements SettingsStore {
  bool discreetMode = false;
  bool appLockEnabled = false;
  String? pinHash;

  @override
  Future<bool> getDiscreetMode() async => discreetMode;

  @override
  Future<void> setDiscreetMode(bool value) async {
    discreetMode = value;
  }

  @override
  Future<String?> getPinHash() async => pinHash;

  @override
  Future<void> setPinHash(String? hash) async {
    pinHash = hash;
  }

  @override
  Future<bool> getAppLockEnabled() async => appLockEnabled;

  @override
  Future<void> setAppLockEnabled(bool value) async {
    appLockEnabled = value;
  }
}

/// Lightweight non-cryptographic PIN hash for prototype only.
/// Replace with a proper KDF before production.
String hashPinPrototype(String pin) {
  final cleaned = pin.trim();
  var h = 0;
  for (final c in cleaned.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return 'proto_$h';
}
