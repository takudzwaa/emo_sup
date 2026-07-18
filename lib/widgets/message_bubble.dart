import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';

/// Chat bubble: user right-aligned, listener left-aligned.
/// Timestamp is shown only while the bubble is selected via long-press.
/// Own messages show delivery status ticks (prototype cue only).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.showTimestamp,
    required this.onLongPress,
    this.onRetry,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTimestamp;
  final VoidCallback onLongPress;

  /// Shown when [message] is [MessageStatus.failed] and is mine (PR 11).
  final VoidCallback? onRetry;

  static String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }

  /// Prototype delivery ticks for own messages.
  static String statusTick(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return '…';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
      case MessageStatus.read:
        return '✓✓';
      case MessageStatus.failed:
        return '!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;

    final bubbleColor = isMine
        ? null
        : (isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9));
    final textColor = isMine ? scheme.onPrimary : scheme.onSurface;
    final tickStyle = textTheme.bodySmall?.copyWith(
      fontSize: 11,
      height: 1,
      letterSpacing: 0.2,
      color: scheme.onPrimary.withValues(alpha: 0.55),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.selectionClick();
          onLongPress();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: isMine ? AppTheme.primaryGradient(scheme) : null,
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 5),
                    bottomRight: Radius.circular(isMine ? 5 : 18),
                  ),
                  border: isMine
                      ? null
                      : Border.all(
                          color: scheme.outline.withValues(alpha: 0.14),
                        ),
                  boxShadow: isMine
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : AppTheme.softShadow(scheme, intensity: 0.55),
                ),
                child: isMine
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              message.text,
                              style: textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusTick(message.status),
                            style: tickStyle,
                          ),
                        ],
                      )
                    : Text(
                        message.text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: showTimestamp
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: 6,
                          right: 6,
                          bottom: 4,
                        ),
                        child: Text(
                          formatTime(message.timestamp),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (isMine &&
                  message.status == MessageStatus.failed &&
                  onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: scheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Tap to retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
