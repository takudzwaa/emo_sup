import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/membership_store.dart';
import '../models/listener_profile.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/anonymous_avatar.dart';
import '../widgets/safety_quick_access_bar.dart';
import '../widgets/soft_surface.dart';
import 'booking_confirm_screen.dart';

/// Simple date/time slot picker for one preferred listener.
class SlotPickerScreen extends StatefulWidget {
  const SlotPickerScreen({
    super.key,
    required this.store,
    required this.membershipStore,
    required this.listener,
  });

  final BookingStore store;
  final MembershipStore membershipStore;
  final ListenerProfile listener;

  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  TimeSlot? _selected;

  List<TimeSlot> get _slots =>
      widget.store.slotsForListener(widget.listener.id);

  Map<DateTime, List<TimeSlot>> get _grouped {
    final map = <DateTime, List<TimeSlot>>{};
    for (final slot in _slots) {
      final day = DateTime(
        slot.start.year,
        slot.start.month,
        slot.start.day,
      );
      map.putIfAbsent(day, () => []).add(slot);
    }
    return map;
  }

  void _continue() {
    final slot = _selected;
    if (slot == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingConfirmScreen(
          store: widget.store,
          membershipStore: widget.membershipStore,
          listener: widget.listener,
          slot: slot,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grouped = _grouped;
    final days = grouped.keys.toList()..sort();
    final hasPlan = widget.membershipStore.hasActivePlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a time'),
      ),
      body: SoftGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  SoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        AnonymousAvatar(
                          displayName: widget.listener.displayName,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.listener.displayName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Pick a slot that works for you',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (days.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No open slots this week. Try another listener.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final day in days) ...[
                      Text(
                        AppDateFormat.dayHeading(day),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final slot in grouped[day]!)
                            _SlotChip(
                              slot: slot,
                              selected: _selected?.start == slot.start,
                              hasActivePlan: hasPlan,
                              onTap: () => setState(() => _selected = slot),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                ],
              ),
            ),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: SoftPrimaryButton(
                  onPressed: _continue,
                  label: 'Continue',
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

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.hasActivePlan,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool selected;
  final bool hasActivePlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gold = AppTheme.premiumAccent(scheme);

    final premiumCaption = slot.sponsored
        ? 'Free · sponsor'
        : !slot.requiresPremium
            ? null
            : (hasActivePlan ? 'Included in plan' : 'Premium · \$12');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.16)
                : (scheme.brightness == Brightness.dark
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.8)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.55)
                  : scheme.outline.withValues(alpha: 0.22),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppDateFormat.timeOfDay(slot.start),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
              if (premiumCaption != null) ...[
                const SizedBox(height: 2),
                Text(
                  premiumCaption,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasActivePlan
                        ? scheme.secondary
                        : gold,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
