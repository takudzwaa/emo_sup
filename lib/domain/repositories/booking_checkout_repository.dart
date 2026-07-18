import '../../models/booking.dart';
import '../../models/payment_method.dart';

/// How a booking is settled at create time (PR 13).
enum CheckoutSettlement {
  /// Membership covers the session → confirmed immediately.
  plan,

  /// NGO/sponsor free slot → confirmed immediately.
  sponsored,

  /// No charge (pilot free) → confirmed immediately.
  free,

  /// Mobile money / card required → pending_payment until gateway success.
  paid,
}

/// Result of [BookingCheckoutRepository.createBookingCheckout].
class BookingCheckoutResult {
  const BookingCheckoutResult({
    required this.booking,
    this.paymentId,
    this.requiresPayment = false,
  });

  final Booking booking;
  final String? paymentId;
  final bool requiresPayment;
}

/// Server-authoritative booking create (CF in prod; memory in prototype).
abstract class BookingCheckoutRepository {
  Future<BookingCheckoutResult> createBookingCheckout({
    required String userId,
    required String listenerId,
    required DateTime slotStart,
    required CheckoutSettlement settlement,
    int priceCents = 0,
    String currency = 'USD',
    String? sponsorId,
  });

  /// Completes a [BookingStatus.pendingPayment] booking after gateway success.
  Future<Booking> confirmPayment({
    required String bookingId,
    required String paymentId,
    required PaymentMethod method,
  });

  Future<void> cancelBooking(String bookingId);

  Future<void> setListenerAvailability({
    required String listenerId,
    required bool availableNow,
  });
}
