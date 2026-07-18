/// Reports, blocks, and delete-my-data entry points.
///
/// Production: `reports` create-only, `blocks`, `deleteMyData` callable.
abstract class SafetyRepository {
  Future<void> submitReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  });

  Future<void> blockTarget({
    required String blockerId,
    required String blockedId,
  });

  /// Soft-delete / erasure request (server-authoritative in prod).
  Future<void> requestDeleteMyData(String userId);
}
