/// A 1:1 chat session between a user and one assigned listener.
///
/// Firestore (later):
/// ```
/// chats/{sessionId}          // session document
/// chats/{sessionId}/messages/{messageId}
/// ```
class ChatSession {
  const ChatSession({
    required this.id,
    required this.userId,
    required this.listenerId,
    required this.startedAt,
    this.listenerDisplayName = 'Listener — Amara K.',
    this.userDisplayName = 'Quiet River',
    this.endedAt,
  });

  final String id;
  final String userId;
  final String listenerId;
  final DateTime startedAt;

  /// Anonymous listener label shown in the app bar (not a public profile).
  final String listenerDisplayName;

  /// Anonymous user label (listener dashboard app bar).
  final String userDisplayName;

  /// Set when the user ends the chat (prototype local only).
  final DateTime? endedAt;

  bool get isActive => endedAt == null;

  ChatSession copyWith({
    String? id,
    String? userId,
    String? listenerId,
    DateTime? startedAt,
    String? listenerDisplayName,
    String? userDisplayName,
    DateTime? endedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listenerId: listenerId ?? this.listenerId,
      startedAt: startedAt ?? this.startedAt,
      listenerDisplayName: listenerDisplayName ?? this.listenerDisplayName,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'listenerId': listenerId,
      'startedAt': startedAt.toIso8601String(),
      'listenerDisplayName': listenerDisplayName,
      'userDisplayName': userDisplayName,
      'endedAt': endedAt?.toIso8601String(),
      // Future Firestore: prefer Timestamp.fromDate(...)
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      userId: map['userId'] as String,
      listenerId: map['listenerId'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      listenerDisplayName:
          map['listenerDisplayName'] as String? ?? 'Listener — Amara K.',
      userDisplayName: map['userDisplayName'] as String? ?? 'Quiet River',
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatSession &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            userId == other.userId &&
            listenerId == other.listenerId &&
            startedAt == other.startedAt &&
            listenerDisplayName == other.listenerDisplayName &&
            userDisplayName == other.userDisplayName &&
            endedAt == other.endedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        listenerId,
        startedAt,
        listenerDisplayName,
        userDisplayName,
        endedAt,
      );
}
