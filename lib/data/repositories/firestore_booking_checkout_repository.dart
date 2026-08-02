import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/booking_checkout_repository.dart';
import '../../models/booking.dart';
import '../../models/payment_method.dart';
import '../firebase/callable_client.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreBookingCheckoutRepository implements BookingCheckoutRepository {
  FirestoreBookingCheckoutRepository({
    FirebaseFirestore? firestore,
    CallableClient? callables,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _callables = callables ?? CallableClient();

  final FirebaseFirestore _db;
  final CallableClient _callables;

  Booking _bookingFromMap(String id, Map<String, dynamic> d) {
    final methodName = d['paymentMethod'] as String?;
    return Booking(
      id: id,
      userId: (d['userId'] as String?) ?? '',
      listenerId: (d['listenerId'] as String?) ?? '',
      slotStart: requireTimestamp(d['slotStart'], fallback: DateTime.now()),
      status: BookingStatusX.fromFirestore(d['status'] as String?),
      priceCents: (d['priceCents'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String?) ?? 'USD',
      planApplied: d['planApplied'] == true,
      paymentMethod: methodName == null
          ? null
          : PaymentMethod.values.firstWhere(
              (m) => m.name == methodName,
              orElse: () => PaymentMethod.card,
            ),
      paymentStatus: (d['paymentStatus'] as String?) ?? 'free',
      holdExpiresAt: parseTimestamp(d['holdExpiresAt']),
      sponsorId: d['sponsorId'] as String?,
    );
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
    final data = await _callables.call('createBookingCheckout', {
      'listenerId': listenerId,
      'slotStart': slotStart.toUtc().toIso8601String(),
      'settlement': settlement.name,
      'priceCents': priceCents,
      'currency': currency,
      'sponsorId': ?sponsorId,
    });
    final bookingId = data['bookingId'] as String;
    final snap = await _db.doc(FirestorePaths.booking(bookingId)).get();
    final booking = _bookingFromMap(bookingId, snap.data() ?? {
      'userId': userId,
      'listenerId': listenerId,
      'slotStart': slotStart,
      'status': data['status'],
      'priceCents': priceCents,
      'currency': currency,
    });
    return BookingCheckoutResult(
      booking: booking,
      paymentId: data['paymentId'] as String?,
      requiresPayment: data['requiresPayment'] == true,
    );
  }

  @override
  Future<Booking> confirmPayment({
    required String bookingId,
    required String paymentId,
    required PaymentMethod method,
  }) async {
    try {
      final data = await _callables.call('confirmBookingPayment', {
        'bookingId': bookingId,
        'paymentId': paymentId,
        'method': method.name,
      });
      final snap = await _db.doc(FirestorePaths.booking(bookingId)).get();
      if (snap.exists) {
        return _bookingFromMap(bookingId, snap.data()!);
      }
      return _bookingFromMap(bookingId, Map<String, dynamic>.from(data));
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _callables.call('cancelBooking', {'bookingId': bookingId});
  }

  @override
  Future<void> setListenerAvailability({
    required String listenerId,
    required bool availableNow,
  }) async {
    await _callables.call('setListenerAvailability', {
      'availableNow': availableNow,
    });
  }
}
