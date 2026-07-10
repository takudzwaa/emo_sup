import 'package:flutter/material.dart';

import '../models/listener_profile.dart';
import '../utils/date_format.dart';
import 'anonymous_avatar.dart';
import 'premium_badge.dart';
import 'soft_surface.dart';

/// Soft card for an available listener (no photo, no last name).
class ListenerCard extends StatelessWidget {
  const ListenerCard({
    super.key,
    required this.listener,
    required this.nextSlot,
    required this.onTap,
  });

  final ListenerProfile listener;
  final TimeSlot? nextSlot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnonymousAvatar(displayName: listener.displayName, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          listener.displayName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (listener.isPremium) ...[
                        const SizedBox(width: 8),
                        const PremiumBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listener.bio,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final lang in listener.languages)
                        _SoftChip(label: lang),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 15,
                          color: scheme.primary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nextSlot == null
                                ? 'No open slots this week'
                                : 'Next: ${AppDateFormat.slotLabel(nextSlot!.start)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: scheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: Color.lerp(scheme.secondary, scheme.onSurface, 0.2),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
