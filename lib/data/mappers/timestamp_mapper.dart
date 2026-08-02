import 'package:cloud_firestore/cloud_firestore.dart';

/// Parse Firestore [Timestamp], ISO string, or null → [DateTime].
DateTime? parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

DateTime requireTimestamp(dynamic value, {DateTime? fallback}) {
  return parseTimestamp(value) ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

Timestamp toTimestamp(DateTime dt) => Timestamp.fromDate(dt);
