import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/config/app_flavor.dart';
import 'package:emo_sup/services/app_check_service.dart';

void main() {
  test('prototype does not enforce by default', () async {
    final s = MemoryAppCheckService(flavor: AppFlavor.prototype);
    await s.activate();
    expect(s.enforcementEnabled, isFalse);
    expect(s.isActivated, isTrue);
  });

  test('prod enables enforcement flag', () async {
    final s = MemoryAppCheckService(flavor: AppFlavor.prod);
    await s.activate();
    expect(s.enforcementEnabled, isTrue);
    expect(await s.getDebugTokenHint(), isNull);
  });

  test('staging exposes debug token hint', () async {
    final s = MemoryAppCheckService(flavor: AppFlavor.staging);
    await s.activate();
    expect(await s.getDebugTokenHint(), isNotNull);
  });
}
