import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/chat_repository.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  ChatSession _sessionFrom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return ChatSession(
      id: (d['id'] as String?) ?? snap.id,
      userId: (d['userId'] as String?) ?? '',
      listenerId: (d['listenerId'] as String?) ?? '',
      startedAt: requireTimestamp(d['startedAt'], fallback: DateTime.now()),
      listenerDisplayName:
          (d['listenerDisplayName'] as String?) ?? 'Listener',
      userDisplayName: (d['userDisplayName'] as String?) ?? 'Anonymous',
      endedAt: parseTimestamp(d['endedAt']),
    );
  }

  ChatMessage _messageFrom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return ChatMessage(
      id: (d['id'] as String?) ?? snap.id,
      senderId: (d['senderId'] as String?) ?? '',
      text: (d['text'] as String?) ?? '',
      timestamp: requireTimestamp(d['timestamp'], fallback: DateTime.now()),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  @override
  Stream<ChatSession?> watchSession(String sessionId) {
    return _db.doc(FirestorePaths.chat(sessionId)).snapshots().map((s) {
      if (!s.exists) return null;
      return _sessionFrom(s);
    });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String sessionId, {int limit = 100}) {
    return _db
        .collection(FirestorePaths.messages(sessionId))
        .orderBy('timestamp')
        .limitToLast(limit)
        .snapshots()
        .map((s) => s.docs.map(_messageFrom).toList());
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async {
    final snap = await _db.doc(FirestorePaths.chat(sessionId)).get();
    if (!snap.exists) return null;
    return _sessionFrom(snap);
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String sessionId, {
    int limit = 100,
  }) async {
    final snap = await _db
        .collection(FirestorePaths.messages(sessionId))
        .orderBy('timestamp')
        .limitToLast(limit)
        .get();
    return snap.docs.map(_messageFrom).toList();
  }

  @override
  Future<void> sendMessage({
    required String sessionId,
    required String senderId,
    required String text,
    required String clientMessageId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final ref = _db
        .collection(FirestorePaths.messages(sessionId))
        .doc(clientMessageId);
    await ref.set({
      'id': clientMessageId,
      'senderId': senderId,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'status': MessageStatus.sent.name,
    });
  }

  @override
  Future<void> updateMessageStatus({
    required String sessionId,
    required String messageId,
    required MessageStatus status,
  }) async {
    await _db
        .collection(FirestorePaths.messages(sessionId))
        .doc(messageId)
        .set({'status': status.name}, SetOptions(merge: true));
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _db.doc(FirestorePaths.chat(sessionId)).set({
      'endedAt': FieldValue.serverTimestamp(),
      'status': 'ended',
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markRead(String sessionId) async {
    final snap = await _db
        .collection(FirestorePaths.messages(sessionId))
        .where('status', whereIn: ['sent', 'delivered'])
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.set(d.reference, {'status': 'read'}, SetOptions(merge: true));
    }
    await batch.commit();
    await _db.doc(FirestorePaths.chat(sessionId)).set({
      'userUnreadCount': 0,
      'listenerUnreadCount': 0,
    }, SetOptions(merge: true));
  }
}
