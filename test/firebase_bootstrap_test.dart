import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/firebase_options.dart';
import 'package:emo_sup/firebase_bootstrap.dart';
import 'package:emo_sup/config/app_flavor.dart';
import 'package:emo_sup/data/repositories/memory_chat_repository.dart';

void main() {
  test('firebase_options point at emo-sup-staging by default', () {
    expect(DefaultFirebaseOptions.android.projectId, 'emo-sup-staging');
    expect(DefaultFirebaseOptions.ios.projectId, 'emo-sup-staging');
    expect(DefaultFirebaseOptions.isConfigured, isTrue);
  });

  test('prod firebase options target emo-sup-prod, not staging', () {
    expect(DefaultFirebaseOptions.prodAndroid.projectId, 'emo-sup-prod');
    expect(DefaultFirebaseOptions.prodIos.projectId, 'emo-sup-prod');
    expect(DefaultFirebaseOptions.prodAndroid.projectId,
        isNot(DefaultFirebaseOptions.android.projectId));
    expect(DefaultFirebaseOptions.prodAndroid.apiKey, isNot('REPLACE_ME'));
  });

  test('prototype createAppServices uses memory repos', () async {
    final services = await createAppServices(flavorOverride: AppFlavor.prototype);
    expect(services.firebaseReady, isFalse);
    expect(services.chats, isA<MemoryChatRepository>());
  });
}
