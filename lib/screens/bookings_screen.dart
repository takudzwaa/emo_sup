import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/membership_store.dart';
import '../models/booking.dart';
import '../models/listener_profile.dart';
import '../widgets/language_filter_chips.dart';
import '../widgets/listener_card.dart';
import '../widgets/safety_quick_access_bar.dart';
import '../widgets/soft_surface.dart';
import '../widgets/upcoming_booking_tile.dart';
import 'slot_picker_screen.dart';

/// Schedule a future session with a preferred listener.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({
    super.key,
    this.bookingStore,
    this.membershipStore,
    this.initialTabIndex = 0,
  });

  /// Optional inject for tests; creates a mock store if null.
  final BookingStore? bookingStore;

  /// Optional inject for tests; creates [MembershipStore] if null.
  final MembershipStore? membershipStore;

  /// 0 = Find a listener, 1 = My upcoming.
  final int initialTabIndex;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final BookingStore _store;
  late final bool _ownsStore;
  late final MembershipStore _membershipStore;
  late final bool _ownsMembershipStore;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.bookingStore == null;
    _store = widget.bookingStore ?? BookingStore();
    _store.addListener(_onStoreChanged);
    _ownsMembershipStore = widget.membershipStore == null;
    _membershipStore = widget.membershipStore ?? MembershipStore();
    _membershipStore.addListener(_onStoreChanged);
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    if (_ownsStore) {
      _store.dispose();
    }
    _membershipStore.removeListener(_onStoreChanged);
    if (_ownsMembershipStore) {
      _membershipStore.dispose();
    }
    _tabs.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openSlotPicker(ListenerProfile listener) async {
    final result = await Navigator.of(context).push<Booking>(
      MaterialPageRoute(
        builder: (_) => SlotPickerScreen(
          store: _store,
          membershipStore: _membershipStore,
          listener: listener,
        ),
      ),
    );

    if (!mounted || result == null) return;

    _tabs.animateTo(1);
    final name =
        _store.listenerById(result.listenerId)?.displayName ?? 'your listener';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You're booked with $name"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reschedule: book a new slot, then cancel the old booking.
  Future<void> _reschedule(Booking old) async {
    final listener = _store.listenerById(old.listenerId);
    if (listener == null) return;

    final result = await Navigator.of(context).push<Booking>(
      MaterialPageRoute(
        builder: (_) => SlotPickerScreen(
          store: _store,
          membershipStore: _membershipStore,
          listener: listener,
        ),
      ),
    );

    if (result != null && mounted) {
      _store.cancelBooking(old.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session rescheduled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmCancel(Booking booking) async {
    final listener = _store.listenerById(booking.listenerId);
    final scheme = Theme.of(context).colorScheme;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel this session?'),
          content: Text(
            listener == null
                ? 'This booking will be removed from your upcoming list.'
                : 'Cancel your session with ${listener.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep booking'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      _store.cancelBooking(booking.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final upcoming = _store.upcomingConfirmed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a session'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'Find a listener'),
            Tab(
              text: upcoming.isEmpty
                  ? 'My upcoming'
                  : 'My upcoming (${upcoming.length})',
            ),
          ],
        ),
      ),
      body: SoftGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _FindListenersTab(
                    store: _store,
                    onSelectListener: _openSlotPicker,
                  ),
                  _UpcomingTab(
                    store: _store,
                    onCancel: _confirmCancel,
                    onReschedule: _reschedule,
                    onBrowseListeners: () => _tabs.animateTo(0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Private scheduling — no public profiles or calendars.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
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

class _FindListenersTab extends StatefulWidget {
  const _FindListenersTab({
    required this.store,
    required this.onSelectListener,
  });

  final BookingStore store;
  final ValueChanged<ListenerProfile> onSelectListener;

  @override
  State<_FindListenersTab> createState() => _FindListenersTabState();
}

class _FindListenersTabState extends State<_FindListenersTab> {
  String? _selectedLanguage;

  List<String> get _uniqueLanguages {
    final set = <String>{};
    for (final listener in widget.store.listeners) {
      set.addAll(listener.languages);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<ListenerProfile> get _filteredListeners {
    final selected = _selectedLanguage;
    if (selected == null) return widget.store.listeners;
    return widget.store.listeners
        .where((l) => l.languages.contains(selected))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredListeners;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Choose someone you’d like to talk with later.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 14),
        LanguageFilterChips(
          languages: _uniqueLanguages,
          selected: _selectedLanguage,
          onChanged: (lang) => setState(() => _selectedLanguage = lang),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'No listeners for this language.',
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final listener in filtered)
            ListenerCard(
              listener: listener,
              nextSlot: widget.store.nextAvailableSlot(listener.id),
              onTap: () => widget.onSelectListener(listener),
            ),
      ],
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({
    required this.store,
    required this.onCancel,
    required this.onReschedule,
    required this.onBrowseListeners,
  });

  final BookingStore store;
  final ValueChanged<Booking> onCancel;
  final ValueChanged<Booking> onReschedule;
  final VoidCallback onBrowseListeners;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final upcoming = store.upcomingConfirmed;

    if (upcoming.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 32,
                  color: scheme.primary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No upcoming sessions',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Book a future slot with a listener when you’re ready.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: onBrowseListeners,
                child: const Text('Find a listener'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Your confirmed sessions',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        for (final booking in upcoming)
          UpcomingBookingTile(
            booking: booking,
            listener: store.listenerById(booking.listenerId) ??
                ListenerProfile(
                  id: booking.listenerId,
                  displayName: 'Listener',
                  bio: '',
                  languages: const [],
                ),
            onCancel: () => onCancel(booking),
            onReschedule: () => onReschedule(booking),
          ),
      ],
    );
  }
}
