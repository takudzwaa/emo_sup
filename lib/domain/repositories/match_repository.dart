import '../../models/chat_session.dart';

/// Match modes for [MatchRepository.requestMatch].
enum MatchMode {
  /// Live presence (may be paid / capacity-limited later).
  now,

  /// Message-and-leave (pilot free path).
  async,
}

/// Result of a matchmaking attempt (CF `requestMatch` or memory stand-in).
sealed class MatchResult {
  const MatchResult();
}

class MatchSuccess extends MatchResult {
  const MatchSuccess({
    required this.session,
    this.quotaCharged = false,
    this.quotaWeekId,
  });

  final ChatSession session;
  final bool quotaCharged;
  final String? quotaWeekId;
}

class MatchQuotaExceeded extends MatchResult {
  const MatchQuotaExceeded({
    required this.used,
    required this.limit,
  });

  final int used;
  final int limit;
}

class MatchNoCapacity extends MatchResult {
  const MatchNoCapacity();
}

class MatchDisabled extends MatchResult {
  const MatchDisabled();
}

class MatchError extends MatchResult {
  const MatchError(this.message);
  final String message;
}

/// Free-match weekly usage snapshot for UI.
class MatchQuotaSnapshot {
  const MatchQuotaSnapshot({
    required this.weekId,
    required this.used,
    required this.limit,
  });

  final String weekId;
  final int used;
  final int limit;

  int get remaining => (limit - used).clamp(0, limit);
}

/// Server-authoritative matchmaking boundary (PR 10).
///
/// Production: Cloud Function `requestMatch`. Prototype: [MemoryMatchRepository].
abstract class MatchRepository {
  Future<MatchResult> requestMatch({
    required String userId,
    required String userDisplayName,
    required MatchMode mode,
    List<String> preferredLanguages = const ['English'],
  });

  Future<MatchQuotaSnapshot> getQuota(String userId);
}
