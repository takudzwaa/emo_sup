import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/booking_repository.dart';
import '../../models/booking.dart';
import '../../models/listener_profile.dart';
import '../../models/payment_method.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Booking _fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final methodName = d['paymentMethod'] as String?;
    return Booking(
      id: (d['id'] as String?) ?? snap.id,
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
  Stream<List<Booking>> watchUserBookings(String userId) {
    return _db
        .collection(FirestorePaths.bookings)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
      return list;
    });
  }

  @override
  Future<List<Booking>> listUserBookings(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.bookings)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
    return list;
  }

  @override
  Future<Booking?> getBooking(String bookingId) async {
    final snap = await _db.doc(FirestorePaths.booking(bookingId)).get();
    if (!snap.exists) return null;
    return _fromDoc(snap);
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
    throw UnsupportedError(
      'Use BookingCheckoutRepository.createBookingCheckout on staging/prod',
    );
  }

  @override
  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newSlotStart,
  }) async {
    throw UnsupportedError('Reschedule via Cloud Function (not yet exposed)');
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    // Client cancel is blocked by rules; use checkout CF cancelBooking.
    throw UnsupportedError('Cancel via BookingCheckoutRepository.cancelBooking');
  }

  @override
  Future<List<TimeSlot>> slotsForListener(
    String listenerId, {
    int days = 7,
  }) async {
    final snap = await _db
        .collection(FirestorePaths.listenerAvailability(listenerId))
        .where('open', isEqualTo: true)
        .get();
    if (snap.docs.isNotEmpty) {
      final slots = <TimeSlot>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        final start = parseTimestamp(d['start']);
        if (start == null) continue;
        slots.add(
          TimeSlot(
            start: start,
            requiresPremium: d['requiresPremium'] == true,
            sponsored: d['sponsored'] == true,
            sponsorId: d['sponsorId'] as String?,
          ),
        );
      }
      slots.sort((a, b) => a.start.compareTo(b.start));
      if (slots.isNotEmpty) return slots;
    }
    // Fallback: generate open slots when availability subcol is empty.
    return _generatedSlots(listenerId, days: days);
  }

  List<TimeSlot> _generatedSlots(String listenerId, {int days = 7}) {
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
