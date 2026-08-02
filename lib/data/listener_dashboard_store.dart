import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/listener_ops_repository.dart';
import '../domain/repositories/safety_repository.dart';
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
    this.chatRepository,
    this.safetyRepository,
  })  : repository = repository ??
            MemoryListenerOpsRepository(
              listenerId: listenerId,
              availableNow: availableNow,
              activeChats: activeChats,
              upcomingBookings: upcomingBookings,
            ),
        availableNow = availableNow,
        _activeChats = List<ActiveChatSummary>.from(
          activeChats ??
              (repository is MemoryListenerOpsRepository || repository == null
                  ? MemoryListenerOpsRepository.defaultActiveChats()
                  : const <ActiveChatSummary>[]),
        ),
        _upcomingBookings = List<ListenerBookingSummary>.from(
          upcomingBookings ??
              (repository is MemoryListenerOpsRepository || repository == null
                  ? MemoryListenerOpsRepository.defaultUpcomingBookings()
                  : const <ListenerBookingSummary>[]),
        ) {
    if (this.repository is! MemoryListenerOpsRepository) {
      _bindRemote();
    }
  }

  StreamSubscription<List<ActiveChatSummary>>? _chatsSub;
  StreamSubscription<bool>? _availSub;

  void _bindRemote() {
    _chatsSub = repository.watchActiveChats(listenerId).listen((list) {
      _activeChats
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
    _availSub = repository.watchAvailableNow(listenerId).listen((v) {
      availableNow = v;
      notifyListeners();
    });
    repository.listUpcomingBookings(listenerId).then((list) {
      _upcomingBookings
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    _availSub?.cancel();
    super.dispose();
  }

  final ListenerOpsRepository repository;
  final ChatRepository? chatRepository;
  final SafetyRepository? safetyRepository;
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

  /// Demo-only estimate — hidden in live listener UI when not prototype.
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
    final session = ChatSession(
      id: summary.sessionId,
      userId: summary.userId,
      listenerId: listenerId,
      startedAt: now.subtract(const Duration(minutes: 20)),
      listenerDisplayName: listenerDisplayName,
      userDisplayName: summary.userAnonymousName,
    );
    if (chatRepository != null) {
      return ChatStore(
        session: session,
        seedMessages: const [],
        mockListenerReplies: false,
        actingAsId: listenerId,
        repository: chatRepository,
      );
    }
    return ChatStore(
      session: session,
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
