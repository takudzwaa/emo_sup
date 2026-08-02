import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_flavor.dart';
import '../domain/repositories/chat_repository.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'repositories/memory_chat_repository.dart';

/// UI-facing chat store (ChangeNotifier façade).
///
/// Persistence via [ChatRepository]. Client-generated message ids for offline
/// idempotent writes (PR 11). Mock listener replies only in prototype flavor.
class ChatStore extends ChangeNotifier {
  ChatStore({
    ChatSession? session,
    List<ChatMessage>? seedMessages,
    bool? mockListenerReplies,
    String? actingAsId,
    ChatRepository? repository,
    Set<String>? blockedPeerIds,
  })  : repository = repository ??
            MemoryChatRepository.withDemoSession(
              session: session,
              seedMessages: seedMessages,
            ),
        mockListenerReplies = mockListenerReplies ?? AppFlavorConfig.isPrototype,
        _blockedPeerIds = blockedPeerIds ?? {},
        session = session ?? MemoryChatRepository.defaultSession(),
        _messages = <ChatMessage>[],
        actingAsId = actingAsId ??
            (session ?? MemoryChatRepository.defaultSession()).userId {
    final repo = this.repository;
    final initial = seedMessages ??
        (repo is MemoryChatRepository && AppFlavorConfig.isPrototype
            ? MemoryChatRepository.defaultSeedMessages()
            : const <ChatMessage>[]);
    _messages.addAll(initial);
    if (repo is MemoryChatRepository) {
      // Prefer messages already written by matchmaking; don't wipe them.
      repo.getMessages(this.session.id).then((existing) {
        if (existing.isNotEmpty) {
          _messages
            ..clear()
            ..addAll(existing);
          notifyListeners();
        } else if (_messages.isNotEmpty) {
          repo.seedSession(this.session, messages: _messages);
        } else {
          repo.seedSession(this.session, messages: const []);
        }
      });
    } else {
      _bindRemoteStreams();
    }
  }

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<ChatSession?>? _sessionSub;

  void _bindRemoteStreams() {
    _messagesSub = repository.watchMessages(session.id).listen((msgs) {
      _messages
        ..clear()
        ..addAll(msgs);
      notifyListeners();
    });
    _sessionSub = repository.watchSession(session.id).listen((s) {
      if (s != null) {
        session = s;
        notifyListeners();
      }
    });
  }

  final ChatRepository repository;

  /// Who sends messages from this client (user or listener uid).
  final String actingAsId;

  /// When true, canned non-clinical replies simulate a listener (prototype only).
  final bool mockListenerReplies;

  /// Peer ids blocked by this user — send is rejected (CF enforce in prod).
  final Set<String> _blockedPeerIds;

  static ChatSession defaultSession() => MemoryChatRepository.defaultSession();

  static List<ChatMessage> defaultSeedMessages() =>
      MemoryChatRepository.defaultSeedMessages();

  static const List<String> _cannedReplies = [
    "I'm glad you shared that. I'm still here.",
    "That sounds like a lot to carry. Thank you for trusting this space.",
    "I'm listening. No pressure to have it all figured out.",
    "It makes sense that you'd feel that way. I'm with you.",
    "Whenever you're ready, I'm here — for as long as this session lasts.",
  ];

  ChatSession session;
  final List<ChatMessage> _messages;
  final _random = Random();

  bool _listenerTyping = false;
  Timer? _replyTimer;
  final List<Timer> _statusTimers = [];
  int _idCounter = 100;

  /// Optional force-fail next send (tests).
  bool debugForceNextSendFail = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListenerTyping => _listenerTyping;
  String get currentUserId => session.userId;
  String get listenerId => session.listenerId;
  bool get isActingAsListener => actingAsId == session.listenerId;

  bool isFromCurrentUser(ChatMessage message) =>
      message.senderId == actingAsId;

  /// Client-generated idempotent message id (PR 11 offline model).
  String _newClientMessageId() {
    final t = DateTime.now().microsecondsSinceEpoch;
    final n = ++_idCounter;
    final r = _random.nextInt(1 << 20);
    return 'msg_${t.toRadixString(36)}_$n$r';
  }

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

  /// Sends a message as [actingAsId] with client-generated id.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !session.isActive) return;

    final peerId = isActingAsListener ? session.userId : session.listenerId;
    if (_blockedPeerIds.contains(peerId)) {
      // Authoritative reject in prod is CF onMessageCreate; client soft-block.
      return;
    }

    final localId = _newClientMessageId();
    final sending = ChatMessage(
      id: localId,
      senderId: actingAsId,
      text: trimmed,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.add(sending);
    notifyListeners();

    if (debugForceNextSendFail) {
      debugForceNextSendFail = false;
      _setMessageStatus(localId, MessageStatus.failed);
      return;
    }

    try {
      await repository.sendMessage(
        sessionId: session.id,
        senderId: actingAsId,
        text: trimmed,
        clientMessageId: localId,
      );

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
    } catch (_) {
      _setMessageStatus(localId, MessageStatus.failed);
    }
  }

  /// Retry a failed message reusing the same client id (PR 11).
  Future<void> retryMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final existing = _messages[index];
    if (existing.status != MessageStatus.failed) return;
    if (existing.senderId != actingAsId) return;

    _messages[index] = existing.copyWith(status: MessageStatus.sending);
    notifyListeners();

    try {
      await repository.sendMessage(
        sessionId: session.id,
        senderId: actingAsId,
        text: existing.text,
        clientMessageId: existing.id,
      );
      _setMessageStatus(messageId, MessageStatus.sent);
      _statusTimers.add(
        Timer(const Duration(milliseconds: 200), () {
          _setMessageStatus(messageId, MessageStatus.delivered);
        }),
      );
    } catch (_) {
      _setMessageStatus(messageId, MessageStatus.failed);
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
        id: _newClientMessageId(),
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
    _messagesSub?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }
}
