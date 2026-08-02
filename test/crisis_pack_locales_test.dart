import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/crisis/crisis_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('en, sn, and nd packs have the expected resource content', () async {
    for (final lang in ['en', 'sn', 'nd']) {
      final path = CrisisPackLoader.assetPathForLocale(lang);
      final raw = await rootBundle.loadString(path);
      final pack =
          CrisisPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(pack.locale, lang);
      expect(pack.region, 'ZW');
      expect(pack.resources, isNotEmpty);
      expect(pack.resources.any((r) => r.tel == '999'), isTrue);
    }
  });

  test(
    'loader refuses to ship any current pilot locale pack (placeholder sign-off)',
    () async {
      // Honest current state: all three locale packs still carry a
      // PILOT-PLACEHOLDER partner sign-off pending real local-partner
      // review, so the hard gate must refuse to load them. Update this
      // per-locale once that locale's real sign-off lands.
      for (final lang in ['en', 'sn', 'nd']) {
        await expectLater(
          CrisisPackLoader.loadForLocale(lang),
          throwsA(isA<StateError>()),
          reason: lang,
        );
      }
    },
  );
}
