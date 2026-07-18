import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/repositories/memory_booking_checkout_repository.dart';
import 'package:emo_sup/domain/repositories/booking_checkout_repository.dart';
import 'package:emo_sup/models/booking.dart';
import 'package:emo_sup/models/payment_method.dart';

void main() {
  test('free and sponsored settle to confirmed without payment', () async {
    final checkout = MemoryBookingCheckoutRepository();
    final free = await checkout.createBookingCheckout(
      userId: 'u1',
      listenerId: 'l1',
      slotStart: DateTime.utc(2026, 8, 1, 10),
      settlement: CheckoutSettlement.free,
    );
    expect(free.requiresPayment, isFalse);
    expect(free.booking.status, BookingStatus.confirmed);
    expect(free.booking.paymentStatus, 'free');

    final sponsored = await checkout.createBookingCheckout(
      userId: 'u1',
      listenerId: 'l1',
      slotStart: DateTime.utc(2026, 8, 1, 11),
      settlement: CheckoutSettlement.sponsored,
      sponsorId: 'sponsor_community_free',
    );
    expect(sponsored.booking.status, BookingStatus.confirmed);
    expect(sponsored.booking.paymentStatus, 'sponsored');
    expect(sponsored.booking.sponsorId, 'sponsor_community_free');
  });

  test('paid path holds then confirms after gateway', () async {
    final checkout = MemoryBookingCheckoutRepository(
      holdTtl: const Duration(minutes: 12),
    );
    final hold = await checkout.createBookingCheckout(
      userId: 'u1',
      listenerId: 'l1',
      slotStart: DateTime.utc(2026, 8, 1, 19),
      settlement: CheckoutSettlement.paid,
      priceCents: 1200,
    );
    expect(hold.requiresPayment, isTrue);
    expect(hold.booking.status, BookingStatus.pendingPayment);
    expect(hold.paymentId, isNotNull);
    expect(hold.booking.holdExpiresAt, isNotNull);

    final confirmed = await checkout.confirmPayment(
      bookingId: hold.booking.id,
      paymentId: hold.paymentId!,
      method: PaymentMethod.ecocash,
    );
    expect(confirmed.status, BookingStatus.confirmed);
    expect(confirmed.paymentStatus, 'paid');
    expect(confirmed.paymentMethod, PaymentMethod.ecocash);
  });

  test('stale holds expire', () async {
    final checkout = MemoryBookingCheckoutRepository(
      holdTtl: const Duration(minutes: 12),
    );
    final hold = await checkout.createBookingCheckout(
      userId: 'u1',
      listenerId: 'l1',
      slotStart: DateTime.utc(2026, 8, 1, 19),
      settlement: CheckoutSettlement.paid,
      priceCents: 1200,
    );
    await checkout.expireStaleHolds(
      now: DateTime.now().add(const Duration(minutes: 13)),
    );
    final expired = checkout.getById(hold.booking.id);
    expect(expired?.status, BookingStatus.expired);
  });
}
