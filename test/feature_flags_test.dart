import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/config/feature_flags.dart';

void main() {
  test('Safety is always available even when other flags off', () {
    final flags = FeatureFlags(
      matchEnabled: false,
      bookingsEnabled: false,
      paymentsEnabled: false,
    );
    expect(flags.safetyAlwaysAvailable, isTrue);
    expect(flags.matchEnabled, isFalse);
  });

  test('applyRemoteMap ignores safety kill keys', () {
    final flags = FeatureFlags();
    flags.applyRemoteMap({
      'match.enabled': false,
      'safety.enabled': false, // must not affect safetyAlwaysAvailable
      'bookings.enabled': false,
    });
    expect(flags.matchEnabled, isFalse);
    expect(flags.bookingsEnabled, isFalse);
    expect(flags.safetyAlwaysAvailable, isTrue);
  });
}
