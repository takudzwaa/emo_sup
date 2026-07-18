import 'package:flutter/foundation.dart';

/// Privacy-respecting product analytics (PR 24).
///
/// **Allowed:** aggregate ops metrics (match wait, quota, reports) — never message
/// content, never streak/points/badges (gamification ban).
abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object?> params = const {}]);
}

/// In-memory sink for tests + prototype; enforces the gamification ban.
class MemoryAnalyticsService implements AnalyticsService {
  final List<({String name, Map<String, Object?> params})> events = [];

  /// Explicit allowlist for pilot dashboards.
  static const allowedEvents = <String>{
    'match_requested',
    'match_connected',
    'match_quota_exceeded',
    'match_no_capacity',
    'match_disabled',
    'booking_checkout_started',
    'booking_confirmed',
    'payment_success',
    'payment_declined',
    'membership_activated',
    'report_submitted',
    'block_submitted',
    'delete_my_data_requested',
    'escalate_chat',
    'safety_opened',
    'crisis_resource_opened',
    'app_lock_unlocked',
    'auth_completed',
  };

  /// Hard ban — never emit growth/gamification signals.
  static const bannedEventFragments = <String>[
    'streak',
    'points',
    'badge',
    'level_up',
    'leaderboard',
    'xp_',
    'reward',
    'daily_challenge',
    'gamif',
  ];

  static bool isBanned(String name) {
    final lower = name.toLowerCase();
    for (final frag in bannedEventFragments) {
      if (lower.contains(frag)) return true;
    }
    return false;
  }

  static bool isAllowed(String name) => allowedEvents.contains(name);

  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> params = const {},
  ]) async {
    if (isBanned(name)) {
      debugPrint('Analytics BAN: refused event "$name" (gamification/privacy)');
      return;
    }
    if (!isAllowed(name)) {
      debugPrint('Analytics skip: "$name" not on pilot allowlist');
      return;
    }
    // Never attach free-text message content.
    final safe = Map<String, Object?>.from(params)
      ..remove('text')
      ..remove('message')
      ..remove('body')
      ..remove('content');
    events.add((name: name, params: safe));
  }
}

/// Dashboard metric keys for ops (documented; not a live BI product).
class PilotDashboardMetrics {
  PilotDashboardMetrics._();

  static const keys = <String>[
    'match_connect_rate',
    'match_quota_exceeded_rate',
    'match_no_capacity_rate',
    'booking_confirm_count',
    'payment_success_rate',
    'report_rate',
    'escalate_count',
    'delete_request_count',
    'p50_match_latency_ms', // ops only; no content
  ];
}
