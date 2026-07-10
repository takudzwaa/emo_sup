import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/listener_profile.dart';
import '../models/payment_method.dart';

/// In-memory bookings + mock availability for the prototype.
///
/// Later Firestore:
/// ```
/// bookings/{bookingId}
/// listeners/{listenerId}
/// ```
class BookingStore extends ChangeNotifier {
  BookingStore({
    List<ListenerProfile>? listeners,
    List<Booking>? seedBookings,
    this.currentUserId = 'user_quiet_river',
  })  : _listeners = List.unmodifiable(
          listeners ?? BookingStore.defaultListeners(),
        ),
        _bookings = List<Booking>.from(
          seedBookings ?? BookingStore.defaultSeedBookings(),
        );

  final String currentUserId;
  final List<ListenerProfile> _listeners;
  final List<Booking> _bookings;
  int _idCounter = 10;

  List<ListenerProfile> get listeners => _listeners;

  List<Booking> get bookings => List.unmodifiable(_bookings);

  List<Booking> get upcomingConfirmed {
    final now = DateTime.now();
    return _bookings
        .where(
          (b) =>
              b.status == BookingStatus.confirmed &&
              b.slotStart.isAfter(now.subtract(const Duration(minutes: 1))),
        )
        .toList()
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  }

  ListenerProfile? listenerById(String id) {
    for (final l in _listeners) {
      if (l.id == id) return l;
    }
    return null;
  }

  static List<ListenerProfile> defaultListeners() {
    return const [
      ListenerProfile(
        id: 'listener_harbor',
        displayName: 'Listener — Harbor',
        bio:
            'Calm presence for late-night overthinking. I listen without rushing you.',
        languages: ['English'],
      ),
      ListenerProfile(
        id: 'listener_moss',
        displayName: 'Listener — Moss',
        bio:
            'Here for academic pressure and quiet company. Soft check-ins, no judgment.',
        languages: ['English', 'Spanish'],
      ),
      ListenerProfile(
        id: 'listener_cedar',
        displayName: 'Listener — Cedar',
        bio:
            'Steady support when work stress piles up. Happy to sit with hard days.',
        languages: ['English', 'French'],
      ),
      ListenerProfile(
        id: 'listener_lantern',
        displayName: 'Listener — Lantern',
        bio:
            'Warm companion for lonely evenings. Share as little or as much as you like.',
        languages: ['English', 'Mandarin'],
        tier: ListenerTier.premium,
      ),
    ];
  }

  static List<Booking> defaultSeedBookings() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final slot = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      14,
    );
    return [
      Booking(
        id: 'booking_seed_01',
        userId: 'user_quiet_river',
        listenerId: 'listener_harbor',
        slotStart: slot,
        status: BookingStatus.confirmed,
      ),
    ];
  }

  /// Mock availability: next [days] days × 3 blocks (10:00, 14:00, 19:00).
  /// Some evening slots tagged Premium (non-blocking in the prototype).
  List<TimeSlot> slotsForListener(String listenerId, {int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hours = [10, 14, 19];
    final slots = <TimeSlot>[];

    // Seed variation so listeners don't look identical.
    final offset = listenerId.hashCode.abs() % 3;

    for (var d = 0; d < days; d++) {
      final day = today.add(Duration(days: d + 1)); // start tomorrow
      for (var h = 0; h < hours.length; h++) {
        // Skip one block per listener for a natural sparse feel.
        if ((h + d + offset) % 5 == 0) continue;

        final start = DateTime(day.year, day.month, day.day, hours[h]);
        if (start.isBefore(now)) continue;

        // Already booked?
        final taken = _bookings.any(
          (b) =>
              b.listenerId == listenerId &&
              b.status == BookingStatus.confirmed &&
              b.slotStart.isAtSameMomentAs(start),
        );
        if (taken) continue;

        final requiresPremium = hours[h] == 19 && (d + offset).isOdd;
        slots.add(TimeSlot(start: start, requiresPremium: requiresPremium));
      }
    }
    return slots;
  }

  /// Earliest open slot for card preview, or null if none.
  TimeSlot? nextAvailableSlot(String listenerId) {
    final slots = slotsForListener(listenerId);
    return slots.isEmpty ? null : slots.first;
  }

  /// Whether this listener or slot requires premium access.
  bool isPremiumAccess({required String listenerId, required TimeSlot slot}) {
    final listener = listenerById(listenerId);
    return slot.requiresPremium || (listener?.isPremium ?? false);
  }

  /// Confirms a booking locally.
  /// Next step: `bookings/{bookingId}` write.
  Booking confirmBooking({
    required String listenerId,
    required DateTime slotStart,
    int priceCents = 0,
    String currency = 'USD',
    bool planApplied = false,
    PaymentMethod? paymentMethod,
    String paymentStatus = 'free',
  }) {
    final booking = Booking(
      id: 'booking_${++_idCounter}',
      userId: currentUserId,
      listenerId: listenerId,
      slotStart: slotStart,
      status: BookingStatus.confirmed,
      priceCents: priceCents,
      currency: currency,
      planApplied: planApplied,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
    );
    _bookings.add(booking);
    notifyListeners();
    return booking;
  }

  void rescheduleBooking({
    required String bookingId,
    required DateTime newSlotStart,
  }) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index].copyWith(slotStart: newSlotStart);
    notifyListeners();
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index].copyWith(
      status: BookingStatus.cancelled,
    );
    notifyListeners();
  }
}
