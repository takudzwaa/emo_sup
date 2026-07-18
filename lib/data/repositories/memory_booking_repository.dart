import '../../domain/repositories/booking_repository.dart';
import '../../models/booking.dart';
import '../../models/listener_profile.dart';
import '../../models/payment_method.dart';

/// In-memory bookings + mock availability for prototype + tests.
class MemoryBookingRepository implements BookingRepository {
  MemoryBookingRepository({
    List<Booking>? seedBookings,
  }) : _bookings = List<Booking>.from(
          seedBookings ?? MemoryBookingRepository.defaultSeedBookings(),
        );

  final List<Booking> _bookings;
  int _idCounter = 10;

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

  @override
  Stream<List<Booking>> watchUserBookings(String userId) async* {
    yield await listUserBookings(userId);
  }

  @override
  Future<List<Booking>> listUserBookings(String userId) async {
    return List.unmodifiable(
      _bookings.where((b) => b.userId == userId).toList(),
    );
  }

  @override
  Future<Booking?> getBooking(String bookingId) async {
    for (final b in _bookings) {
      if (b.id == bookingId) return b;
    }
    return null;
  }

  @override
  Future<Booking> confirmBooking({
    required String userId,
    required String listenerId,
    required DateTime slotStart,
    int priceCents = 0,
    String currency = 'USD',
    bool planApplied = false,
    PaymentMethod? paymentMethod,
    String paymentStatus = 'free',
  }) async {
    final booking = Booking(
      id: 'booking_${++_idCounter}',
      userId: userId,
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
    return booking;
  }

  @override
  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newSlotStart,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index].copyWith(slotStart: newSlotStart);
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index].copyWith(
      status: BookingStatus.cancelled,
    );
  }

  @override
  Future<List<TimeSlot>> slotsForListener(
    String listenerId, {
    int days = 7,
  }) async {
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
        final sponsored =
            hours[h] == 10 && (d + offset).isEven && !requiresPremium;
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
}
