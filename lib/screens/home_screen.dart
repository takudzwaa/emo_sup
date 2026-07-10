import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/membership_store.dart';
import '../data/mood_store.dart';
import '../models/mood_entry.dart';
import '../utils/date_format.dart';
import '../widgets/anonymous_avatar.dart';
import '../widgets/mood_check_in.dart';
import '../widgets/plan_status_chip.dart';
import '../widgets/safety_quick_access_bar.dart';
import '../widgets/soft_surface.dart';
import 'bookings_screen.dart';
import 'chat_screen.dart';
import 'safety_privacy_screen.dart';

/// Home: mood check-in + one primary "Talk to Someone" CTA.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.moodStore,
    required this.bookingStore,
    required this.membershipStore,
    this.anonymousUsername = 'Quiet River',
  });

  final MoodStore moodStore;
  final BookingStore bookingStore;
  final MembershipStore membershipStore;

  /// Anonymous display name only — never a real name or public profile.
  final String anonymousUsername;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.moodStore.addListener(_onStoreChanged);
    widget.bookingStore.addListener(_onStoreChanged);
    widget.membershipStore.addListener(_onStoreChanged);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moodStore != widget.moodStore) {
      oldWidget.moodStore.removeListener(_onStoreChanged);
      widget.moodStore.addListener(_onStoreChanged);
    }
    if (oldWidget.bookingStore != widget.bookingStore) {
      oldWidget.bookingStore.removeListener(_onStoreChanged);
      widget.bookingStore.addListener(_onStoreChanged);
    }
    if (oldWidget.membershipStore != widget.membershipStore) {
      oldWidget.membershipStore.removeListener(_onStoreChanged);
      widget.membershipStore.addListener(_onStoreChanged);
    }
  }

  @override
  void dispose() {
    widget.moodStore.removeListener(_onStoreChanged);
    widget.bookingStore.removeListener(_onStoreChanged);
    widget.membershipStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _onMoodSelected(int value) {
    widget.moodStore.add(value);
  }

  void _openSafetyHub() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SafetyPrivacyScreen(),
      ),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChatScreen(),
      ),
    );
  }

  void _openBookings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingsScreen(
          bookingStore: widget.bookingStore,
          membershipStore: widget.membershipStore,
        ),
      ),
    );
  }

  static String greetingFor(DateTime now, String username) {
    final hour = now.hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$salutation, $username';
  }

  static String emojiForMood(int value) {
    switch (value) {
      case 1:
        return '😔';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final upcoming = widget.bookingStore.upcomingConfirmed;
    final nextBooking = upcoming.isEmpty ? null : upcoming.first;
    final nextListener = nextBooking == null
        ? null
        : widget.bookingStore.listenerById(nextBooking.listenerId);
    final history = widget.moodStore.entries;
    final recentHistory = history.length <= 5
        ? history
        : history.sublist(history.length - 5);

    return Scaffold(
      body: SoftGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HomeHeader(
                        username: widget.anonymousUsername,
                        greeting: greetingFor(
                          DateTime.now(),
                          widget.anonymousUsername,
                        ),
                        hasPlan: widget.membershipStore.hasActivePlan,
                        onSettingsTap: _openSafetyHub,
                      ),
                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: TrustChip(),
                      ),
                      const SizedBox(height: 28),

                      MoodCheckIn(
                        latest: widget.moodStore.latest,
                        onSelected: _onMoodSelected,
                      ),

                      if (recentHistory.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MoodHistoryStrip(entries: recentHistory),
                      ],
                      const SizedBox(height: 28),

                      SoftPrimaryButton(
                        onPressed: _openChat,
                        label: 'Talk to Someone',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Connect with a trained listener — not therapy.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),

                      if (nextBooking != null && nextListener != null) ...[
                        SoftCard(
                          padding: EdgeInsets.zero,
                          onTap: _openBookings,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: scheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.event_rounded,
                                    color: scheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Next session',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        nextListener.displayName,
                                        style: textTheme.titleSmall,
                                      ),
                                      Text(
                                        AppDateFormat.slotLabel(
                                          nextBooking.slotStart,
                                        ),
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      SoftCard(
                        padding: EdgeInsets.zero,
                        onTap: _openBookings,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      scheme.secondary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.event_available_outlined,
                                  color: scheme.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Book a session for later',
                                      style: textTheme.titleSmall,
                                    ),
                                    Text(
                                      'Schedule with a preferred listener',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.35),
                              ),
                            ],
                          ),
                        ),
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
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.username,
    required this.greeting,
    required this.hasPlan,
    required this.onSettingsTap,
  });

  final String username;
  final String greeting;
  final bool hasPlan;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        AnonymousAvatar(displayName: username, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      username,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlanStatusChip(hasPlan: hasPlan),
                ],
              ),
            ],
          ),
        ),
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            tooltip: 'Safety & Privacy',
            onPressed: onSettingsTap,
            icon: const Icon(Icons.shield_outlined),
          ),
        ),
      ],
    );
  }
}

/// Horizontal strip of recent mood emojis (last up to 5) — not streaks/points.
class _MoodHistoryStrip extends StatelessWidget {
  const _MoodHistoryStrip({required this.entries});

  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent check-ins',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  _HomeScreenState.emojiForMood(entry.value),
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
