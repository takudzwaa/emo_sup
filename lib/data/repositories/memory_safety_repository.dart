import '../../domain/repositories/safety_repository.dart';

/// Captures safety actions in memory for prototype + tests.
class MemorySafetyRepository implements SafetyRepository {
  final List<Map<String, dynamic>> reports = [];
  final List<({String blockerId, String blockedId})> blocks = [];
  final List<String> deleteRequests = [];

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
  }

  @override
  Future<void> blockTarget({
    required String blockerId,
    required String blockedId,
  }) async {
    blocks.add((blockerId: blockerId, blockedId: blockedId));
  }

  @override
  Future<void> requestDeleteMyData(String userId) async {
    deleteRequests.add(userId);
  }
}
