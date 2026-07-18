import 'package:flutter/foundation.dart';

import '../domain/repositories/booking_repository.dart';
import '../domain/repositories/listener_directory_repository.dart';
import '../models/booking.dart';
import '../models/listener_profile.dart';
import '../models/payment_method.dart';
import 'repositories/memory_booking_repository.dart';
import 'repositories/memory_listener_directory_repository.dart';

/// UI-facing bookings + listener directory (ChangeNotifier façade).
///
/// I/O via [BookingRepository] + [ListenerDirectoryRepository].
class BookingStore extends ChangeNotifier {
  BookingStore({
    List<ListenerProfile>? listeners,
    List<Booking>? seedBookings,
    this.currentUserId = 'user_quiet_river',
    BookingRepository? bookingRepository,
    ListenerDirectoryRepository? listenerDirectory,
  })  : bookingRepository = bookingRepository ??
            MemoryBookingRepository(seedBookings: seedBookings),
        listenerDirectory = listenerDirectory ??
            MemoryListenerDirectoryRepository(listeners: listeners) {
    // Sync seed for UI: prefer injected lists, else memory defaults.
    _listeners = List.unmodifiable(
      listeners ?? MemoryListenerDirectoryRepository.defaultListeners(),
    );
    _bookings = List<Booking>.from(
      seedBookings ?? MemoryBookingRepository.defaultSeedBookings(),
    );
  }

  final String currentUserId;
  final BookingRepository bookingRepository;
  final ListenerDirectoryRepository listenerDirectory;

  late final List<ListenerProfile> _listeners;
  late List<Booking> _bookings;
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

  /// Kept for tests / seed overrides that still call the old static name.
  static List<ListenerProfile> defaultListeners() =>
      MemoryListenerDirectoryRepository.defaultListeners();

  static List<Booking> defaultSeedBookings() =>
      MemoryBookingRepository.defaultSeedBookings();

  /// Mock availability: next [days] days × 3 blocks (10:00, 14:00, 19:00).
  /// Some morning slots are **sponsored** free (PR 15).
  List<TimeSlot> slotsForListener(String listenerId, {int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hours = [10, 14, 19];
    final slots = <TimeSlot>[];
    final offset = listenerId.hashCode.abs() % 3;

    for (var d = 0; d < days; d++) {
      final day = today.add(Duration(days: d + 1));
      for (var h = 0; h < hours.length; h++) {
        if ((h + d + offset) % 5 == 0) continue;
        final start = DateTime(day.year, day.month, day.day, hours[h]);
        if (start.isBefore(now)) continue;

        final taken = _bookings.any(
          (b) =>
              b.listenerId == listenerId &&
              b.status == BookingStatus.confirmed &&
              b.slotStart.isAtSameMomentAs(start),
        );
        if (taken) continue;

        final requiresPremium = hours[h] == 19 && (d + offset).isOdd;
        // Morning community free slots (sponsor) — not premium.
        final sponsored = hours[h] == 10 && (d + offset).isEven && !requiresPremium;
        slots.add(
          TimeSlot(
            start: start,
            requiresPremium: requiresPremium,
            sponsored: sponsored,
            sponsorId: sponsored ? 'sponsor_community_free' : null,
          ),
        );
      }
    }
    return slots;
  }

  TimeSlot? nextAvailableSlot(String listenerId) {
    final slots = slotsForListener(listenerId);
    return slots.isEmpty ? null : slots.first;
  }

  bool isPremiumAccess({required String listenerId, required TimeSlot slot}) {
    if (slot.sponsored) return false;
    final listener = listenerById(listenerId);
    return slot.requiresPremium || (listener?.isPremium ?? false);
  }

  /// Confirms a booking locally (prototype). Production: CF checkout.
  Booking confirmBooking({
    required String listenerId,
    required DateTime slotStart,
    int priceCents = 0,
    String currency = 'USD',
    bool planApplied = false,
    PaymentMethod? paymentMethod,
    String paymentStatus = 'free',
    String? sponsorId,
    BookingStatus status = BookingStatus.confirmed,
  }) {
    final booking = Booking(
      id: 'booking_${++_idCounter}',
      userId: currentUserId,
      listenerId: listenerId,
      slotStart: slotStart,
      status: status,
      priceCents: priceCents,
      currency: currency,
      planApplied: planApplied,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      sponsorId: sponsorId,
    );
    _bookings.add(booking);
    bookingRepository.confirmBooking(
      userId: currentUserId,
      listenerId: listenerId,
      slotStart: slotStart,
      priceCents: priceCents,
      currency: currency,
      planApplied: planApplied,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
    );
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
    bookingRepository.rescheduleBooking(
      bookingId: bookingId,
      newSlotStart: newSlotStart,
    );
    notifyListeners();
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index].copyWith(
      status: BookingStatus.cancelled,
    );
    bookingRepository.cancelBooking(bookingId);
    notifyListeners();
  }
}
