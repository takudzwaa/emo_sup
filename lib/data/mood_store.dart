import 'package:flutter/foundation.dart';

import '../domain/repositories/mood_repository.dart';
import '../models/mood_entry.dart';
import 'repositories/memory_mood_repository.dart';

/// UI-facing mood store (ChangeNotifier façade).
///
/// I/O goes through [MoodRepository]. Default is [MemoryMoodRepository].
class MoodStore extends ChangeNotifier {
  MoodStore({
    MoodRepository? repository,
    this.userId = 'local_user',
  }) : repository = repository ?? MemoryMoodRepository();

  final MoodRepository repository;
  final String userId;

  final List<MoodEntry> _entries = <MoodEntry>[];

  List<MoodEntry> get entries => List.unmodifiable(_entries);

  MoodEntry? get latest => _entries.isEmpty ? null : _entries.last;

  /// Records a new mood value (1–5) with the current timestamp.
  MoodEntry add(int value) {
    assert(value >= 1 && value <= 5, 'Mood value must be between 1 and 5');
    final entry = MoodEntry(timestamp: DateTime.now(), value: value);
    _entries.add(entry);
    // Fire-and-forget I/O; memory repo is sync-fast. Firestore will await.
    repository.add(userId: userId, value: value, timestamp: entry.timestamp);
    notifyListeners();
    return entry;
  }

  void clear() {
    _entries.clear();
    repository.clear(userId);
    notifyListeners();
  }
}
