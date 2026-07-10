import 'package:flutter/material.dart';

/// Text field + send only. No emoji picker, attachments, or voice.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? scheme.surface.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.88),
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: enabled
                        ? 'Write a message…'
                        : 'This chat has ended',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? scheme.surfaceContainerHighest.withValues(alpha: 0.7)
                        : scheme.surface.withValues(alpha: 0.95),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.22),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: scheme.primary.withValues(alpha: 0.55),
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  onSubmitted: enabled ? (_) => onSend() : null,
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;
                  final canSend = enabled && hasText;
                  return Container(
                    decoration: canSend
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          )
                        : null,
                    child: IconButton.filled(
                      key: const Key('chat_send_button'),
                      tooltip: 'Send',
                      // Always attach handler when session is active so tests and
                      // rapid taps work; empty text is ignored in ChatStore.
                      onPressed: enabled ? onSend : null,
                      style: IconButton.styleFrom(
                        backgroundColor: canSend
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        foregroundColor: canSend
                            ? scheme.onPrimary
                            : scheme.onSurface.withValues(alpha: 0.35),
                        disabledBackgroundColor:
                            scheme.surfaceContainerHighest,
                        disabledForegroundColor:
                            scheme.onSurface.withValues(alpha: 0.3),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
