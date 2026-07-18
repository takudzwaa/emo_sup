import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/config/discreet_settings.dart';
import 'package:emo_sup/data/local/settings_store.dart';
import 'package:emo_sup/domain/repositories/notification_service.dart';

void main() {
  test('discreet mode forces notification bodies off', () async {
    final notifications = MemoryNotificationService(allowBodies: true);
    final settings = DiscreetSettings(
      store: MemorySettingsStore(),
      notifications: notifications,
    );
    await settings.load();
    expect(settings.displayAppTitle, 'Emo Sup');

    await settings.setDiscreetMode(true);
    expect(settings.discreetMode, isTrue);
    expect(settings.displayAppTitle, 'Notes');
    expect(notifications.allowNotificationBodies, isFalse);
  });

  test('app lock requires valid pin and unlocks', () async {
    final settings = DiscreetSettings(store: MemorySettingsStore());
    await settings.load();

    expect(await settings.enableAppLock('12'), isFalse);
    expect(await settings.enableAppLock('1234'), isTrue);
    expect(settings.appLockEnabled, isTrue);
    expect(settings.isLocked, isFalse);

    settings.lockNow();
    expect(settings.isLocked, isTrue);
    expect(settings.unlock('0000'), isFalse);
    expect(settings.unlock('1234'), isTrue);
    expect(settings.isLocked, isFalse);
  });
}
