import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gold chip marking a premium listener or slot.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gold = AppTheme.premiumAccent(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 13, color: gold),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: textTheme.bodySmall?.copyWith(
              color: gold,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
