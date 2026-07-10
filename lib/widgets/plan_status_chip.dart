import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small elegant chip: "Plan" (gold/tertiary) or "Free" (muted).
class PlanStatusChip extends StatelessWidget {
  const PlanStatusChip({
    super.key,
    required this.hasPlan,
  });

  final bool hasPlan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (hasPlan) {
      final gold = AppTheme.premiumAccent(scheme);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withValues(alpha: 0.5)),
        ),
        child: Text(
          'Plan',
          style: textTheme.bodySmall?.copyWith(
            color: gold,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            height: 1.1,
          ),
        ),
      );
    }

    final muted = scheme.onSurface.withValues(alpha: 0.45);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
      ),
      child: Text(
        'Free',
        style: textTheme.bodySmall?.copyWith(
          color: muted,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          height: 1.1,
        ),
      ),
    );
  }
}
