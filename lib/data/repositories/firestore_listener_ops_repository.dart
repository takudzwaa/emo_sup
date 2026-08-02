import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/listener_ops_repository.dart';
import '../../models/active_chat_summary.dart';
import '../firebase/callable_client.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreListenerOpsRepository implements ListenerOpsRepository {
  FirestoreListenerOpsRepository({
    FirebaseFirestore? firestore,
    CallableClient? callables,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _callables = callables ?? CallableClient();

  final FirebaseFirestore _db;
  final CallableClient _callables;

  ActiveChatSummary _chatFrom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return ActiveChatSummary(
      sessionId: snap.id,
      userId: (d['userId'] as String?) ?? '',
      userAnonymousName: (d['userDisplayName'] as String?) ?? 'Anonymous',
      lastMessagePreview: (d['lastMessagePreview'] as String?) ?? '',
      lastMessageAt:
          requireTimestamp(d['lastMessageAt'], fallback: DateTime.now()),
      unreadCount: (d['listenerUnreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<bool> getAvailableNow(String listenerId) async {
    final snap = await _db.doc(FirestorePaths.listener(listenerId)).get();
    return snap.data()?['availableNow'] == true;
  }

  @override
  Future<void> setAvailableNow(String listenerId, bool value) async {
    await _callables.call('setListenerAvailability', {
      'availableNow': value,
    });
  }

  @override
  Stream<bool> watchAvailableNow(String listenerId) {
    return _db.doc(FirestorePaths.listener(listenerId)).snapshots().map(
          (s) => s.data()?['availableNow'] == true,
        );
  }

  @override
  Future<List<ActiveChatSummary>> listActiveChats(String listenerId) async {
    final snap = await _db
        .collection(FirestorePaths.chats)
        .where('listenerId', isEqualTo: listenerId)
        .where('status', isEqualTo: 'active')
        .get();
    final list = snap.docs.map(_chatFrom).toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return list;
  }

  @override
  Stream<List<ActiveChatSummary>> watchActiveChats(String listenerId) {
    return _db
        .collection(FirestorePaths.chats)
        .where('listenerId', isEqualTo: listenerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((s) {
      final list = s.docs.map(_chatFrom).toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  @override
  Future<List<ListenerBookingSummary>> listUpcomingBookings(
    String listenerId,
  ) async {
    final snap = await _db
        .collection(FirestorePaths.bookings)
        .where('listenerId', isEqualTo: listenerId)
        .where('status', isEqualTo: 'confirmed')
        .get();
    final list = <ListenerBookingSummary>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final userId = (d['userId'] as String?) ?? '';
      String name = 'Anonymous';
      if (userId.isNotEmpty) {
        final user = await _db.doc(FirestorePaths.user(userId)).get();
        name = (user.data()?['anonymousName'] as String?) ?? name;
      }
      list.add(
        ListenerBookingSummary(
          bookingId: doc.id,
          userId: userId,
          userAnonymousName: name,
          slotStart:
              requireTimestamp(d['slotStart'], fallback: DateTime.now()),
        ),
      );
    }
    list.sort((a, b) => a.slotStart.compareTo(b.slotStart));
    return list;
  }

  @override
  Future<void> markChatRead(String listenerId, String sessionId) async {
    await _db.doc(FirestorePaths.chat(sessionId)).set({
      'listenerUnreadCount': 0,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> escalateChat({
    required String sessionId,
    required String listenerId,
    String reason = 'listener_escalation',
  }) async {
    try {
      await _callables.call('escalateChat', {
        'sessionId': sessionId,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }
}
