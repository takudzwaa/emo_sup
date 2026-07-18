import 'dart:async';

import '../../domain/repositories/mood_repository.dart';
import '../../models/mood_entry.dart';

/// In-memory mood entries for prototype + tests.
class MemoryMoodRepository implements MoodRepository {
  MemoryMoodRepository({Map<String, List<MoodEntry>>? seed})
      : _byUser = {
          for (final e in (seed ?? {}).entries)
            e.key: List<MoodEntry>.from(e.value),
        };

  final Map<String, List<MoodEntry>> _byUser;
  final _controllers = <String, StreamController<List<MoodEntry>>>{};

  List<MoodEntry> _list(String userId) =>
      _byUser.putIfAbsent(userId, () => <MoodEntry>[]);

  void _emit(String userId) {
    final c = _controllers[userId];
    if (c != null && !c.isClosed) {
      c.add(List.unmodifiable(_list(userId)));
    }
  }

  @override
  Future<List<MoodEntry>> listEntries(String userId, {int limit = 50}) async {
    final all = _list(userId);
    if (all.length <= limit) return List.unmodifiable(all);
    return List.unmodifiable(all.sublist(all.length - limit));
  }

  @override
  Future<MoodEntry?> latest(String userId) async {
    final all = _list(userId);
    return all.isEmpty ? null : all.last;
  }

  @override
  Future<MoodEntry> add({
    required String userId,
    required int value,
    DateTime? timestamp,
  }) async {
    assert(value >= 1 && value <= 5, 'Mood value must be between 1 and 5');
    final entry = MoodEntry(
      timestamp: timestamp ?? DateTime.now(),
      value: value,
    );
    _list(userId).add(entry);
    _emit(userId);
    return entry;
  }

  @override
  Future<void> clear(String userId) async {
    _list(userId).clear();
    _emit(userId);
  }
}
