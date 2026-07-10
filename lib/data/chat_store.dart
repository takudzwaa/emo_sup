import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';

/// In-memory chat store for the prototype.
///
/// Later: replace body of [sendMessage] / load with Firestore:
/// ```
/// chats/{sessionId}
/// chats/{sessionId}/messages/{messageId}
/// ```
class ChatStore extends ChangeNotifier {
  ChatStore({
    ChatSession? session,
    List<ChatMessage>? seedMessages,
    this.mockListenerReplies = true,
    String? actingAsId,
  })  : session = session ?? ChatStore.defaultSession(),
        _messages = List<ChatMessage>.from(
          seedMessages ?? ChatStore.defaultSeedMessages(),
        ),
        actingAsId = actingAsId ??
            (session ?? ChatStore.defaultSession()).userId;

  /// Who sends messages from this client (user or listener uid).
  final String actingAsId;

  /// Demo session: current user + one assigned listener.
  static ChatSession defaultSession() {
    return ChatSession(
      id: 'session_demo_001',
      userId: 'user_quiet_river',
      listenerId: 'listener_amara_k',
      startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      listenerDisplayName: 'Listener — Amara K.',
    );
  }

  /// Static seed conversation (no backend / no AI).
  static List<ChatMessage> defaultSeedMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'msg_001',
        senderId: 'listener_amara_k',
        text:
            "Hi — I'm here to listen. This is a private space; share only "
            "what feels comfortable.",
        timestamp: now.subtract(const Duration(minutes: 11)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_002',
        senderId: 'user_quiet_river',
        text: "Thanks. It's been a heavy week and I just needed somewhere quiet.",
        timestamp: now.subtract(const Duration(minutes: 9)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_003',
        senderId: 'listener_amara_k',
        text:
            "That makes sense. I'm here with you — take your time. "
            "What's been weighing on you most?",
        timestamp: now.subtract(const Duration(minutes: 8)),
        status: MessageStatus.read,
      ),
    ];
  }

  /// Canned listener lines (supportive, non-clinical). Rotated, not AI-generated.
  static const List<String> _cannedReplies = [
    "I'm glad you shared that. I'm still here.",
    "That sounds like a lot to carry. Thank you for trusting this space.",
    "I'm listening. No pressure to have it all figured out.",
    "It makes sense that you'd feel that way. I'm with you.",
    "Whenever you're ready, I'm here — for as long as this session lasts.",
  ];

  ChatSession session;
  final List<ChatMessage> _messages;
  final bool mockListenerReplies;
  final _random = Random();

  bool _listenerTyping = false;
  Timer? _replyTimer;
  final List<Timer> _statusTimers = [];
  int _idCounter = 100;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListenerTyping => _listenerTyping;
  String get currentUserId => session.userId;
  String get listenerId => session.listenerId;
  bool get isActingAsListener => actingAsId == session.listenerId;

  bool isFromCurrentUser(ChatMessage message) =>
      message.senderId == actingAsId;

  void _setMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    if (_messages[index].status == status) return;
    _messages[index] = _messages[index].copyWith(status: status);
    notifyListeners();
  }

  /// Sends a message as [actingAsId].
  /// Next step: `chats/{sessionId}/messages/{messageId}` write.
  ///
  /// Prototype delivery: sending → sent → delivered via short timers.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !session.isActive) return;

    final localId = 'msg_local_${++_idCounter}';
    final sending = ChatMessage(
      id: localId,
      senderId: actingAsId,
      text: trimmed,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.add(sending);
    notifyListeners();

    // Simulate network ack then delivery (prototype; no real backend).
    _statusTimers.add(
      Timer(const Duration(milliseconds: 150), () {
        _setMessageStatus(localId, MessageStatus.sent);
        _statusTimers.add(
          Timer(const Duration(milliseconds: 200), () {
            _setMessageStatus(localId, MessageStatus.delivered);
          }),
        );
      }),
    );

    // Auto-replies only when the end-user is chatting (prototype mock).
    if (mockListenerReplies && !isActingAsListener) {
      _scheduleMockListenerReply();
    }
  }

  void _scheduleMockListenerReply() {
    _replyTimer?.cancel();
    _listenerTyping = true;
    notifyListeners();

    final delayMs = 900 + _random.nextInt(900);
    _replyTimer = Timer(Duration(milliseconds: delayMs), () {
      _listenerTyping = false;
      final reply = _cannedReplies[_random.nextInt(_cannedReplies.length)];
      _messages.add(
        ChatMessage(
          id: 'msg_listener_${++_idCounter}',
          senderId: session.listenerId,
          text: reply,
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
        ),
      );
      notifyListeners();
    });
  }

  void _cancelStatusTimers() {
    for (final t in _statusTimers) {
      t.cancel();
    }
    _statusTimers.clear();
  }

  void endSession() {
    _replyTimer?.cancel();
    _cancelStatusTimers();
    _listenerTyping = false;
    session = session.copyWith(endedAt: DateTime.now());
    notifyListeners();
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _cancelStatusTimers();
    super.dispose();
  }
}
