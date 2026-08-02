import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/mood_repository.dart';
import '../../models/mood_entry.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreMoodRepository implements MoodRepository {
  FirestoreMoodRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection(FirestorePaths.moodEntries(userId));

  MoodEntry _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MoodEntry(
      timestamp: requireTimestamp(d['timestamp'], fallback: DateTime.now()),
      value: (d['value'] as num?)?.toInt() ?? 3,
    );
  }

  @override
  Future<List<MoodEntry>> listEntries(String userId, {int limit = 50}) async {
    final snap = await _col(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_fromDoc).toList().reversed.toList();
  }

  @override
  Future<MoodEntry?> latest(String userId) async {
    final snap = await _col(userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  @override
  Future<MoodEntry> add({
    required String userId,
    required int value,
    DateTime? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now();
    final entry = MoodEntry(timestamp: ts, value: value);
    await _col(userId).add({
      'timestamp': toTimestamp(ts),
      'value': value,
    });
    await _db.doc(FirestorePaths.user(userId)).set({
      'lastMoodValue': value,
      'lastMoodAt': toTimestamp(ts),
    }, SetOptions(merge: true));
    return entry;
  }

  @override
  Future<void> clear(String userId) async {
    final snap = await _col(userId).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
