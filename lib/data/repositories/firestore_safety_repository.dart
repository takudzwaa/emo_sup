import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/safety_repository.dart';
import '../firebase/callable_client.dart';
import '../firebase/firestore_paths.dart';

class FirestoreSafetyRepository implements SafetyRepository {
  FirestoreSafetyRepository({
    FirebaseFirestore? firestore,
    CallableClient? callables,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _callables = callables ?? CallableClient();

  final FirebaseFirestore _db;
  final CallableClient _callables;
  final List<SafetyInboxEvent> _localInbox = [];

  @override
  List<SafetyInboxEvent> get safetyInbox => List.unmodifiable(_localInbox);

  void _pushLocal(String kind, String summary) {
    _localInbox.add(
      SafetyInboxEvent(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
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
    final ref = _db.collection(FirestorePaths.reports).doc();
    await ref.set({
      'id': ref.id,
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'details': ?details,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _pushLocal('report', 'Report on $targetType/$targetId: $reason');
  }

  @override
  Future<BlockResult> blockTarget({
    required String blockerId,
    required String blockedId,
  }) async {
    final blockId = '${blockerId}_$blockedId';
    await _db.collection(FirestorePaths.blocks).doc(blockId).set({
      'id': blockId,
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Soft-end active chats between the pair.
    final asUser = await _db
        .collection(FirestorePaths.chats)
        .where('userId', isEqualTo: blockerId)
        .where('listenerId', isEqualTo: blockedId)
        .where('status', isEqualTo: 'active')
        .get();
    final asListener = await _db
        .collection(FirestorePaths.chats)
        .where('userId', isEqualTo: blockedId)
        .where('listenerId', isEqualTo: blockerId)
        .where('status', isEqualTo: 'active')
        .get();
    var ended = 0;
    final batch = _db.batch();
    for (final d in [...asUser.docs, ...asListener.docs]) {
      batch.set(d.reference, {
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      ended++;
    }
    if (ended > 0) await batch.commit();
    _pushLocal('block', 'Block $blockerId → $blockedId');
    return BlockResult(blockId: blockId, sessionsEnded: ended);
  }

  @override
  Future<void> escalateChat({
    required String sessionId,
    required String listenerId,
    String reason = 'listener_escalation',
  }) async {
    await _callables.call('escalateChat', {
      'sessionId': sessionId,
      'reason': reason,
    });
    _pushLocal('escalate', 'Escalated $sessionId');
  }

  @override
  Future<DeleteMyDataResult> requestDeleteMyData(String userId) async {
    try {
      final data = await _callables.call('deleteMyData');
      final result = DeleteMyDataResult(
        userId: userId,
        requestedAt: DateTime.now(),
        messagesScrubbed: (data['messagesScrubbed'] as num?)?.toInt() ?? 0,
        sessionsUnlinked: (data['sessionsUnlinked'] as num?)?.toInt() ?? 0,
        tokensCleared: (data['tokensCleared'] as num?)?.toInt() ?? 0,
        quotaDocsRemoved: (data['quotaDocsRemoved'] as num?)?.toInt() ?? 0,
      );
      _pushLocal('delete_request', 'Delete requested for $userId');
      return result;
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }
}
