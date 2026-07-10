import 'package:flutter/foundation.dart';

import '../models/mood_entry.dart';

/// Local in-memory mood store for the prototype.
///
/// Swap the body of [add] / [latest] for Firestore reads/writes later
/// without changing call sites on the Home screen.
class MoodStore extends ChangeNotifier {
  MoodStore();

  final List<MoodEntry> _entries = <MoodEntry>[];

  List<MoodEntry> get entries => List.unmodifiable(_entries);

  MoodEntry? get latest => _entries.isEmpty ? null : _entries.last;

  /// Records a new mood value (1–5) with the current timestamp.
  MoodEntry add(int value) {
    assert(value >= 1 && value <= 5, 'Mood value must be between 1 and 5');
    final entry = MoodEntry(timestamp: DateTime.now(), value: value);
    _entries.add(entry);
    // Next step: await firestore.collection('mood_entries').add(entry.toMap());
    notifyListeners();
    return entry;
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
