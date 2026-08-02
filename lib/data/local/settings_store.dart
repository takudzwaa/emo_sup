import 'package:shared_preferences/shared_preferences.dart';

/// Local device settings (PR 21).
///
/// Prototype uses [MemorySettingsStore]; staging/prod use
/// [SharedPreferencesSettingsStore] so app-lock/discreet-mode survive
/// restarts.
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

/// Device-persistent settings via `shared_preferences`.
class SharedPreferencesSettingsStore implements SettingsStore {
  static const _kDiscreetMode = 'settings.discreetMode';
  static const _kPinHash = 'settings.pinHash';
  static const _kAppLockEnabled = 'settings.appLockEnabled';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<bool> getDiscreetMode() async =>
      (await _prefs).getBool(_kDiscreetMode) ?? false;

  @override
  Future<void> setDiscreetMode(bool value) async {
    await (await _prefs).setBool(_kDiscreetMode, value);
  }

  @override
  Future<String?> getPinHash() async => (await _prefs).getString(_kPinHash);

  @override
  Future<void> setPinHash(String? hash) async {
    final prefs = await _prefs;
    if (hash == null) {
      await prefs.remove(_kPinHash);
    } else {
      await prefs.setString(_kPinHash, hash);
    }
  }

  @override
  Future<bool> getAppLockEnabled() async =>
      (await _prefs).getBool(_kAppLockEnabled) ?? false;

  @override
  Future<void> setAppLockEnabled(bool value) async {
    await (await _prefs).setBool(_kAppLockEnabled, value);
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
