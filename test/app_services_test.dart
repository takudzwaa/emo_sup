import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/auth/auth_service.dart';
import 'package:emo_sup/config/app_flavor.dart';
import 'package:emo_sup/data/repositories/memory_mood_repository.dart';
import 'package:emo_sup/firebase_bootstrap.dart';

void main() {
  test('createAppServices prototype uses memory stack', () async {
    final services = await createAppServices(
      flavorOverride: AppFlavor.prototype,
    );
    expect(services.flavor, AppFlavor.prototype);
    expect(services.firebaseReady, isFalse);
    expect(services.auth, isA<PrototypeAuthService>());
    expect(services.moods, isA<MemoryMoodRepository>());
    expect(services.chats, isNotNull);
    expect(services.safety, isNotNull);
  });

  test('createAuthService still returns AuthService', () async {
    final auth = await createAuthService();
    expect(auth, isA<AuthService>());
  });
}
