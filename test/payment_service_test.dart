import 'package:flutter_test/flutter_test.dart';
import 'package:emo_sup/models/payment_method.dart';
import 'package:emo_sup/models/payment_result.dart';
import 'package:emo_sup/services/payment_service.dart';

void main() {
  final service = PaymentService(delay: Duration.zero);

  test('card 4242 succeeds', () async {
    final r = await service.charge(
      method: PaymentMethod.card,
      amountCents: 1200,
      cardNumber: '4242424242424242',
      exp: '12/30',
      cvc: '123',
    );
    expect(r.status, PaymentStatus.success);
  });

  test('card 4000 declines', () async {
    final r = await service.charge(
      method: PaymentMethod.card,
      amountCents: 1200,
      cardNumber: '4000000000000000',
      exp: '12/30',
      cvc: '123',
    );
    expect(r.status, PaymentStatus.declined);
  });

  test('ecocash PIN 0000 succeeds', () async {
    final r = await service.charge(
      method: PaymentMethod.ecocash,
      amountCents: 1200,
      phone: '0772123456',
      pin: '0000',
    );
    expect(r.status, PaymentStatus.success);
  });

  test('ecocash PIN 9999 declines', () async {
    final r = await service.charge(
      method: PaymentMethod.ecocash,
      amountCents: 1200,
      phone: '0772123456',
      pin: '9999',
    );
    expect(r.status, PaymentStatus.declined);
  });

  test('subscribe success activates result message', () async {
    final r = await service.subscribe(
      method: PaymentMethod.innbucks,
      amountCents: 2900,
      phone: '0772000000',
      pin: '0000',
    );
    expect(r.status, PaymentStatus.success);
  });
}
