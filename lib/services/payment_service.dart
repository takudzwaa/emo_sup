import '../domain/repositories/payment_gateway.dart';
import '../models/payment_method.dart';
import '../models/payment_result.dart';

/// Demo-only payment gateway. No network. No real charges.
///
/// Implements [PaymentGateway] for Phase A (PR 14). Demo success rules:
/// - Card: number starts with 4242
/// - EcoCash / OneMoney / InnBucks: PIN 0000 or even last phone digit
class PaymentService implements PaymentGateway {
  PaymentService({this.delay = const Duration(milliseconds: 1400)});

  final Duration delay;

  /// In-memory payment ledger (Phase A).
  final List<PaymentLedgerEntry> ledger = [];

  static const sessionPriceCents = 1200; // $12
  static const planPriceCents = 2900; // $29

  int _ledgerSeq = 0;

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
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final result = _evaluate(
      method: method,
      cardNumber: cardNumber,
      phone: phone,
      pin: pin,
      successMessage:
          'Paid \$${(amountCents / 100).toStringAsFixed(0)} via ${method.displayName}',
    );
    _record(
      amountCents: amountCents,
      method: method,
      status: result.status,
      purpose: purpose,
      bookingId: bookingId,
    );
    return result;
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
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final result = _evaluate(
      method: method,
      cardNumber: cardNumber,
      phone: phone,
      pin: pin,
      successMessage: 'Plan activated via ${method.displayName}',
    );
    _record(
      amountCents: amountCents,
      method: method,
      status: result.status,
      purpose: 'membership',
    );
    return result;
  }

  void _record({
    required int amountCents,
    required PaymentMethod method,
    required PaymentStatus status,
    required String purpose,
    String? bookingId,
  }) {
    ledger.add(
      PaymentLedgerEntry(
        id: 'pay_${++_ledgerSeq}',
        amountCents: amountCents,
        method: method,
        status: status,
        purpose: purpose,
        bookingId: bookingId,
      ),
    );
  }

  PaymentResult _evaluate({
    required PaymentMethod method,
    String? cardNumber,
    String? phone,
    String? pin,
    required String successMessage,
  }) {
    final ok = switch (method) {
      PaymentMethod.card =>
        (cardNumber ?? '').replaceAll(' ', '').startsWith('4242'),
      PaymentMethod.ecocash ||
      PaymentMethod.netone ||
      PaymentMethod.innbucks =>
        (pin != null && pin == '0000') ||
            ((phone ?? '').isNotEmpty &&
                pin != '9999' &&
                _lastDigitEven(phone!)),
    };

    if (method == PaymentMethod.card &&
        (cardNumber ?? '').replaceAll(' ', '').startsWith('4000')) {
      return PaymentResult(
        status: PaymentStatus.declined,
        message: 'Card declined (demo). Try 4242…',
        method: method,
      );
    }
    if (pin == '9999') {
      return PaymentResult(
        status: PaymentStatus.declined,
        message: 'Payment declined (demo). Use PIN 0000 to succeed.',
        method: method,
      );
    }

    if (ok) {
      return PaymentResult(
        status: PaymentStatus.success,
        message: successMessage,
        method: method,
      );
    }
    return PaymentResult(
      status: PaymentStatus.declined,
      message: 'Payment declined (demo). Check details and try again.',
      method: method,
    );
  }

  bool _lastDigitEven(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;
    final d = int.tryParse(digits[digits.length - 1]) ?? 1;
    return d.isEven;
  }
}

/// Alias for design-doc naming (PR 14 Phase A).
typedef FakePaymentGateway = PaymentService;
