import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/repositories/chat_repository.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'repositories/memory_chat_repository.dart';

/// UI-facing chat store (ChangeNotifier façade).
///
/// Persistence via [ChatRepository]. Mock listener replies stay here for
/// the prototype flavor only.
class ChatStore extends ChangeNotifier {
  ChatStore({
    ChatSession? session,
    List<ChatMessage>? seedMessages,
    this.mockListenerReplies = true,
    String? actingAsId,
    ChatRepository? repository,
  })  : repository = repository ??
            MemoryChatRepository.withDemoSession(
              session: session,
              seedMessages: seedMessages,
            ),
        session = session ?? MemoryChatRepository.defaultSession(),
        _messages = List<ChatMessage>.from(
          seedMessages ?? MemoryChatRepository.defaultSeedMessages(),
        ),
        actingAsId = actingAsId ??
            (session ?? MemoryChatRepository.defaultSession()).userId {
    // Keep memory repo in sync when custom session/messages were passed.
    final repo = this.repository;
    if (repo is MemoryChatRepository) {
      repo.seedSession(this.session, messages: _messages);
    }
  }

  final ChatRepository repository;

  /// Who sends messages from this client (user or listener uid).
  final String actingAsId;

  /// Demo session helper (tests / screens).
  static ChatSession defaultSession() => MemoryChatRepository.defaultSession();

  static List<ChatMessage> defaultSeedMessages() =>
      MemoryChatRepository.defaultSeedMessages();

  /// Canned listener lines (supportive, non-clinical). Rotated, not AI.
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
    repository.updateMessageStatus(
      sessionId: session.id,
      messageId: messageId,
      status: status,
    );
    notifyListeners();
  }

  /// Sends a message as [actingAsId].
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

    await repository.sendMessage(
      sessionId: session.id,
      senderId: actingAsId,
      text: trimmed,
      clientMessageId: localId,
    );

    // Prototype delivery: sending → sent → delivered via short timers.
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
      final message = ChatMessage(
        id: 'msg_listener_${++_idCounter}',
        senderId: session.listenerId,
        text: reply,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
      );
      _messages.add(message);
      final repo = repository;
      if (repo is MemoryChatRepository) {
        repo.appendMessage(session.id, message);
      } else {
        repository.sendMessage(
          sessionId: session.id,
          senderId: session.listenerId,
          text: reply,
          clientMessageId: message.id,
        );
      }
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
    repository.endSession(session.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _cancelStatusTimers();
    super.dispose();
  }
}
