import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

/// I/O for 1:1 chat sessions and messages.
///
/// Firestore (prod): `chats/{sessionId}`, `chats/{sessionId}/messages/{id}`.
/// Session create is server-authoritative in production (Cloud Function).
abstract class ChatRepository {
  Stream<ChatSession?> watchSession(String sessionId);

  Stream<List<ChatMessage>> watchMessages(String sessionId, {int limit = 100});

  Future<ChatSession?> getSession(String sessionId);

  Future<List<ChatMessage>> getMessages(String sessionId, {int limit = 100});

  /// Idempotent write: [clientMessageId] is the document id.
  Future<void> sendMessage({
    required String sessionId,
    required String senderId,
    required String text,
    required String clientMessageId,
  });

  Future<void> updateMessageStatus({
    required String sessionId,
    required String messageId,
    required MessageStatus status,
  });

  Future<void> endSession(String sessionId);

  Future<void> markRead(String sessionId);
}
