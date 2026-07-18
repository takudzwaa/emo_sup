import 'package:flutter/foundation.dart';

import '../data/local/settings_store.dart';
import '../domain/repositories/notification_service.dart';

/// Device privacy controls for shared-phone homes (PR 21).
///
/// - **Discreet mode:** generic app title; forces notification bodies off.
/// - **App lock:** 4-digit PIN gate after cold start / background (session).
class DiscreetSettings extends ChangeNotifier {
  DiscreetSettings({
    SettingsStore? store,
    NotificationService? notifications,
  })  : _store = store ?? MemorySettingsStore(),
        _notifications = notifications;

  final SettingsStore _store;
  final NotificationService? _notifications;

  bool _loaded = false;
  bool _discreetMode = false;
  bool _appLockEnabled = false;
  bool _unlocked = true;
  String? _pinHash;

  bool get isLoaded => _loaded;
  bool get discreetMode => _discreetMode;
  bool get appLockEnabled => _appLockEnabled;
  bool get isLocked => _appLockEnabled && !_unlocked;
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;

  /// Generic label when discreet (lock-screen / multitasking friendliness).
  String get displayAppTitle =>
      _discreetMode ? 'Notes' : 'Emo Sup';

  Future<void> load() async {
    _discreetMode = await _store.getDiscreetMode();
    _appLockEnabled = await _store.getAppLockEnabled();
    _pinHash = await _store.getPinHash();
    // Lock on cold start if enabled.
    _unlocked = !_appLockEnabled;
    if (_discreetMode) {
      await _notifications?.setAllowNotificationBodies(false);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDiscreetMode(bool value) async {
    _discreetMode = value;
    await _store.setDiscreetMode(value);
    if (value) {
      await _notifications?.setAllowNotificationBodies(false);
    }
    notifyListeners();
  }

  /// Enable lock and set a 4-digit PIN. Returns false if PIN invalid.
  Future<bool> enableAppLock(String pin) async {
    if (!_isValidPin(pin)) return false;
    _pinHash = hashPinPrototype(pin);
    _appLockEnabled = true;
    _unlocked = true;
    await _store.setPinHash(_pinHash);
    await _store.setAppLockEnabled(true);
    notifyListeners();
    return true;
  }

  Future<void> disableAppLock({required String currentPin}) async {
    if (!verifyPin(currentPin)) return;
    _appLockEnabled = false;
    _pinHash = null;
    _unlocked = true;
    await _store.setAppLockEnabled(false);
    await _store.setPinHash(null);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (_pinHash == null) return false;
    return hashPinPrototype(pin) == _pinHash;
  }

  bool unlock(String pin) {
    if (!verifyPin(pin)) return false;
    _unlocked = true;
    notifyListeners();
    return true;
  }

  void lockNow() {
    if (!_appLockEnabled) return;
    _unlocked = false;
    notifyListeners();
  }

  static bool _isValidPin(String pin) {
    final t = pin.trim();
    return t.length == 4 && RegExp(r'^\d{4}$').hasMatch(t);
  }
}
