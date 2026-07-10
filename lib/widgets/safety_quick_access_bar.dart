import 'package:flutter/material.dart';

import '../screens/safety_privacy_screen.dart';

/// Persistent, low-emphasis entry points for safety actions.
///
/// Drop this into Chat, Bookings, Listener Dashboard, etc. so
/// "Report & block" and "Delete my data" stay within ≤2 taps.
class SafetyQuickAccessBar extends StatelessWidget {
  const SafetyQuickAccessBar({
    super.key,
    this.compact = false,
  });

  /// When true, shows icon buttons only (useful in dense layouts).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;

    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Report & block',
            onPressed: () => _openHub(context, SafetyHubSection.reportBlock),
            icon: Icon(
              Icons.flag_outlined,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          IconButton(
            tooltip: 'Delete my data',
            onPressed: () => _openHub(context, SafetyHubSection.deleteData),
            icon: Icon(
              Icons.delete_outline,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    return Material(
      color: isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.55),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SafetyLink(
                icon: Icons.flag_outlined,
                label: 'Report & block',
                onTap: () => _openHub(context, SafetyHubSection.reportBlock),
                color: scheme.onSurface.withValues(alpha: 0.58),
                style: textTheme.bodySmall,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              _SafetyLink(
                icon: Icons.delete_outline,
                label: 'Delete my data',
                onTap: () => _openHub(context, SafetyHubSection.deleteData),
                color: scheme.onSurface.withValues(alpha: 0.58),
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHub(BuildContext context, SafetyHubSection section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SafetyPrivacyScreen(initialSection: section),
      ),
    );
  }
}

class _SafetyLink extends StatelessWidget {
  const _SafetyLink({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.style,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: style?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
