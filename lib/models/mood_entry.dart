/// A single mood check-in.
///
/// Structured for a later Firestore write, e.g.:
/// ```dart
/// firestore.collection('mood_entries').add(entry.toMap());
/// ```
class MoodEntry {
  const MoodEntry({
    required this.timestamp,
    required this.value,
  });

  /// When the check-in was recorded.
  final DateTime timestamp;

  /// Mood intensity from 1 (very low) to 5 (great).
  final int value;

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      // Future Firestore: prefer Timestamp.fromDate(timestamp)
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      value: map['value'] as int,
    );
  }

  @override
  String toString() => 'MoodEntry(timestamp: $timestamp, value: $value)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MoodEntry &&
            runtimeType == other.runtimeType &&
            timestamp == other.timestamp &&
            value == other.value;
  }

  @override
  int get hashCode => Object.hash(timestamp, value);
}
