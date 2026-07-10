import 'package:flutter/material.dart';

import '../../data/listener_dashboard_store.dart';
import '../../models/active_chat_summary.dart';
import '../../theme/listener_theme.dart';
import '../../utils/date_format.dart';
import '../../widgets/anonymous_avatar.dart';
import '../../widgets/safety_quick_access_bar.dart';
import '../../widgets/soft_surface.dart';
import '../chat_screen.dart';

/// Separate interface for vetted listeners (not the end-user app shell).
class ListenerDashboardScreen extends StatefulWidget {
  const ListenerDashboardScreen({
    super.key,
    this.store,
  });

  final ListenerDashboardStore? store;

  @override
  State<ListenerDashboardScreen> createState() =>
      _ListenerDashboardScreenState();
}

class _ListenerDashboardScreenState extends State<ListenerDashboardScreen> {
  late final ListenerDashboardStore _store;
  late final bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.store == null;
    _store = widget.store ?? ListenerDashboardStore();
    _store.addListener(_onChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    if (_ownsStore) _store.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openChat(ActiveChatSummary chat) async {
    _store.markChatRead(chat.sessionId);
    final chatStore = _store.openChatStore(chat);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatStore: chatStore,
          perspective: ChatPerspective.listener,
          onEscalate: () => _store.escalateChat(sessionId: chat.sessionId),
        ),
      ),
    );
    chatStore.dispose();
  }

  Future<void> _escalateFromCard(ActiveChatSummary chat) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Escalate this chat?'),
          content: Text(
            'Escalate for ${chat.userAnonymousName} if there may be risk of harm. '
            'Never diagnose.\n\n'
            'Prototype: confirmation only — real on-call notification hooks '
            'into ListenerDashboardStore.escalateChat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Go back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Escalate now'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _store.escalateChat(sessionId: chat.sessionId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Escalation recorded for ${chat.userAnonymousName} (prototype).',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _joinBooking(ListenerBookingSummary booking) async {
    if (!booking.canJoin) return;

    // Open a fresh session for the booked user (prototype).
    final summary = ActiveChatSummary(
      sessionId: 'session_from_${booking.bookingId}',
      userId: booking.userId,
      userAnonymousName: booking.userAnonymousName,
      lastMessagePreview: 'Scheduled session starting now.',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    );
    await _openChat(summary);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listener dashboard',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _store.listenerDisplayName,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ListenerTheme.scaffoldGradient(scheme),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TodaySummaryCard(
                      sessionsToday: _store.sessionsToday,
                      estimatedEarnings: _store.estimatedEarningsDemo,
                    ),
                    const SizedBox(height: 16),

                    // Availability — one large primary control
                    _AvailabilityCard(
                      available: _store.availableNow,
                      onChanged: _store.setAvailableNow,
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Active chats',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_store.activeChats.isEmpty)
                      const _EmptyHint(text: 'No open chats right now.')
                    else
                      for (final chat in _store.activeChats)
                        _ActiveChatCard(
                          chat: chat,
                          onOpen: () => _openChat(chat),
                          onEscalate: () => _escalateFromCard(chat),
                        ),

                    const SizedBox(height: 24),
                    Text(
                      'Upcoming bookings',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_store.upcomingBookings.isEmpty)
                      const _EmptyHint(text: 'No scheduled sessions.')
                    else
                      for (final booking in _store.upcomingBookings)
                        _BookingCard(
                          booking: booking,
                          onJoin: () => _joinBooking(booking),
                        ),
                  ],
                ),
              ),
            ),

            // Un-dismissible safety reminder
            const _ListenerReminderBanner(),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
            const SafetyQuickAccessBar(),
          ],
        ),
      ),
    );
  }
}

// ─── Today summary (demo metrics) ─────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.sessionsToday,
    required this.estimatedEarnings,
  });

  final int sessionsToday;
  final int estimatedEarnings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Sessions today',
                  value: '$sessionsToday',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: scheme.outline.withValues(alpha: 0.22),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Est. earnings',
                  value: '\$$estimatedEarnings',
                  caption: '(demo)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Demo totals only — not real payouts.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.48),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(width: 6),
                Text(
                  caption!,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Availability ─────────────────────────────────────────────────────────────

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.available,
    required this.onChanged,
  });

  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Online → secondary (sage); Away → muted outline.
    final statusColor = available
        ? scheme.secondary
        : scheme.outline.withValues(alpha: 0.55);

    return SoftCard(
      highlighted: available,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        value: available,
        onChanged: onChanged,
        activeTrackColor: scheme.secondary,
        secondary: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: available
                ? [
                    BoxShadow(
                      color: scheme.secondary.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        title: Text(
          available ? 'Online' : 'Away',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: available
                ? scheme.onSurface
                : scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        subtitle: Text(
          available
              ? 'You may receive new chat requests'
              : 'You appear offline to users',
          style: textTheme.bodySmall?.copyWith(
            color: available
                ? scheme.onSurface.withValues(alpha: 0.65)
                : scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

// ─── Active chats ─────────────────────────────────────────────────────────────

class _ActiveChatCard extends StatelessWidget {
  const _ActiveChatCard({
    required this.chat,
    required this.onOpen,
    required this.onEscalate,
  });

  final ActiveChatSummary chat;
  final VoidCallback onOpen;
  final VoidCallback onEscalate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnonymousAvatar(
                displayName: chat.userAnonymousName,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.userAnonymousName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: chat.hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          AppDateFormat.timeOfDay(chat.lastMessageAt),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessagePreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: chat.hasUnread ? 0.85 : 0.6,
                        ),
                        fontWeight: chat.hasUnread
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (chat.hasUnread) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    chat.unreadCount > 9 ? '9+' : '${chat.unreadCount}',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onEscalate,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Escalate'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Open chat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bookings ─────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onJoin,
  });

  final ListenerBookingSummary booking;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canJoin = booking.canJoin;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          AnonymousAvatar(
            displayName: booking.userAnonymousName,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.userAnonymousName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateFormat.slotLabel(booking.slotStart),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canJoin ? onJoin : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor:
                  canJoin ? scheme.primary : scheme.surfaceContainerHighest,
              foregroundColor: canJoin
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.35),
              disabledBackgroundColor: scheme.surfaceContainerHighest,
              disabledForegroundColor:
                  scheme.onSurface.withValues(alpha: 0.35),
            ),
            child: Text(canJoin ? 'Join now' : 'Join at time'),
          ),
        ],
      ),
    );
  }
}

// ─── Shared bits ──────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Persistent, un-dismissible reminder for every listener session.
class _ListenerReminderBanner extends StatelessWidget {
  const _ListenerReminderBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.error.withValues(alpha: 0.1),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.priority_high_rounded,
                size: 18,
                color: scheme.error.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reminder: never diagnose. If a user indicates risk of harm, '
                  'use the Escalate button.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
