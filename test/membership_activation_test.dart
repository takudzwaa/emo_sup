import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/repositories/memory_membership_repository.dart';
import 'package:emo_sup/models/payment_method.dart';
import 'package:emo_sup/services/membership_activation_service.dart';
import 'package:emo_sup/services/payment_service.dart';

void main() {
  test('subscribe activates membership after successful payment', () async {
    final memberships = MemoryMembershipRepository();
    final payments = PaymentService(delay: Duration.zero);
    final service = MembershipActivationService(
      memberships: memberships,
      payments: payments,
    );

    final result = await service.subscribe(
      userId: 'u1',
      method: PaymentMethod.card,
      cardNumber: '4242424242424242',
    );
    expect(result.ok, isTrue);
    expect(result.membership?.hasActivePlan, isTrue);
    final stored = await memberships.getMembership('u1');
    expect(stored.hasActivePlan, isTrue);
  });

  test('subscribe fails without activating on decline', () async {
    final memberships = MemoryMembershipRepository();
    final service = MembershipActivationService(
      memberships: memberships,
      payments: PaymentService(delay: Duration.zero),
    );

    final result = await service.subscribe(
      userId: 'u1',
      method: PaymentMethod.card,
      cardNumber: '4000000000000000',
    );
    expect(result.ok, isFalse);
    final stored = await memberships.getMembership('u1');
    expect(stored.hasActivePlan, isFalse);
  });
}
