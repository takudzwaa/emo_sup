import 'package:flutter/foundation.dart';

import '../domain/repositories/listener_ops_repository.dart';
import '../models/active_chat_summary.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'chat_store.dart';
import 'repositories/memory_listener_ops_repository.dart';

/// UI-facing Listener Dashboard store (ChangeNotifier façade).
class ListenerDashboardStore extends ChangeNotifier {
  ListenerDashboardStore({
    this.listenerId = 'listener_amara_k',
    this.listenerDisplayName = 'Listener — Harbor',
    bool availableNow = true,
    List<ActiveChatSummary>? activeChats,
    List<ListenerBookingSummary>? upcomingBookings,
    ListenerOpsRepository? repository,
  })  : repository = repository ??
            MemoryListenerOpsRepository(
              listenerId: listenerId,
              availableNow: availableNow,
              activeChats: activeChats,
              upcomingBookings: upcomingBookings,
            ),
        availableNow = availableNow,
        _activeChats = List<ActiveChatSummary>.from(
          activeChats ?? MemoryListenerOpsRepository.defaultActiveChats(),
        ),
        _upcomingBookings = List<ListenerBookingSummary>.from(
          upcomingBookings ??
              MemoryListenerOpsRepository.defaultUpcomingBookings(),
        );

  final ListenerOpsRepository repository;
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

  int get sessionsToday => _activeChats.length;

  /// Stub earnings: \$8 per active session — demo only, not real payouts.
  int get estimatedEarningsDemo => sessionsToday * 8;

  void setAvailableNow(bool value) {
    if (availableNow == value) return;
    availableNow = value;
    repository.setAvailableNow(listenerId, value);
    notifyListeners();
  }

  void markChatRead(String sessionId) {
    final i = _activeChats.indexWhere((c) => c.sessionId == sessionId);
    if (i == -1) return;
    _activeChats[i] = _activeChats[i].copyWith(unreadCount: 0);
    repository.markChatRead(listenerId, sessionId);
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

  Future<void> escalateChat({
    required String sessionId,
    String reason = 'listener_escalation',
  }) async {
    debugPrint(
      'ESCALATE stub session=$sessionId listener=$listenerId reason=$reason',
    );
    await repository.escalateChat(
      sessionId: sessionId,
      listenerId: listenerId,
      reason: reason,
    );
  }

  static List<ActiveChatSummary> defaultActiveChats() =>
      MemoryListenerOpsRepository.defaultActiveChats();

  static List<ListenerBookingSummary> defaultUpcomingBookings() =>
      MemoryListenerOpsRepository.defaultUpcomingBookings();
}
