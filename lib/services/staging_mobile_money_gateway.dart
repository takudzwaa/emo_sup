import '../domain/repositories/payment_gateway.dart';
import '../models/payment_method.dart';
import '../models/payment_result.dart';
import 'payment_service.dart';

/// Phase B staging adapter for Zimbabwe mobile money (PR 23).
///
/// **Not production EcoCash/OneMoney/InnBucks.** This gateway:
/// - Documents selection criteria for the eventual named aggregator
/// - Uses sandbox success rules identical to [FakePaymentGateway] until
///   merchant credentials exist
/// - Tags ledger purpose with `staging_mm` for field testing
///
/// ### Provider selection criteria (commercial decision still open)
/// 1. Coverage: EcoCash + OneMoney + InnBucks (or clear path to all three)
/// 2. Settlement currency: USD and/or ZiG with explicit pilot choice
/// 3. Webhook reliability + idempotent payment ids
/// 4. KYC / merchant onboarding fit for NGO or local entity
/// 5. USSD vs redirect UX acceptable on low-end Android / intermittent data
///
/// Candidates to evaluate: Paynow, direct EcoCash API, Flutterwave/Pesapal if
/// ZW rails meet (1)–(5). Do not hardcode a brand until contracts + sandbox
/// keys land.
class StagingMobileMoneyGateway implements PaymentGateway {
  StagingMobileMoneyGateway({
    PaymentService? delegate,
    this.providerLabel = 'staging_mm_unspecified',
  }) : _delegate = delegate ?? PaymentService(delay: Duration.zero);

  final PaymentService _delegate;

  /// Placeholder until a named provider is chosen.
  final String providerLabel;

  /// Field-test notes surface for ops.
  List<String> get fieldNotes => [
        'Sandbox only — no real charges.',
        'Success: card 4242… or MM PIN 0000 / even last phone digit.',
        'Decline: card 4000… or PIN 9999.',
        'Replace $providerLabel after commercial decision; keep webhook idempotency.',
      ];

  List<PaymentLedgerEntry> get ledger => _delegate.ledger;

  @override
  Future<PaymentResult> charge({
    required PaymentMethod method,
    required int amountCents,
    String purpose = 'booking',
    String? bookingId,
    String? cardNumber,
    String? exp,
    String? cvc,
    String? phone,
    String? pin,
  }) async {
    final result = await _delegate.charge(
      method: method,
      amountCents: amountCents,
      purpose: '${purpose}_$providerLabel',
      bookingId: bookingId,
      cardNumber: cardNumber,
      exp: exp,
      cvc: cvc,
      phone: phone,
      pin: pin,
    );
    if (!result.isSuccess) return result;
    return PaymentResult(
      status: result.status,
      message: '${result.message} [$providerLabel sandbox]',
      method: result.method,
    );
  }

  @override
  Future<PaymentResult> subscribe({
    required PaymentMethod method,
    required int amountCents,
    String? cardNumber,
    String? exp,
    String? cvc,
    String? phone,
    String? pin,
  }) async {
    final result = await _delegate.subscribe(
      method: method,
      amountCents: amountCents,
      cardNumber: cardNumber,
      exp: exp,
      cvc: cvc,
      phone: phone,
      pin: pin,
    );
    if (!result.isSuccess) return result;
    return PaymentResult(
      status: result.status,
      message: '${result.message} [$providerLabel sandbox]',
      method: result.method,
    );
  }
}
