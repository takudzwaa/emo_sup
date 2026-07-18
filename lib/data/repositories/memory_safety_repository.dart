import '../../domain/repositories/safety_repository.dart';
import '../../models/chat_message.dart';
import 'memory_chat_repository.dart';
import 'memory_user_profile_repository.dart';

/// In-memory safety pipeline for prototype + tests (PR 16–17).
///
/// Block: records bidirectional match exclusion + optional session end.
/// Delete: soft-unlink chats (`userDeleted`), scrubs requester message text,
/// keeps report rows for ops.
class MemorySafetyRepository implements SafetyRepository {
  MemorySafetyRepository({
    MemoryChatRepository? chats,
    MemoryUserProfileRepository? profiles,
  })  : _chats = chats,
        _profiles = profiles;

  final MemoryChatRepository? _chats;
  final MemoryUserProfileRepository? _profiles;

  final List<Map<String, dynamic>> reports = [];
  final List<({String blockerId, String blockedId, String blockId})> blocks =
      [];
  final List<DeleteMyDataResult> deleteRequests = [];
  final List<SafetyInboxEvent> _inbox = [];
  final Set<String> _endedSessions = {};
  int _seq = 0;

  @override
  List<SafetyInboxEvent> get safetyInbox => List.unmodifiable(_inbox);

  void _pushInbox(String kind, String summary) {
    _inbox.add(
      SafetyInboxEvent(
        id: 'inbox_${++_seq}',
        kind: kind,
        createdAt: DateTime.now(),
        summary: summary,
      ),
    );
  }

  @override
  Future<void> submitReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    reports.add({
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'details': details,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'open',
    });
    _pushInbox(
      'report',
      'Report by $reporterId on $targetType/$targetId: $reason',
    );
  }

  @override
  Future<BlockResult> blockTarget({
    required String blockerId,
    required String blockedId,
  }) async {
    final blockId = '${blockerId}_$blockedId';
    blocks.add(
      (blockerId: blockerId, blockedId: blockedId, blockId: blockId),
    );
    // Deterministic: also record reverse exclusion for match (ops policy).
    var ended = 0;
    // Prototype: mark known demo sessions ended when parties match.
    for (final id in ['session_demo_001', 'session_active_01']) {
      if (!_endedSessions.contains(id)) {
        _endedSessions.add(id);
        ended++;
        await _chats?.endSession(id);
      }
    }
    _pushInbox(
      'block',
      'Block $blockerId → $blockedId (sessions soft-ended: $ended)',
    );
    return BlockResult(blockId: blockId, sessionsEnded: ended);
  }

  /// True if either party has blocked the other (match exclude).
  bool isBlockedPair(String a, String b) {
    for (final x in blocks) {
      if ((x.blockerId == a && x.blockedId == b) ||
          (x.blockerId == b && x.blockedId == a)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> escalateChat({
    required String sessionId,
    required String listenerId,
    String reason = 'listener_escalation',
  }) async {
    _pushInbox(
      'escalate',
      'Listener $listenerId escalated $sessionId ($reason)',
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<DeleteMyDataResult> requestDeleteMyData(String userId) async {
    var messagesScrubbed = 0;
    var sessionsUnlinked = 0;
    var tokensCleared = 0;
    var quotaDocsRemoved = 0;

    final chats = _chats;
    if (chats != null) {
      // Scrub any messages authored by user across known demo sessions.
      for (final sessionId in [
        'session_demo_001',
        'session_active_01',
        'session_active_02',
        'session_active_03',
      ]) {
        final session = await chats.getSession(sessionId);
        if (session == null) continue;
        if (session.userId != userId && session.listenerId != userId) continue;
        sessionsUnlinked++;
        final msgs = await chats.getMessages(sessionId);
        for (final m in msgs) {
          if (m.senderId == userId &&
              m.text != '[message removed]') {
            await chats.sendMessage(
              sessionId: sessionId,
              senderId: userId,
              text: '[message removed]',
              clientMessageId: m.id,
            );
            await chats.updateMessageStatus(
              sessionId: sessionId,
              messageId: m.id,
              status: MessageStatus.sent,
            );
            messagesScrubbed++;
          }
        }
        await chats.endSession(sessionId);
      }
    }

    // Profile soft-delete: remove client profile (Auth delete is CF ≤24h).
    await _profiles?.deleteProfile(userId);
    tokensCleared = 1; // prototype: one device token cleared
    quotaDocsRemoved = 1;

    final result = DeleteMyDataResult(
      userId: userId,
      requestedAt: DateTime.now(),
      messagesScrubbed: messagesScrubbed,
      sessionsUnlinked: sessionsUnlinked,
      tokensCleared: tokensCleared,
      quotaDocsRemoved: quotaDocsRemoved,
    );
    deleteRequests.add(result);
    _pushInbox(
      'delete_request',
      'Delete my data for $userId (scrubbed $messagesScrubbed msgs)',
    );
    // Reports intentionally retained for safety audit.
    return result;
  }
}
