import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import 'soft_surface.dart';

/// Five tappable mood levels (very low → great).
///
/// Acknowledgment copy is warm only — no advice, diagnosis, or therapy language.
class MoodCheckIn extends StatelessWidget {
  const MoodCheckIn({
    super.key,
    required this.onSelected,
    this.latest,
  });

  final ValueChanged<int> onSelected;
  final MoodEntry? latest;

  static const _moods = <_MoodOption>[
    _MoodOption(value: 1, emoji: '😔', label: 'Very low'),
    _MoodOption(value: 2, emoji: '😕', label: 'Low'),
    _MoodOption(value: 3, emoji: '😐', label: 'Okay'),
    _MoodOption(value: 4, emoji: '🙂', label: 'Good'),
    _MoodOption(value: 5, emoji: '😊', label: 'Great'),
  ];

  static String acknowledgmentFor(int value) {
    switch (value) {
      case 1:
        return "Thanks for checking in. You're welcome here.";
      case 2:
        return "We hear you. Take things one moment at a time.";
      case 3:
        return 'Noted. However today feels is okay.';
      case 4:
        return 'Glad you shared that. Nice to have you here.';
      case 5:
        return 'Wonderful that things feel good right now.';
      default:
        return 'Thanks for checking in.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = latest?.value;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How are you feeling?',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'A quick private check-in — just for you.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final mood in _moods)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _MoodChip(
                      option: mood,
                      isSelected: selected == mood.value,
                      onTap: () => onSelected(mood.value),
                    ),
                  ),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: selected == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        acknowledgmentFor(selected),
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoodOption {
  const _MoodOption({
    required this.value,
    required this.emoji,
    required this.label,
  });

  final int value;
  final String emoji;
  final String label;
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _MoodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.16)
                  : (isDark
                      ? scheme.surface.withValues(alpha: 0.45)
                      : scheme.surface.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.5)
                    : scheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  option.label,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 9.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
