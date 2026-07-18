import '../../models/payment_method.dart';
import '../../models/payment_result.dart';

/// Payment gateway port (PR 14 Phase A).
///
/// **Phase A:** [FakePaymentGateway] — no real charges.
/// **Phase B:** named ZW MM aggregator (Paynow / EcoCash / etc.) after commercial
/// decision — selection criteria: EcoCash + OneMoney + InnBucks coverage,
/// USD/ZiG settlement, reliable webhooks, KYC fit for pilot NGO.
abstract class PaymentGateway {
  Future<PaymentResult> charge({
    required PaymentMethod method,
    required int amountCents,
    String purpose, // booking | membership
    String? bookingId,
    String? cardNumber,
    String? exp,
    String? cvc,
    String? phone,
    String? pin,
  });

  Future<PaymentResult> subscribe({
    required PaymentMethod method,
    required int amountCents,
    String? cardNumber,
    String? exp,
    String? cvc,
    String? phone,
    String? pin,
  });
}

/// In-memory ledger entry for Phase A audit trail.
class PaymentLedgerEntry {
  PaymentLedgerEntry({
    required this.id,
    required this.amountCents,
    required this.method,
    required this.status,
    required this.purpose,
    this.bookingId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final int amountCents;
  final PaymentMethod method;
  final PaymentStatus status;
  final String purpose;
  final String? bookingId;
  final DateTime createdAt;
}
