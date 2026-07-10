import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/listener_profile.dart';
import '../utils/date_format.dart';
import 'anonymous_avatar.dart';
import 'soft_surface.dart';

/// One confirmed upcoming session with reschedule and cancel actions.
class UpcomingBookingTile extends StatelessWidget {
  const UpcomingBookingTile({
    super.key,
    required this.booking,
    required this.listener,
    required this.onCancel,
    this.onReschedule,
  });

  final Booking booking;
  final ListenerProfile listener;
  final VoidCallback onCancel;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnonymousAvatar(displayName: listener.displayName, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listener.displayName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppDateFormat.slotLabel(booking.slotStart),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Confirmed',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (onReschedule != null)
                      TextButton(
                        onPressed: onReschedule,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Reschedule'),
                      ),
                    if (onReschedule != null) const SizedBox(width: 12),
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Cancel booking'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
