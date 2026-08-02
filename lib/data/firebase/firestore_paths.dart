/// Collection / document paths matching docs/firestore_schema.md.
class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const listenerPublic = 'listener_public';
  static const listeners = 'listeners';
  static const chats = 'chats';
  static const bookings = 'bookings';
  static const payments = 'payments';
  static const memberships = 'memberships';
  static const reports = 'reports';
  static const blocks = 'blocks';
  static const safetyInbox = 'safety_inbox';
  static const config = 'config';

  static String user(String uid) => '$users/$uid';
  static String moodEntries(String uid) => '$users/$uid/mood_entries';
  static String matchQuota(String uid) => '$users/$uid/match_quota';
  static String fcmTokens(String uid) => '$users/$uid/fcm_tokens';
  static String listener(String id) => '$listeners/$id';
  static String listenerAvailability(String id) =>
      '$listeners/$id/availability';
  static String chat(String sessionId) => '$chats/$sessionId';
  static String messages(String sessionId) => '$chats/$sessionId/messages';
  static String booking(String id) => '$bookings/$id';
  static String membership(String uid) => '$memberships/$uid';
  static String freeMatchConfig = '$config/free_match';
}
