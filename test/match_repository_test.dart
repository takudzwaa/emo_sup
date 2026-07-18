import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/repositories/memory_match_repository.dart';
import 'package:emo_sup/domain/repositories/match_repository.dart';

void main() {
  test('async match creates session and charges quota', () async {
    final match = MemoryMatchRepository(weeklyAsyncQuota: 2);
    final result = await match.requestMatch(
      userId: 'u1',
      userDisplayName: 'Quiet River',
      mode: MatchMode.async,
    );
    expect(result, isA<MatchSuccess>());
    final success = result as MatchSuccess;
    expect(success.quotaCharged, isTrue);
    expect(success.session.userId, 'u1');
    expect(success.session.listenerId, isNotEmpty);

    final quota = await match.getQuota('u1');
    expect(quota.used, 1);
    expect(quota.remaining, 1);
  });

  test('quota exceeded after weeklyAsyncQuota free async matches', () async {
    final match = MemoryMatchRepository(weeklyAsyncQuota: 2);
    await match.requestMatch(
      userId: 'u1',
      userDisplayName: 'Quiet River',
      mode: MatchMode.async,
    );
    await match.requestMatch(
      userId: 'u1',
      userDisplayName: 'Quiet River',
      mode: MatchMode.async,
    );
    final third = await match.requestMatch(
      userId: 'u1',
      userDisplayName: 'Quiet River',
      mode: MatchMode.async,
    );
    expect(third, isA<MatchQuotaExceeded>());
  });

  test('now mode does not charge free quota', () async {
    final match = MemoryMatchRepository(weeklyAsyncQuota: 1);
    final result = await match.requestMatch(
      userId: 'u1',
      userDisplayName: 'Quiet River',
      mode: MatchMode.now,
    );
    expect(result, isA<MatchSuccess>());
    expect((result as MatchSuccess).quotaCharged, isFalse);
    final quota = await match.getQuota('u1');
    expect(quota.used, 0);
  });
}
