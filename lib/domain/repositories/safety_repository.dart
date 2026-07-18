/// Reports, blocks, escalate, and delete-my-data entry points.
///
/// Production: Firestore `reports` (create-only), `blocks`, CF `deleteMyData`,
/// CF escalate → `safety_inbox`.
abstract class SafetyRepository {
  Future<void> submitReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  });

  /// Deterministic block: store block, end active sessions between pair,
  /// exclude both directions from future match (enforced in match CF).
  Future<BlockResult> blockTarget({
    required String blockerId,
    required String blockedId,
  });

  Future<void> escalateChat({
    required String sessionId,
    required String listenerId,
    String reason = 'listener_escalation',
  });

  /// Soft-unlink + scrub requester-authored message text (both views).
  /// Retains report metadata for the safety team.
  Future<DeleteMyDataResult> requestDeleteMyData(String userId);

  /// Ops inbox events (reports, escalations) for pilot review.
  List<SafetyInboxEvent> get safetyInbox;
}

class BlockResult {
  const BlockResult({
    required this.blockId,
    required this.sessionsEnded,
  });

  final String blockId;
  final int sessionsEnded;
}

class DeleteMyDataResult {
  const DeleteMyDataResult({
    required this.userId,
    required this.requestedAt,
    required this.messagesScrubbed,
    required this.sessionsUnlinked,
    required this.tokensCleared,
    required this.quotaDocsRemoved,
  });

  final String userId;
  final DateTime requestedAt;
  final int messagesScrubbed;
  final int sessionsUnlinked;
  final int tokensCleared;
  final int quotaDocsRemoved;
}

class SafetyInboxEvent {
  const SafetyInboxEvent({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.summary,
    this.ackDueWithin = const Duration(hours: 24),
  });

  final String id;
  final String kind; // report | escalate | delete_request
  final DateTime createdAt;
  final String summary;
  final Duration ackDueWithin;
}
