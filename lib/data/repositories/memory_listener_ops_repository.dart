import 'dart:async';

import '../../domain/repositories/listener_ops_repository.dart';
import '../../models/active_chat_summary.dart';

/// In-memory listener dashboard data for prototype + tests.
class MemoryListenerOpsRepository implements ListenerOpsRepository {
  MemoryListenerOpsRepository({
    this.listenerId = 'listener_amara_k',
    this.availableNow = true,
    List<ActiveChatSummary>? activeChats,
    List<ListenerBookingSummary>? upcomingBookings,
  })  : _activeChats = List<ActiveChatSummary>.from(
          activeChats ?? MemoryListenerOpsRepository.defaultActiveChats(),
        ),
        _upcomingBookings = List<ListenerBookingSummary>.from(
          upcomingBookings ??
              MemoryListenerOpsRepository.defaultUpcomingBookings(),
        );

  final String listenerId;
  bool availableNow;
  final List<ActiveChatSummary> _activeChats;
  final List<ListenerBookingSummary> _upcomingBookings;

  final _availableController = StreamController<bool>.broadcast();
  final _chatsController =
      StreamController<List<ActiveChatSummary>>.broadcast();

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

  @override
  Future<bool> getAvailableNow(String listenerId) async => availableNow;

  @override
  Future<void> setAvailableNow(String listenerId, bool value) async {
    if (availableNow == value) return;
    availableNow = value;
    if (!_availableController.isClosed) {
      _availableController.add(value);
    }
  }

  @override
  Stream<bool> watchAvailableNow(String listenerId) async* {
    yield availableNow;
    yield* _availableController.stream;
  }

  @override
  Future<List<ActiveChatSummary>> listActiveChats(String listenerId) async {
    return List.unmodifiable(_activeChats);
  }

  @override
  Stream<List<ActiveChatSummary>> watchActiveChats(String listenerId) async* {
    yield List.unmodifiable(_activeChats);
    yield* _chatsController.stream;
  }

  @override
  Future<List<ListenerBookingSummary>> listUpcomingBookings(
    String listenerId,
  ) async {
    final list = List<ListenerBookingSummary>.from(_upcomingBookings)
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
    return list;
  }

  @override
  Future<void> markChatRead(String listenerId, String sessionId) async {
    final i = _activeChats.indexWhere((c) => c.sessionId == sessionId);
    if (i == -1) return;
    _activeChats[i] = _activeChats[i].copyWith(unreadCount: 0);
    if (!_chatsController.isClosed) {
      _chatsController.add(List.unmodifiable(_activeChats));
    }
  }

  @override
  Future<void> escalateChat({
    required String sessionId,
    required String listenerId,
    String reason = 'listener_escalation',
  }) async {
    // Prototype: no network. Real path: Cloud Function escalateChat.
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
