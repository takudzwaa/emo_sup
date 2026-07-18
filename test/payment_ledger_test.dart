import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/models/payment_method.dart';
import 'package:emo_sup/models/payment_result.dart';
import 'package:emo_sup/services/payment_service.dart';

void main() {
  test('FakePaymentGateway records ledger on charge', () async {
    final gateway = PaymentService(delay: Duration.zero);
    final result = await gateway.charge(
      method: PaymentMethod.card,
      amountCents: 1200,
      purpose: 'booking',
      bookingId: 'b1',
      cardNumber: '4242 4242 4242 4242',
    );
    expect(result.isSuccess, isTrue);
    expect(gateway.ledger.length, 1);
    expect(gateway.ledger.single.bookingId, 'b1');
    expect(gateway.ledger.single.status, PaymentStatus.success);
  });
}
