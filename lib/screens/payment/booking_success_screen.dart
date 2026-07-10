import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/listener_profile.dart';
import '../../utils/date_format.dart';
import '../../widgets/anonymous_avatar.dart';
import '../../widgets/safety_quick_access_bar.dart';
import '../../widgets/soft_surface.dart';

/// Confirmation after a free or paid booking succeeds.
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({
    super.key,
    required this.booking,
    required this.listener,
    this.receiptLine,
  });

  final Booking booking;
  final ListenerProfile listener;

  /// Optional payment receipt / plan message from [PaymentService].
  final String? receiptLine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked'),
        automaticallyImplyLeading: false,
      ),
      body: SoftGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: scheme.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: scheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "You're booked",
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A private session is scheduled. You can cancel anytime.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SoftCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          AnonymousAvatar(
                            displayName: listener.displayName,
                            size: 56,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            listener.displayName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppDateFormat.mediumDate(booking.slotStart)} · ${AppDateFormat.timeOfDay(booking.slotStart)}',
                            style: textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.75),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (receiptLine != null &&
                              receiptLine!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Divider(
                              color: scheme.outline.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              receiptLine!,
                              style: textTheme.bodySmall?.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.55),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: TrustChip(label: 'Private & confidential'),
                    ),
                    const SizedBox(height: 32),
                    SoftPrimaryButton(
                      onPressed: () => Navigator.of(context).pop(),
                      label: 'View upcoming',
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            scheme.onSurface.withValues(alpha: 0.65),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
            const SafetyQuickAccessBar(),
          ],
        ),
      ),
    );
  }
}
