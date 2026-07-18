import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/services/analytics_service.dart';

void main() {
  test('allowlist accepts pilot ops events', () async {
    final a = MemoryAnalyticsService();
    await a.logEvent('match_requested', {'mode': 'async'});
    await a.logEvent('match_connected');
    expect(a.events.map((e) => e.name), ['match_requested', 'match_connected']);
  });

  test('bans gamification event names', () async {
    final a = MemoryAnalyticsService();
    await a.logEvent('daily_streak_count');
    await a.logEvent('points_earned');
    await a.logEvent('badge_unlocked');
    expect(a.events, isEmpty);
    expect(MemoryAnalyticsService.isBanned('user_streak'), isTrue);
  });

  test('strips message content params', () async {
    final a = MemoryAnalyticsService();
    await a.logEvent('report_submitted', {
      'reason': 'spam',
      'text': 'secret chat',
      'message': 'nope',
    });
    expect(a.events.single.params.containsKey('text'), isFalse);
    expect(a.events.single.params.containsKey('message'), isFalse);
    expect(a.events.single.params['reason'], 'spam');
  });
}
