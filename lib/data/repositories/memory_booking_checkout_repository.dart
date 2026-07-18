import '../../domain/repositories/booking_checkout_repository.dart';
import '../../domain/repositories/listener_ops_repository.dart';
import '../../models/booking.dart';
import '../../models/payment_method.dart';
import 'memory_listener_ops_repository.dart';

/// Prototype stand-in for CF `createBookingCheckout` (PR 13).
///
/// Dual entry:
/// - plan / sponsored / free → [BookingStatus.confirmed] immediately
/// - paid → [BookingStatus.pendingPayment] with 12-minute hold
class MemoryBookingCheckoutRepository implements BookingCheckoutRepository {
  MemoryBookingCheckoutRepository({
    ListenerOpsRepository? listenerOps,
    this.holdTtl = const Duration(minutes: 12),
    List<Booking>? seed,
  })  : _listenerOps = listenerOps ?? MemoryListenerOpsRepository(),
        _bookings = List<Booking>.from(seed ?? const []);

  final ListenerOpsRepository _listenerOps;
  final Duration holdTtl;
  final List<Booking> _bookings;
  int _idCounter = 100;
  int _payCounter = 100;

  List<Booking> get bookings => List.unmodifiable(_bookings);

  Booking? getById(String id) {
    for (final b in _bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Future<BookingCheckoutResult> createBookingCheckout({
    required String userId,
    required String listenerId,
    required DateTime slotStart,
    required CheckoutSettlement settlement,
    int priceCents = 0,
    String currency = 'USD',
    String? sponsorId,
  }) async {
    final needsPay = settlement == CheckoutSettlement.paid;
    final status =
        needsPay ? BookingStatus.pendingPayment : BookingStatus.confirmed;
    final paymentStatus = switch (settlement) {
      CheckoutSettlement.plan => 'plan',
      CheckoutSettlement.sponsored => 'sponsored',
      CheckoutSettlement.free => 'free',
      CheckoutSettlement.paid => 'pending',
    };

    final booking = Booking(
      id: 'booking_co_${++_idCounter}',
      userId: userId,
      listenerId: listenerId,
      slotStart: slotStart,
      status: status,
      priceCents: priceCents,
      currency: currency,
      planApplied: settlement == CheckoutSettlement.plan,
      paymentStatus: paymentStatus,
      holdExpiresAt: needsPay ? DateTime.now().add(holdTtl) : null,
      sponsorId: sponsorId,
    );
    _bookings.add(booking);

    final paymentId = needsPay ? 'pay_hold_${++_payCounter}' : null;
    return BookingCheckoutResult(
      booking: booking,
      paymentId: paymentId,
      requiresPayment: needsPay,
    );
  }

  @override
  Future<Booking> confirmPayment({
    required String bookingId,
    required String paymentId,
    required PaymentMethod method,
  }) async {
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i < 0) {
      throw StateError('Booking not found: $bookingId');
    }
    final updated = _bookings[i].copyWith(
      status: BookingStatus.confirmed,
      paymentMethod: method,
      paymentStatus: 'paid',
      holdExpiresAt: null,
    );
    _bookings[i] = updated;
    return updated;
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i < 0) return;
    _bookings[i] = _bookings[i].copyWith(status: BookingStatus.cancelled);
  }

  @override
  Future<void> setListenerAvailability({
    required String listenerId,
    required bool availableNow,
  }) async {
    await _listenerOps.setAvailableNow(listenerId, availableNow);
  }

  /// Expire unpaid holds (would be a scheduled CF in production).
  Future<void> expireStaleHolds({DateTime? now}) async {
    final t = now ?? DateTime.now();
    for (var i = 0; i < _bookings.length; i++) {
      final b = _bookings[i];
      if (b.status == BookingStatus.pendingPayment &&
          b.holdExpiresAt != null &&
          b.holdExpiresAt!.isBefore(t)) {
        _bookings[i] = b.copyWith(status: BookingStatus.expired);
      }
    }
  }
}
