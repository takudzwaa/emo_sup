/// Push notification boundary (PR 12).
///
/// Production: FCM with **title-only / empty body** by default so shared phones
/// do not leak chat content on the lock screen.
abstract class NotificationService {
  /// Register or refresh this device's push token for [userId].
  Future<void> registerToken(String userId);

  /// Clear token(s) on sign-out.
  Future<void> clearToken(String userId);

  /// Whether push bodies are allowed (default false = private).
  bool get allowNotificationBodies;

  Future<void> setAllowNotificationBodies(bool allow);
}

/// In-memory / no-op notifications for prototype + tests.
class MemoryNotificationService implements NotificationService {
  MemoryNotificationService({this._allowBodies = false});

  bool _allowBodies;
  final Map<String, String> tokens = {};
  final List<Map<String, String>> sent = [];

  @override
  bool get allowNotificationBodies => _allowBodies;

  @override
  Future<void> setAllowNotificationBodies(bool allow) async {
    _allowBodies = allow;
  }

  @override
  Future<void> registerToken(String userId) async {
    tokens[userId] = 'memory_token_$userId';
  }

  @override
  Future<void> clearToken(String userId) async {
    tokens.remove(userId);
  }

  /// Simulate a peer-message push (title only unless bodies allowed).
  Future<void> notifyNewMessage({
    required String recipientUserId,
    required String title,
    String? body,
  }) async {
    sent.add({
      'to': recipientUserId,
      'title': title,
      'body': _allowBodies ? (body ?? '') : '',
    });
  }
}
