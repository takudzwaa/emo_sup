import 'package:flutter/foundation.dart';

import '../models/active_chat_summary.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'chat_store.dart';

/// In-memory state for the Listener Dashboard prototype.
///
/// Later Firestore:
/// ```
/// listeners/{listenerId}                 // availability
/// chats where listenerId == me           // active chats
/// bookings where listenerId == me        // upcoming
/// ```
class ListenerDashboardStore extends ChangeNotifier {
  ListenerDashboardStore({
    this.listenerId = 'listener_amara_k',
    this.listenerDisplayName = 'Listener — Harbor',
    this.availableNow = true,
    List<ActiveChatSummary>? activeChats,
    List<ListenerBookingSummary>? upcomingBookings,
  })  : _activeChats = List<ActiveChatSummary>.from(
          activeChats ?? defaultActiveChats(),
        ),
        _upcomingBookings = List<ListenerBookingSummary>.from(
          upcomingBookings ?? defaultUpcomingBookings(),
        );

  final String listenerId;
  final String listenerDisplayName;

  bool availableNow;
  final List<ActiveChatSummary> _activeChats;
  final List<ListenerBookingSummary> _upcomingBookings;

  List<ActiveChatSummary> get activeChats => List.unmodifiable(_activeChats);
  List<ListenerBookingSummary> get upcomingBookings {
    final list = List<ListenerBookingSummary>.from(_upcomingBookings)
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
    return list;
  }

  /// Active chats count used as "sessions today" demo metric.
  int get sessionsToday => _activeChats.length;

  /// Stub earnings: \$8 per active session — demo only, not real payouts.
  int get estimatedEarningsDemo => sessionsToday * 8;

  void setAvailableNow(bool value) {
    if (availableNow == value) return;
    availableNow = value;
    // Next: firestore.collection('listeners').doc(listenerId).update({...});
    notifyListeners();
  }

  void markChatRead(String sessionId) {
    final i = _activeChats.indexWhere((c) => c.sessionId == sessionId);
    if (i == -1) return;
    _activeChats[i] = _activeChats[i].copyWith(unreadCount: 0);
    notifyListeners();
  }

  /// Builds a [ChatStore] for the listener to open an existing conversation.
  ChatStore openChatStore(ActiveChatSummary summary) {
    final now = DateTime.now();
    return ChatStore(
      session: ChatSession(
        id: summary.sessionId,
        userId: summary.userId,
        listenerId: listenerId,
        startedAt: now.subtract(const Duration(minutes: 20)),
        listenerDisplayName: listenerDisplayName,
        userDisplayName: summary.userAnonymousName,
      ),
      seedMessages: [
        ChatMessage(
          id: '${summary.sessionId}_m0',
          senderId: listenerId,
          text: "I'm here with you. Take your time.",
          timestamp: summary.lastMessageAt.subtract(const Duration(minutes: 3)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: '${summary.sessionId}_m1',
          senderId: summary.userId,
          text: summary.lastMessagePreview,
          timestamp: summary.lastMessageAt,
          status: MessageStatus.delivered,
        ),
      ],
      mockListenerReplies: false,
      actingAsId: listenerId,
    );
  }

  /// Escalation stub — real path would notify on-call / safety team.
  ///
  /// Hook point (later):
  /// ```
  /// // Cloud Function: escalateChat({ sessionId, listenerId, reason })
  /// // → page on-call safety reviewer + flag chat in Firestore
  /// // → optional: notify user that extra support is being arranged
  /// ```
  Future<void> escalateChat({
    required String sessionId,
    String reason = 'listener_escalation',
  }) async {
    // Prototype: no network. Mark as handled locally for UI feedback.
    debugPrint(
      'ESCALATE stub session=$sessionId listener=$listenerId reason=$reason',
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  static List<ActiveChatSummary> defaultActiveChats() {
    final now = DateTime.now();
    return [
      ActiveChatSummary(
        sessionId: 'session_active_01',
        userId: 'user_quiet_river',
        userAnonymousName: 'Quiet River',
        lastMessagePreview:
            "It's been a heavy week and I just needed somewhere quiet.",
        lastMessageAt: now.subtract(const Duration(minutes: 4)),
        unreadCount: 2,
      ),
      ActiveChatSummary(
        sessionId: 'session_active_02',
        userId: 'user_soft_meadow',
        userAnonymousName: 'Soft Meadow',
        lastMessagePreview: 'Thanks for listening earlier. Still here.',
        lastMessageAt: now.subtract(const Duration(minutes: 28)),
        unreadCount: 0,
      ),
      ActiveChatSummary(
        sessionId: 'session_active_03',
        userId: 'user_still_pine',
        userAnonymousName: 'Still Pine',
        lastMessagePreview: 'Work has been a lot. Not sure where to start.',
        lastMessageAt: now.subtract(const Duration(hours: 1)),
        unreadCount: 1,
      ),
    ];
  }

  static List<ListenerBookingSummary> defaultUpcomingBookings() {
    final now = DateTime.now();
    return [
      ListenerBookingSummary(
        bookingId: 'lb_01',
        userId: 'user_calm_brook',
        userAnonymousName: 'Calm Brook',
        // In the join window for prototype demos.
        slotStart: now.subtract(const Duration(minutes: 2)),
      ),
      ListenerBookingSummary(
        bookingId: 'lb_02',
        userId: 'user_gentle_cloud',
        userAnonymousName: 'Gentle Cloud',
        slotStart: now.add(const Duration(hours: 3)),
      ),
      ListenerBookingSummary(
        bookingId: 'lb_03',
        userId: 'user_mellow_stone',
        userAnonymousName: 'Mellow Stone',
        slotStart: now.add(const Duration(days: 1, hours: 2)),
      ),
    ];
  }
}
