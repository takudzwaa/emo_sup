import 'package:flutter/material.dart';

import '../data/chat_store.dart';
import '../data/listener_dashboard_store.dart';
import '../widgets/anonymous_avatar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/safety_quick_access_bar.dart';
import '../widgets/soft_surface.dart';
import '../widgets/typing_indicator.dart';
import 'safety_privacy_screen.dart';

/// Who is using the chat UI in this instance.
enum ChatPerspective {
  /// End-user talking to a listener.
  endUser,

  /// Vetted listener talking to an anonymous user.
  listener,
}

/// 1:1 text chat (mock messages for the prototype).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.chatStore,
    this.perspective = ChatPerspective.endUser,
    this.onEscalate,
  });

  /// Optional inject for tests; creates a seeded store if null.
  final ChatStore? chatStore;

  final ChatPerspective perspective;

  /// Listener-side escalation. Defaults to a local stub dialog when null.
  final Future<void> Function()? onEscalate;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatStore _store;
  late final bool _ownsStore;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _scrollController = ScrollController();

  /// Message id whose timestamp is visible after long-press.
  String? _timestampMessageId;

  bool get _isListener => widget.perspective == ChatPerspective.listener;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.chatStore == null;
    _store = widget.chatStore ??
        ChatStore(
          mockListenerReplies: !_isListener,
          actingAsId: _isListener
              ? ChatStore.defaultSession().listenerId
              : ChatStore.defaultSession().userId,
        );
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    if (_ownsStore) {
      _store.dispose();
    }
    _inputController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    setState(() => _timestampMessageId = null);
    await _store.sendMessage(text);
  }

  void _openCrisisResources() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SafetyPrivacyScreen(
          initialSection: SafetyHubSection.crisisResources,
        ),
      ),
    );
  }

  void _openReportBlock() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SafetyPrivacyScreen(
          initialSection: SafetyHubSection.reportBlock,
        ),
      ),
    );
  }

  Future<void> _confirmEndSession() async {
    final scheme = Theme.of(context).colorScheme;
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('End this session?'),
          content: Text(
            _isListener
                ? 'The person can start a new conversation later. '
                    'This ends the current private session only.'
                : 'You can start a new conversation anytime from Home. '
                    'This ends the current private session only.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep talking'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              child: const Text('End session'),
            ),
          ],
        );
      },
    );

    if (shouldEnd == true && mounted) {
      _store.endSession();
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop();
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Session ended'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _escalate() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Escalate this chat?'),
          content: const Text(
            'Use escalate when someone may be at risk of harm. '
            'Do not diagnose. A safety reviewer will be notified '
            '(prototype: confirmation only).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Go back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Escalate now'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Real escalation / on-call notification hooks in here.
    // See ListenerDashboardStore.escalateChat for the intended backend path.
    if (widget.onEscalate != null) {
      await widget.onEscalate!();
    } else {
      await ListenerDashboardStore().escalateChat(
        sessionId: _store.session.id,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Escalation recorded (prototype). Support will follow up.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onOverflowSelected(String value) {
    switch (value) {
      case 'report':
        _openReportBlock();
      case 'end':
        _confirmEndSession();
      case 'escalate':
        _escalate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final session = _store.session;
    final messages = _store.messages;

    final peerName = _isListener
        ? session.userDisplayName
        : session.listenerDisplayName;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            AnonymousAvatar(displayName: peerName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  const TrustChip(
                    label: 'Encrypted',
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isListener)
            TextButton(
              onPressed: _escalate,
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                minimumSize: const Size(48, 48),
              ),
              child: const Text('Escalate'),
            ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: _onOverflowSelected,
            itemBuilder: (context) => [
              if (_isListener)
                const PopupMenuItem(
                  value: 'escalate',
                  child: Text('Escalate'),
                ),
              if (!_isListener)
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report & block'),
                ),
              const PopupMenuItem(
                value: 'end',
                child: Text('End session'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isListener ? 40 : 40),
          child: _isListener
              ? const _ListenerSafetyStrip()
              : _CrisisHelpBanner(onTap: _openCrisisResources),
        ),
      ),
      body: SoftGradientBackground(
        child: Column(
          children: [
            _SessionPrivacyBanner(peerName: peerName),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _timestampMessageId = null);
                },
                behavior: HitTestBehavior.opaque,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: messages.length +
                      (_store.isListenerTyping && !_isListener ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const TypingIndicator();
                    }
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMine: _store.isFromCurrentUser(message),
                      showTimestamp: _timestampMessageId == message.id,
                      onLongPress: () {
                        setState(() {
                          _timestampMessageId =
                              _timestampMessageId == message.id
                                  ? null
                                  : message.id;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
            ChatInputBar(
              controller: _inputController,
              focusNode: _inputFocus,
              onSend: _send,
              enabled: session.isActive,
            ),
            if (!_isListener) const SafetyQuickAccessBar(),
          ],
        ),
      ),
    );
  }
}

/// Soft strip reinforcing private 1:1 session context.
class _SessionPrivacyBanner extends StatelessWidget {
  const _SessionPrivacyBanner({required this.peerName});

  final String peerName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SoftCard(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      child: Row(
        children: [
          Expanded(
            child: Text(
              "You're in a private session with $peerName",
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const TrustChip(
            label: 'Private',
            compact: true,
          ),
        ],
      ),
    );
  }
}

/// Unobtrusive one-tap entry to crisis resources (not an interrupting popup).
class _CrisisHelpBanner extends StatelessWidget {
  const _CrisisHelpBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.secondary.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 15,
                color: scheme.secondary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Need urgent help?',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Crisis resources',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: scheme.primary.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Listener-side strip reinforcing non-clinical boundaries.
class _ListenerSafetyStrip extends StatelessWidget {
  const _ListenerSafetyStrip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Never diagnose. Escalate if there is risk of harm.',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
