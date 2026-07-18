import '../../domain/repositories/listener_directory_repository.dart';
import '../../domain/repositories/match_repository.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../models/listener_profile.dart';
import 'memory_chat_repository.dart';
import 'memory_listener_directory_repository.dart';

/// Prototype stand-in for CF `requestMatch` + `match_quota` (PR 10).
///
/// Enforces weekly async free quota (default 2) and assigns an available
/// listener from the directory. Does not trust client-supplied listenerId
/// for the match path (picks server-side).
class MemoryMatchRepository implements MatchRepository {
  MemoryMatchRepository({
    ListenerDirectoryRepository? listeners,
    MemoryChatRepository? chats,
    this.weeklyAsyncQuota = 2,
    this.matchEnabled = true,
  })  : _listeners = listeners ?? MemoryListenerDirectoryRepository(),
        _chats = chats ?? MemoryChatRepository();

  final ListenerDirectoryRepository _listeners;
  final MemoryChatRepository _chats;
  final int weeklyAsyncQuota;
  final bool matchEnabled;

  /// weekId → userId → {started, refunded}
  final Map<String, Map<String, ({int started, int refunded})>> _quota = {};
  int _sessionCounter = 0;

  /// Week key in Africa/Harare (UTC+2, no DST) — pilot TZ.
  /// Format `YYYY-Www` (week-of-year Monday-based approximation).
  static String weekIdFor(DateTime utcNow) {
    final harare = utcNow.toUtc().add(const Duration(hours: 2));
    final date = DateTime.utc(harare.year, harare.month, harare.day);
    final startOfYear = DateTime.utc(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;
    final week = ((dayOfYear - 1) ~/ 7) + 1;
    return '${date.year}-W${week.toString().padLeft(2, '0')}';
  }

  ({int started, int refunded}) _quotaPair(String userId, String weekId) {
    final byUser = _quota.putIfAbsent(weekId, () => {});
    return byUser.putIfAbsent(userId, () => (started: 0, refunded: 0));
  }

  void _setQuota(String userId, String weekId, ({int started, int refunded}) v) {
    _quota.putIfAbsent(weekId, () => {})[userId] = v;
  }

  @override
  Future<MatchQuotaSnapshot> getQuota(String userId) async {
    final weekId = weekIdFor(DateTime.now().toUtc());
    final q = _quotaPair(userId, weekId);
    final used = (q.started - q.refunded).clamp(0, 999);
    return MatchQuotaSnapshot(
      weekId: weekId,
      used: used,
      limit: weeklyAsyncQuota,
    );
  }

  @override
  Future<MatchResult> requestMatch({
    required String userId,
    required String userDisplayName,
    required MatchMode mode,
    List<String> preferredLanguages = const ['English'],
  }) async {
    if (!matchEnabled) return const MatchDisabled();

    final weekId = weekIdFor(DateTime.now().toUtc());
    var quotaCharged = false;

    if (mode == MatchMode.async) {
      final q = _quotaPair(userId, weekId);
      final used = q.started - q.refunded;
      if (used >= weeklyAsyncQuota) {
        return MatchQuotaExceeded(used: used, limit: weeklyAsyncQuota);
      }
      _setQuota(
        userId,
        weekId,
        (started: q.started + 1, refunded: q.refunded),
      );
      quotaCharged = true;
    }

    final all = await _listeners.listListeners();
    ListenerProfile? pick;
    for (final lang in preferredLanguages) {
      for (final l in all) {
        if (l.languages.contains(lang)) {
          pick = l;
          break;
        }
      }
      if (pick != null) break;
    }
    pick ??= all.isEmpty ? null : all.first;
    if (pick == null) {
      // Refund quota if we charged.
      if (quotaCharged) {
        final q = _quotaPair(userId, weekId);
        _setQuota(
          userId,
          weekId,
          (started: q.started, refunded: q.refunded + 1),
        );
      }
      return const MatchNoCapacity();
    }

    final sessionId = 'session_match_${++_sessionCounter}';
    final session = ChatSession(
      id: sessionId,
      userId: userId,
      listenerId: pick.id,
      startedAt: DateTime.now(),
      listenerDisplayName: pick.displayName,
      userDisplayName: userDisplayName,
    );

    final opener = ChatMessage(
      id: '${sessionId}_m0',
      senderId: pick.id,
      text:
          "Hi — I'm here to listen. This is a private space; share only "
          'what feels comfortable. Take your time.',
      timestamp: DateTime.now(),
      status: MessageStatus.delivered,
    );

    _chats.seedSession(session, messages: [opener]);

    return MatchSuccess(
      session: session,
      quotaCharged: quotaCharged,
      quotaWeekId: quotaCharged ? weekId : null,
    );
  }

  /// Test helper: force quota nearly full.
  void debugSetUsed(String userId, int used) {
    final weekId = weekIdFor(DateTime.now().toUtc());
    _setQuota(userId, weekId, (started: used, refunded: 0));
  }
}
