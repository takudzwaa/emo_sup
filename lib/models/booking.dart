import 'payment_method.dart';

/// Lifecycle of a scheduled session booking.
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

/// A scheduled future session with a preferred listener.
///
/// Firestore (later):
/// ```
/// bookings/{bookingId}
/// ```
class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.listenerId,
    required this.slotStart,
    this.status = BookingStatus.confirmed,
    this.priceCents = 0,
    this.currency = 'USD',
    this.planApplied = false,
    this.paymentMethod,
    this.paymentStatus = 'free',
  });

  final String id;
  final String userId;
  final String listenerId;
  final DateTime slotStart;
  final BookingStatus status;

  /// Session price in minor currency units (cents). Default 0 for free seeds.
  final int priceCents;

  final String currency;

  /// True when an active membership plan covered this booking.
  final bool planApplied;

  final PaymentMethod? paymentMethod;

  /// 'none' | 'paid' | 'plan' | 'free'
  final String paymentStatus;

  Booking copyWith({
    String? id,
    String? userId,
    String? listenerId,
    DateTime? slotStart,
    BookingStatus? status,
    int? priceCents,
    String? currency,
    bool? planApplied,
    PaymentMethod? paymentMethod,
    String? paymentStatus,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listenerId: listenerId ?? this.listenerId,
      slotStart: slotStart ?? this.slotStart,
      status: status ?? this.status,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      planApplied: planApplied ?? this.planApplied,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'listenerId': listenerId,
      'slotStart': slotStart.toIso8601String(),
      'status': status.name,
      'priceCents': priceCents,
      'currency': currency,
      'planApplied': planApplied,
      'paymentMethod': paymentMethod?.name,
      'paymentStatus': paymentStatus,
      // Future Firestore: prefer Timestamp.fromDate(slotStart)
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    final methodName = map['paymentMethod'] as String?;
    return Booking(
      id: map['id'] as String,
      userId: map['userId'] as String,
      listenerId: map['listenerId'] as String,
      slotStart: DateTime.parse(map['slotStart'] as String),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      priceCents: (map['priceCents'] as int?) ?? 0,
      currency: (map['currency'] as String?) ?? 'USD',
      planApplied: (map['planApplied'] as bool?) ?? false,
      paymentMethod: methodName == null
          ? null
          : PaymentMethod.values.firstWhere(
              (m) => m.name == methodName,
              orElse: () => PaymentMethod.card,
            ),
      paymentStatus: (map['paymentStatus'] as String?) ?? 'free',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Booking &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            userId == other.userId &&
            listenerId == other.listenerId &&
            slotStart == other.slotStart &&
            status == other.status &&
            priceCents == other.priceCents &&
            currency == other.currency &&
            planApplied == other.planApplied &&
            paymentMethod == other.paymentMethod &&
            paymentStatus == other.paymentStatus;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        listenerId,
        slotStart,
        status,
        priceCents,
        currency,
        planApplied,
        paymentMethod,
        paymentStatus,
      );
}
