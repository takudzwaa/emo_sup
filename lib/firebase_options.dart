// Staging options from FlutterFire; prod options filled by
// tools/firebase_setup_prod.sh (flutterfire configure --project=emo-sup-prod).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'config/app_flavor.dart';

/// Flavor-aware [FirebaseOptions].
///
/// - [AppFlavor.staging] / default → `emo-sup-staging`
/// - [AppFlavor.prod] → `emo-sup-prod` (placeholders until setup script runs)
///
/// Check [DefaultFirebaseOptions.isConfigured] before [Firebase.initializeApp].
class DefaultFirebaseOptions {
  /// True when the active flavor's API keys are not placeholders.
  static bool get isConfigured {
    final key = currentPlatform.apiKey;
    return key.isNotEmpty &&
        key != 'REPLACE_ME' &&
        !key.startsWith('YOUR_');
  }

  static FirebaseOptions get currentPlatform {
    final flavor = AppFlavorConfig.current;
    if (flavor == AppFlavor.prod) {
      return _forPlatform(
        android: prodAndroid,
        ios: prodIos,
        macos: prodMacos,
        web: prodWeb,
        windows: prodWindows,
      );
    }
    // staging + prototype (prototype never initializes Firebase).
    return _forPlatform(
      android: android,
      ios: ios,
      macos: macos,
      web: web,
      windows: windows,
    );
  }

  static FirebaseOptions _forPlatform({
    required FirebaseOptions android,
    required FirebaseOptions ios,
    required FirebaseOptions macos,
    required FirebaseOptions web,
    required FirebaseOptions windows,
  }) {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux — '
          'run tools/firebase_setup.sh / flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- Staging (emo-sup-staging) -------------------------------------------

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyASwcKjHMJEmVdYbgFg6QirbI-glfMp6Ng',
    appId: '1:988752876591:android:2825d62e2eec20c652a2da',
    messagingSenderId: '988752876591',
    projectId: 'emo-sup-staging',
    authDomain: 'emo-sup-staging.firebaseapp.com',
    storageBucket: 'emo-sup-staging.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyASwcKjHMJEmVdYbgFg6QirbI-glfMp6Ng',
    appId: '1:988752876591:android:2825d62e2eec20c652a2da',
    messagingSenderId: '988752876591',
    projectId: 'emo-sup-staging',
    storageBucket: 'emo-sup-staging.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC2EqmDAiDHdJH5TZjZw94t4j_q_-CMKjU',
    appId: '1:988752876591:ios:0975f2a0212f09bb52a2da',
    messagingSenderId: '988752876591',
    projectId: 'emo-sup-staging',
    storageBucket: 'emo-sup-staging.firebasestorage.app',
    iosBundleId: 'com.emosup.emoSup',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC2EqmDAiDHdJH5TZjZw94t4j_q_-CMKjU',
    appId: '1:988752876591:ios:0975f2a0212f09bb52a2da',
    messagingSenderId: '988752876591',
    projectId: 'emo-sup-staging',
    storageBucket: 'emo-sup-staging.firebasestorage.app',
    iosBundleId: 'com.emosup.emoSup',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyASwcKjHMJEmVdYbgFg6QirbI-glfMp6Ng',
    appId: '1:988752876591:android:2825d62e2eec20c652a2da',
    messagingSenderId: '988752876591',
    projectId: 'emo-sup-staging',
    storageBucket: 'emo-sup-staging.firebasestorage.app',
  );

  // --- Production (emo-sup-prod) -------------------------------------------
  // Native configs for store builds: android/app/google-services-prod.json
  // and ios/Runner/GoogleService-Info-Prod.plist (swap in for release or use
  // product flavors). Day-to-day defaults remain staging.

  static const FirebaseOptions prodWeb = FirebaseOptions(
    apiKey: 'AIzaSyBB-GAOwxV-aME55ZOwzR1atV89a6ujwR8',
    appId: '1:385946750640:android:88ce75c6ab94910d61b575',
    messagingSenderId: '385946750640',
    projectId: 'emo-sup-prod',
    authDomain: 'emo-sup-prod.firebaseapp.com',
    storageBucket: 'emo-sup-prod.firebasestorage.app',
  );

  static const FirebaseOptions prodAndroid = FirebaseOptions(
    apiKey: 'AIzaSyBB-GAOwxV-aME55ZOwzR1atV89a6ujwR8',
    appId: '1:385946750640:android:88ce75c6ab94910d61b575',
    messagingSenderId: '385946750640',
    projectId: 'emo-sup-prod',
    storageBucket: 'emo-sup-prod.firebasestorage.app',
  );

  static const FirebaseOptions prodIos = FirebaseOptions(
    apiKey: 'AIzaSyAi01XNysGEiZf0Y98bKB9cGl3uqB51Ou0',
    appId: '1:385946750640:ios:2b88b181be00646b61b575',
    messagingSenderId: '385946750640',
    projectId: 'emo-sup-prod',
    storageBucket: 'emo-sup-prod.firebasestorage.app',
    iosBundleId: 'com.emosup.emoSup',
  );

  static const FirebaseOptions prodMacos = FirebaseOptions(
    apiKey: 'AIzaSyAi01XNysGEiZf0Y98bKB9cGl3uqB51Ou0',
    appId: '1:385946750640:ios:2b88b181be00646b61b575',
    messagingSenderId: '385946750640',
    projectId: 'emo-sup-prod',
    storageBucket: 'emo-sup-prod.firebasestorage.app',
    iosBundleId: 'com.emosup.emoSup',
  );

  static const FirebaseOptions prodWindows = FirebaseOptions(
    apiKey: 'AIzaSyBB-GAOwxV-aME55ZOwzR1atV89a6ujwR8',
    appId: '1:385946750640:android:88ce75c6ab94910d61b575',
    messagingSenderId: '385946750640',
    projectId: 'emo-sup-prod',
    storageBucket: 'emo-sup-prod.firebasestorage.app',
  );
}
