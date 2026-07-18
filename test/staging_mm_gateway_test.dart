import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/models/payment_method.dart';
import 'package:emo_sup/services/staging_mobile_money_gateway.dart';

void main() {
  test('staging MM gateway tags sandbox success messages', () async {
    final gw = StagingMobileMoneyGateway(providerLabel: 'paynow_sandbox');
    final result = await gw.charge(
      method: PaymentMethod.ecocash,
      amountCents: 1200,
      phone: '0771234568', // even last digit
      pin: '1111',
    );
    expect(result.isSuccess, isTrue);
    expect(result.message, contains('paynow_sandbox'));
    expect(gw.fieldNotes, isNotEmpty);
  });

  test('staging MM gateway declines with 9999 pin', () async {
    final gw = StagingMobileMoneyGateway();
    final result = await gw.charge(
      method: PaymentMethod.ecocash,
      amountCents: 1200,
      phone: '0771234567',
      pin: '9999',
    );
    expect(result.isSuccess, isFalse);
  });
}
