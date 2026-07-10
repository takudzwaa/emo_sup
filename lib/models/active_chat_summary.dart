/// Listener-facing summary of an open 1:1 chat.
///
/// Firestore (later): derived from `chats/{sessionId}` + last message query.
class ActiveChatSummary {
  const ActiveChatSummary({
    required this.sessionId,
    required this.userId,
    required this.userAnonymousName,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String sessionId;
  final String userId;

  /// User's anonymous display name only (never a real name).
  final String userAnonymousName;
  final String lastMessagePreview;
  final DateTime lastMessageAt;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  ActiveChatSummary copyWith({
    String? sessionId,
    String? userId,
    String? userAnonymousName,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ActiveChatSummary(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userAnonymousName: userAnonymousName ?? this.userAnonymousName,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// A scheduled session on the listener dashboard.
class ListenerBookingSummary {
  const ListenerBookingSummary({
    required this.bookingId,
    required this.userId,
    required this.userAnonymousName,
    required this.slotStart,
  });

  final String bookingId;
  final String userId;
  final String userAnonymousName;
  final DateTime slotStart;

  /// True when the slot time has arrived (or passed within session window).
  bool get canJoin {
    final now = DateTime.now();
    // Allow join from 5 minutes before through 45 minutes after start.
    final open = slotStart.subtract(const Duration(minutes: 5));
    final close = slotStart.add(const Duration(minutes: 45));
    return !now.isBefore(open) && now.isBefore(close);
  }

  bool get isUpcoming => DateTime.now().isBefore(slotStart);
}
