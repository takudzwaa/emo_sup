import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/booking_store.dart';
import 'package:emo_sup/models/listener_profile.dart';
import 'package:emo_sup/models/payment_method.dart';

void main() {
  test('confirmBooking stores payment metadata', () {
    final store = BookingStore(seedBookings: []);
    final b = store.confirmBooking(
      listenerId: 'listener_harbor',
      slotStart: DateTime.utc(2026, 8, 1, 10),
      priceCents: 1200,
      paymentMethod: PaymentMethod.ecocash,
      paymentStatus: 'paid',
    );
    expect(b.priceCents, 1200);
    expect(b.paymentMethod, PaymentMethod.ecocash);
    expect(b.paymentStatus, 'paid');
    expect(b.currency, 'USD');
    expect(b.planApplied, isFalse);
  });

  test('isPremiumAccess is true for premium listener Lantern', () {
    final store = BookingStore(seedBookings: []);
    final lantern = store.listenerById('listener_lantern');
    expect(lantern, isNotNull);
    expect(lantern!.isPremium, isTrue);
    expect(lantern.tier, ListenerTier.premium);

    final slot = TimeSlot(
      start: DateTime.utc(2026, 8, 1, 10),
      requiresPremium: false,
    );
    expect(
      store.isPremiumAccess(listenerId: 'listener_lantern', slot: slot),
      isTrue,
    );
  });

  test('isPremiumAccess is true for requiresPremium slots', () {
    final store = BookingStore(seedBookings: []);
    final harbor = store.listenerById('listener_harbor');
    expect(harbor, isNotNull);
    expect(harbor!.isPremium, isFalse);
    expect(harbor.tier, ListenerTier.standard);

    final premiumSlot = TimeSlot(
      start: DateTime.utc(2026, 8, 1, 19),
      requiresPremium: true,
    );
    expect(
      store.isPremiumAccess(listenerId: 'listener_harbor', slot: premiumSlot),
      isTrue,
    );

    final standardSlot = TimeSlot(
      start: DateTime.utc(2026, 8, 1, 10),
      requiresPremium: false,
    );
    expect(
      store.isPremiumAccess(listenerId: 'listener_harbor', slot: standardSlot),
      isFalse,
    );
  });

  test('rescheduleBooking updates slotStart', () {
    final store = BookingStore(seedBookings: []);
    final b = store.confirmBooking(
      listenerId: 'listener_harbor',
      slotStart: DateTime.utc(2026, 8, 1, 10),
    );
    final newStart = DateTime.utc(2026, 8, 2, 14);
    store.rescheduleBooking(bookingId: b.id, newSlotStart: newStart);
    expect(store.bookings.singleWhere((x) => x.id == b.id).slotStart, newStart);
  });
}
