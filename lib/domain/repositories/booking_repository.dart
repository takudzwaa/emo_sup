import '../../models/booking.dart';
import '../../models/listener_profile.dart';
import '../../models/payment_method.dart';

/// I/O for user bookings.
///
/// Production: create/confirm via Cloud Function; clients only read + cancel
/// request paths. Memory impl keeps prototype local confirms.
abstract class BookingRepository {
  Stream<List<Booking>> watchUserBookings(String userId);

  Future<List<Booking>> listUserBookings(String userId);

  Future<Booking?> getBooking(String bookingId);

  /// Prototype / Phase A helper. Production uses `createBookingCheckout` CF.
  Future<Booking> confirmBooking({
    required String userId,
    required String listenerId,
    required DateTime slotStart,
    int priceCents = 0,
    String currency = 'USD',
    bool planApplied = false,
    PaymentMethod? paymentMethod,
    String paymentStatus = 'free',
  });

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newSlotStart,
  });

  Future<void> cancelBooking(String bookingId);

  /// Mock/local availability until CF-backed slots ship.
  Future<List<TimeSlot>> slotsForListener(
    String listenerId, {
    int days = 7,
  });
}
