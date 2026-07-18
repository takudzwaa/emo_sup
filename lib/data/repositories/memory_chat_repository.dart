import 'dart:async';

import '../../domain/repositories/chat_repository.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

/// In-memory chat I/O for prototype + tests.
///
/// UI-facing delivery timers / mock replies stay in [ChatStore].
class MemoryChatRepository implements ChatRepository {
  MemoryChatRepository({
    Map<String, ChatSession>? sessions,
    Map<String, List<ChatMessage>>? messages,
  })  : _sessions = Map<String, ChatSession>.from(sessions ?? {}),
        _messages = {
          for (final e in (messages ?? {}).entries)
            e.key: List<ChatMessage>.from(e.value),
        };

  final Map<String, ChatSession> _sessions;
  final Map<String, List<ChatMessage>> _messages;
  final _sessionControllers = <String, StreamController<ChatSession?>>{};
  final _messageControllers = <String, StreamController<List<ChatMessage>>>{};

  /// Seeds a demo session matching historical [ChatStore] defaults.
  factory MemoryChatRepository.withDemoSession({
    ChatSession? session,
    List<ChatMessage>? seedMessages,
  }) {
    final s = session ?? MemoryChatRepository.defaultSession();
    final msgs = seedMessages ?? MemoryChatRepository.defaultSeedMessages();
    return MemoryChatRepository(
      sessions: {s.id: s},
      messages: {s.id: msgs},
    );
  }

  static ChatSession defaultSession() {
    return ChatSession(
      id: 'session_demo_001',
      userId: 'user_quiet_river',
      listenerId: 'listener_amara_k',
      startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      listenerDisplayName: 'Listener — Amara K.',
    );
  }

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
        text:
            "Thanks. It's been a heavy week and I just needed somewhere quiet.",
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

  List<ChatMessage> _msgList(String sessionId) =>
      _messages.putIfAbsent(sessionId, () => <ChatMessage>[]);

  void _emitSession(String sessionId) {
    final c = _sessionControllers[sessionId];
    if (c != null && !c.isClosed) {
      c.add(_sessions[sessionId]);
    }
  }

  void _emitMessages(String sessionId) {
    final c = _messageControllers[sessionId];
    if (c != null && !c.isClosed) {
      c.add(List.unmodifiable(_msgList(sessionId)));
    }
  }

  @override
  Stream<ChatSession?> watchSession(String sessionId) {
    final controller = _sessionControllers.putIfAbsent(
      sessionId,
      () => StreamController<ChatSession?>.broadcast(),
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(_sessions[sessionId]);
    });
    return controller.stream;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String sessionId, {int limit = 100}) {
    final controller = _messageControllers.putIfAbsent(
      sessionId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        final all = _msgList(sessionId);
        final slice =
            all.length <= limit ? all : all.sublist(all.length - limit);
        controller.add(List.unmodifiable(slice));
      }
    });
    return controller.stream;
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async =>
      _sessions[sessionId];

  @override
  Future<List<ChatMessage>> getMessages(
    String sessionId, {
    int limit = 100,
  }) async {
    final all = _msgList(sessionId);
    if (all.length <= limit) return List.unmodifiable(all);
    return List.unmodifiable(all.sublist(all.length - limit));
  }

  @override
  Future<void> sendMessage({
    required String sessionId,
    required String senderId,
    required String text,
    required String clientMessageId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final list = _msgList(sessionId);
    final existing = list.indexWhere((m) => m.id == clientMessageId);
    final message = ChatMessage(
      id: clientMessageId,
      senderId: senderId,
      text: trimmed,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    if (existing >= 0) {
      list[existing] = message;
    } else {
      list.add(message);
    }
    _emitMessages(sessionId);
  }

  /// Prototype helper: seed or replace a full session + messages.
  void seedSession(ChatSession session, {List<ChatMessage>? messages}) {
    _sessions[session.id] = session;
    if (messages != null) {
      _messages[session.id] = List<ChatMessage>.from(messages);
    }
    _emitSession(session.id);
    _emitMessages(session.id);
  }

  /// Append a message without idempotent client id (mock listener replies).
  Future<void> appendMessage(String sessionId, ChatMessage message) async {
    _msgList(sessionId).add(message);
    _emitMessages(sessionId);
  }

  @override
  Future<void> updateMessageStatus({
    required String sessionId,
    required String messageId,
    required MessageStatus status,
  }) async {
    final list = _msgList(sessionId);
    final index = list.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    if (list[index].status == status) return;
    list[index] = list[index].copyWith(status: status);
    _emitMessages(sessionId);
  }

  @override
  Future<void> endSession(String sessionId) async {
    final existing = _sessions[sessionId];
    if (existing == null) return;
    _sessions[sessionId] = existing.copyWith(endedAt: DateTime.now());
    _emitSession(sessionId);
  }

  @override
  Future<void> markRead(String sessionId) async {
    final list = _msgList(sessionId);
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      if (list[i].status != MessageStatus.read) {
        list[i] = list[i].copyWith(status: MessageStatus.read);
        changed = true;
      }
    }
    if (changed) _emitMessages(sessionId);
  }
}
