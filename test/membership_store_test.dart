import 'package:flutter_test/flutter_test.dart';
import 'package:emo_sup/data/membership_store.dart';

void main() {
  test('activatePlan sets hasActivePlan', () {
    final store = MembershipStore();
    expect(store.hasActivePlan, isFalse);
    store.activatePlan();
    expect(store.hasActivePlan, isTrue);
    expect(store.membership.planId, 'plan_monthly_29');
  });
}
