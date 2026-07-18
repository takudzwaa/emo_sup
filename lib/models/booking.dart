import 'payment_method.dart';

/// Lifecycle of a scheduled session booking (PR 9 state machine).
///
/// Firestore stores snake-ish status strings via [firestoreName].
enum BookingStatus {
  /// Slot held while waiting for MM/card (CF only).
  pendingPayment,

  /// Legacy alias path — map to [pendingPayment] when reading old seeds.
  pending,

  confirmed,
  cancelled,
  completed,
  expired,
}

extension BookingStatusX on BookingStatus {
  String get firestoreName {
    switch (this) {
      case BookingStatus.pendingPayment:
      case BookingStatus.pending:
        return 'pending_payment';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.expired:
        return 'expired';
    }
  }

  static BookingStatus fromFirestore(String? raw) {
    switch (raw) {
      case 'pending_payment':
      case 'pending':
        return BookingStatus.pendingPayment;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'expired':
        return BookingStatus.expired;
      default:
        return BookingStatus.confirmed;
    }
  }
}

/// A scheduled future session with a preferred listener.
///
/// Production: clients only **read**; create/confirm via Cloud Functions.
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
    this.holdExpiresAt,
    this.sponsorId,
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

  /// 'none' | 'paid' | 'plan' | 'free' | 'sponsored' | 'pending'
  final String paymentStatus;

  /// When status is [BookingStatus.pendingPayment], hold TTL end.
  final DateTime? holdExpiresAt;

  /// NGO/sponsor slot id when free via sponsor.
  final String? sponsorId;

  bool get isConfirmed => status == BookingStatus.confirmed;

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
    DateTime? holdExpiresAt,
    String? sponsorId,
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
      holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
      sponsorId: sponsorId ?? this.sponsorId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'listenerId': listenerId,
      'slotStart': slotStart.toIso8601String(),
      'status': status.firestoreName,
      'priceCents': priceCents,
      'currency': currency,
      'planApplied': planApplied,
      'paymentMethod': paymentMethod?.name,
      'paymentStatus': paymentStatus,
      'holdExpiresAt': holdExpiresAt?.toIso8601String(),
      'sponsorId': sponsorId,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    final methodName = map['paymentMethod'] as String?;
    return Booking(
      id: map['id'] as String,
      userId: map['userId'] as String,
      listenerId: map['listenerId'] as String,
      slotStart: DateTime.parse(map['slotStart'] as String),
      status: BookingStatusX.fromFirestore(map['status'] as String?),
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
      holdExpiresAt: map['holdExpiresAt'] != null
          ? DateTime.parse(map['holdExpiresAt'] as String)
          : null,
      sponsorId: map['sponsorId'] as String?,
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
            paymentStatus == other.paymentStatus &&
            holdExpiresAt == other.holdExpiresAt &&
            sponsorId == other.sponsorId;
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
        holdExpiresAt,
        sponsorId,
      );
}
