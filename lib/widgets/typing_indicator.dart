import 'package:flutter/material.dart';

/// Soft three-dot typing placeholder for the assigned listener.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.14),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_controller.value + i * 0.2) % 1.0;
                final opacity = 0.35 + 0.65 * (1 - (phase - 0.5).abs() * 2);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  child: Opacity(
                    opacity: opacity.clamp(0.35, 1.0),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
