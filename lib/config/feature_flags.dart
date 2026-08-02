import 'package:flutter/foundation.dart';

/// Kill switches for closed pilot (PR 19).
///
/// **Safety & Privacy is never flaggable** — crisis, report, block, delete
/// remain reachable even when match/bookings/payments are off.
class FeatureFlags extends ChangeNotifier {
  FeatureFlags({
    this._matchEnabled = true,
    this._bookingsEnabled = true,
    this._paymentsEnabled = true,
    this._listenLiveEnabled = true,
  });

  bool _matchEnabled;
  bool _bookingsEnabled;
  bool _paymentsEnabled;
  bool _listenLiveEnabled;

  bool get matchEnabled => _matchEnabled;
  bool get bookingsEnabled => _bookingsEnabled;
  bool get paymentsEnabled => _paymentsEnabled;
  bool get listenLiveEnabled => _listenLiveEnabled;

  /// Always true — do not add a setter that can disable Safety.
  bool get safetyAlwaysAvailable => true;

  void setMatchEnabled(bool v) {
    if (_matchEnabled == v) return;
    _matchEnabled = v;
    notifyListeners();
  }

  void setBookingsEnabled(bool v) {
    if (_bookingsEnabled == v) return;
    _bookingsEnabled = v;
    notifyListeners();
  }

  void setPaymentsEnabled(bool v) {
    if (_paymentsEnabled == v) return;
    _paymentsEnabled = v;
    notifyListeners();
  }

  void setListenLiveEnabled(bool v) {
    if (_listenLiveEnabled == v) return;
    _listenLiveEnabled = v;
    notifyListeners();
  }

  /// Apply remote-config style map (prototype / tests).
  void applyRemoteMap(Map<String, dynamic> map) {
    if (map.containsKey('match.enabled')) {
      setMatchEnabled(map['match.enabled'] == true);
    }
    if (map.containsKey('bookings.enabled')) {
      setBookingsEnabled(map['bookings.enabled'] == true);
    }
    if (map.containsKey('payments.mobile_money')) {
      setPaymentsEnabled(map['payments.mobile_money'] == true);
    }
    if (map.containsKey('listen.live')) {
      setListenLiveEnabled(map['listen.live'] == true);
    }
    // Intentionally ignore any safety.* kill keys.
  }
}
