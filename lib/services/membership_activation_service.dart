import '../domain/repositories/membership_repository.dart';
import '../domain/repositories/payment_gateway.dart';
import '../models/membership.dart';
import '../models/payment_method.dart';
import '../models/payment_result.dart';
import 'payment_service.dart';

/// Server-style membership activation (PR 22).
///
/// Production: CF / webhook writes `memberships/{uid}` only after payment
/// settles. Client never trusts local-only plan flags for premium access
/// without a server membership doc.
class MembershipActivationService {
  MembershipActivationService({
    required this.memberships,
    required this.payments,
  });

  final MembershipRepository memberships;
  final PaymentGateway payments;

  static const planIdMonthly = 'plan_monthly_29';

  /// Charge then activate membership (atomic from client POV).
  Future<MembershipActivationResult> subscribe({
    required String userId,
    required PaymentMethod method,
    String planId = planIdMonthly,
    int amountCents = PaymentService.planPriceCents,
    String? cardNumber,
    String? exp,
    String? cvc,
    String? phone,
    String? pin,
  }) async {
    final payment = await payments.subscribe(
      method: method,
      amountCents: amountCents,
      cardNumber: cardNumber,
      exp: exp,
      cvc: cvc,
      phone: phone,
      pin: pin,
    );
    if (!payment.isSuccess) {
      return MembershipActivationResult.failed(payment);
    }

    final membership = await memberships.activatePlan(
      userId: userId,
      planId: planId,
    );
    return MembershipActivationResult.success(
      membership: membership,
      payment: payment,
    );
  }
}

class MembershipActivationResult {
  MembershipActivationResult._({
    required this.ok,
    this.membership,
    required this.payment,
  });

  factory MembershipActivationResult.success({
    required Membership membership,
    required PaymentResult payment,
  }) =>
      MembershipActivationResult._(
        ok: true,
        membership: membership,
        payment: payment,
      );

  factory MembershipActivationResult.failed(PaymentResult payment) =>
      MembershipActivationResult._(ok: false, payment: payment);

  final bool ok;
  final Membership? membership;
  final PaymentResult payment;
}
