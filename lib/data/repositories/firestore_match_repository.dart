import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/match_repository.dart';
import '../../models/chat_session.dart';
import '../firebase/callable_client.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreMatchRepository implements MatchRepository {
  FirestoreMatchRepository({
    FirebaseFirestore? firestore,
    CallableClient? callables,
    this.weeklyAsyncQuota = 2,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _callables = callables ?? CallableClient();

  final FirebaseFirestore _db;
  final CallableClient _callables;
  final int weeklyAsyncQuota;

  static String weekIdFor(DateTime utcNow) {
    final harare = utcNow.toUtc().add(const Duration(hours: 2));
    final date = DateTime.utc(harare.year, harare.month, harare.day);
    final startOfYear = DateTime.utc(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;
    final week = ((dayOfYear - 1) ~/ 7) + 1;
    return '${date.year}-W${week.toString().padLeft(2, '0')}';
  }

  @override
  Future<MatchQuotaSnapshot> getQuota(String userId) async {
    final weekId = weekIdFor(DateTime.now().toUtc());
    final snap =
        await _db.doc('${FirestorePaths.matchQuota(userId)}/$weekId').get();
    final d = snap.data() ?? {};
    final started = (d['asyncStarted'] as num?)?.toInt() ?? 0;
    final refunded = (d['asyncRefunded'] as num?)?.toInt() ?? 0;
    final used = (started - refunded).clamp(0, 999);
    int limit = weeklyAsyncQuota;
    final config = await _db.doc(FirestorePaths.freeMatchConfig).get();
    final cfg = config.data();
    if (cfg != null && cfg['weeklyAsyncQuota'] is num) {
      limit = (cfg['weeklyAsyncQuota'] as num).toInt();
    }
    return MatchQuotaSnapshot(weekId: weekId, used: used, limit: limit);
  }

  @override
  Future<MatchResult> requestMatch({
    required String userId,
    required String userDisplayName,
    required MatchMode mode,
    List<String> preferredLanguages = const ['English'],
  }) async {
    try {
      final data = await _callables.call('requestMatch', {
        'mode': mode == MatchMode.now ? 'now' : 'async',
        'preferredLanguages': preferredLanguages,
      });
      final sessionId = data['sessionId'] as String?;
      if (sessionId == null) {
        return const MatchError('No session returned');
      }
      final sessionSnap =
          await _db.doc(FirestorePaths.chat(sessionId)).get();
      final d = sessionSnap.data() ?? {};
      final session = ChatSession(
        id: sessionId,
        userId: (d['userId'] as String?) ?? userId,
        listenerId: (d['listenerId'] as String?) ??
            (data['listenerId'] as String? ?? ''),
        startedAt:
            requireTimestamp(d['startedAt'], fallback: DateTime.now()),
        listenerDisplayName: (d['listenerDisplayName'] as String?) ??
            (data['listenerDisplayName'] as String? ?? 'Listener'),
        userDisplayName:
            (d['userDisplayName'] as String?) ?? userDisplayName,
        endedAt: parseTimestamp(d['endedAt']),
      );
      return MatchSuccess(
        session: session,
        quotaCharged: data['quotaCharged'] == true,
        quotaWeekId: data['quotaWeekId'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'resource-exhausted':
          final q = await getQuota(userId);
          return MatchQuotaExceeded(used: q.used, limit: q.limit);
        case 'unavailable':
          return const MatchNoCapacity();
        case 'failed-precondition':
          return const MatchDisabled();
        default:
          return MatchError(e.message ?? e.code);
      }
    } catch (e) {
      return MatchError(e.toString());
    }
  }
}
