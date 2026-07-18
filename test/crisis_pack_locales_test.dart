import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/crisis/crisis_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads en, sn, and nd packs with partner sign-off', () async {
    for (final lang in ['en', 'sn', 'nd']) {
      final pack = await CrisisPackLoader.loadForLocale(lang);
      expect(pack.isSignedOff, isTrue, reason: lang);
      expect(pack.locale, lang);
      expect(pack.region, 'ZW');
      expect(pack.resources, isNotEmpty);
      expect(pack.resources.any((r) => r.tel == '999'), isTrue);
    }
  });
}
