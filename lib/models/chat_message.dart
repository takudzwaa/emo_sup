/// Delivery status for a chat message (prototype; refine when wiring FCM).
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// A single text message in a 1:1 chat session.
///
/// Firestore (later):
/// ```
/// chats/{sessionId}/messages/{messageId}
/// ```
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      // Future Firestore: prefer Timestamp.fromDate(timestamp)
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatMessage &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            senderId == other.senderId &&
            text == other.text &&
            timestamp == other.timestamp &&
            status == other.status;
  }

  @override
  int get hashCode => Object.hash(id, senderId, text, timestamp, status);
}
