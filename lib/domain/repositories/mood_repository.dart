import '../../models/mood_entry.dart';

/// I/O for mood check-ins: `users/{uid}/mood_entries/{entryId}`.
abstract class MoodRepository {
  Future<List<MoodEntry>> listEntries(String userId, {int limit = 50});

  Future<MoodEntry?> latest(String userId);

  Future<MoodEntry> add({
    required String userId,
    required int value,
    DateTime? timestamp,
  });

  Future<void> clear(String userId);
}
