import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/crisis/crisis_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ZW EN crisis pack loads with partner sign-off', () async {
    final pack = await CrisisPackLoader.loadEnZw();
    expect(pack.isSignedOff, isTrue);
    expect(pack.locale, 'en');
    expect(pack.region, 'ZW');
    expect(pack.resources, isNotEmpty);
    expect(pack.resources.any((r) => r.tel == '999'), isTrue);
    expect(pack.disclaimer.toLowerCase(), contains('not an emergency'));
  });
}
