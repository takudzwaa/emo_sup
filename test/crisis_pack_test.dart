import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/crisis/crisis_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ZW EN crisis pack has the expected resource content', () async {
    final raw = await rootBundle.loadString(CrisisPackLoader.enPath);
    final pack = CrisisPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(pack.locale, 'en');
    expect(pack.region, 'ZW');
    expect(pack.resources, isNotEmpty);
    expect(pack.resources.any((r) => r.tel == '999'), isTrue);
    expect(pack.disclaimer.toLowerCase(), contains('not an emergency'));
  });

  test(
    'loader refuses to ship the current pilot pack (placeholder sign-off)',
    () async {
      // The shipped asset is honestly still a pilot placeholder — this is
      // the hard gate working as intended, not a bug. Once a real partner
      // sign-off replaces "PILOT-PLACEHOLDER ..." in the JSON, this test
      // should be updated to assert a successful load instead.
      expect(CrisisPackLoader.loadEnZw, throwsA(isA<StateError>()));
    },
  );

  group('isSignedOff gate', () {
    CrisisPack packWith({required String partner, required String reviewer}) {
      return CrisisPack(
        locale: 'en',
        region: 'ZW',
        version: 'test',
        partnerSignOff: CrisisPartnerSignOff(
          partner: partner,
          signedAt: '2026-01-01',
          reviewer: reviewer,
        ),
        disclaimer: 'test',
        resources: const [],
      );
    }

    test('rejects placeholder markers regardless of case', () {
      expect(
        packWith(partner: 'PILOT-PLACEHOLDER — replace with vetted partner',
                reviewer: 'ops').isSignedOff,
        isFalse,
      );
      expect(
        packWith(partner: 'pilot-placeholder', reviewer: 'ops').isSignedOff,
        isFalse,
      );
      expect(
        packWith(partner: 'Real Partner', reviewer: 'TBD').isSignedOff,
        isFalse,
      );
    });

    test('accepts a plausible real sign-off', () {
      expect(
        packWith(
          partner: 'Zimbabwe National Association for Mental Health',
          reviewer: 'J. Moyo, Clinical Lead',
        ).isSignedOff,
        isTrue,
      );
    });
  });
}
