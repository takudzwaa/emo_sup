import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/membership_store.dart';
import '../models/booking.dart';
import '../models/listener_profile.dart';
import '../utils/date_format.dart';
import '../widgets/anonymous_avatar.dart';
import '../widgets/safety_quick_access_bar.dart';
import '../widgets/soft_surface.dart';
import 'payment/checkout_screen.dart';

/// Summary step with one primary action: Confirm booking (or continue to pay).
class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({
    super.key,
    required this.store,
    required this.membershipStore,
    required this.listener,
    required this.slot,
  });

  final BookingStore store;
  final MembershipStore membershipStore;
  final ListenerProfile listener;
  final TimeSlot slot;

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _confirming = false;

  bool get _isPremiumAccess => widget.store.isPremiumAccess(
        listenerId: widget.listener.id,
        slot: widget.slot,
      );

  bool get _needsPay =>
      _isPremiumAccess && !widget.membershipStore.hasActivePlan;

  bool get _planCovers =>
      _isPremiumAccess && widget.membershipStore.hasActivePlan;

  Future<void> _onPrimary() async {
    if (_confirming) return;
    setState(() => _confirming = true);

    final needsPay = widget.store.isPremiumAccess(
          listenerId: widget.listener.id,
          slot: widget.slot,
        ) &&
        !widget.membershipStore.hasActivePlan;

    if (!needsPay) {
      final isPremium = widget.store.isPremiumAccess(
        listenerId: widget.listener.id,
        slot: widget.slot,
      );
      final booking = widget.store.confirmBooking(
        listenerId: widget.listener.id,
        slotStart: widget.slot.start,
        priceCents: 0,
        planApplied: isPremium && widget.membershipStore.hasActivePlan,
        paymentStatus:
            (isPremium && widget.membershipStore.hasActivePlan) ? 'plan' : 'free',
      );
      _finishWith(booking);
      return;
    }

    final booking = await Navigator.of(context).push<Booking>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          store: widget.store,
          membershipStore: widget.membershipStore,
          listener: widget.listener,
          slot: widget.slot,
        ),
      ),
    );
    if (!mounted) return;
    if (booking != null) {
      _finishWith(booking);
    } else {
      setState(() => _confirming = false);
    }
  }

  void _finishWith(Booking booking) {
    Navigator.of(context).pop(); // confirm
    Navigator.of(context).pop(booking); // picker
  }

  String get _primaryLabel {
    if (_confirming) {
      return _needsPay ? 'Opening…' : 'Confirming…';
    }
    if (_needsPay) return 'Continue to payment';
    return 'Confirm booking';
  }

  String? get _accessHint {
    if (_needsPay) return 'Premium session · \$12';
    if (_planCovers) return 'Included in your plan';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final listener = widget.listener;
    final slot = widget.slot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm booking'),
      ),
      body: SoftGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "You're booking with",
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: AnonymousAvatar(
                        displayName: listener.displayName,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      listener.displayName,
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppDateFormat.mediumDate(slot.start)} at ${AppDateFormat.timeOfDay(slot.start)}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SoftCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _SummaryRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date',
                            value: AppDateFormat.mediumDate(slot.start),
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            icon: Icons.schedule_outlined,
                            label: 'Time',
                            value: AppDateFormat.timeOfDay(slot.start),
                          ),
                          if (_isPremiumAccess) ...[
                            const SizedBox(height: 16),
                            _SummaryRow(
                              icon: Icons.workspace_premium_outlined,
                              label: 'Tier',
                              value: _planCovers
                                  ? 'Premium · covered by plan'
                                  : 'Premium session',
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_accessHint != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _accessHint!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.primary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 36),
                    SoftPrimaryButton(
                      onPressed: _confirming ? null : _onPrimary,
                      label: _primaryLabel,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _confirming
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            scheme.onSurface.withValues(alpha: 0.65),
                      ),
                      child: const Text('Cancel'),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary.withValues(alpha: 0.85)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
