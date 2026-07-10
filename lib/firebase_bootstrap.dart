import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';

/// Tries real Firebase; falls back to prototype auth when no project is linked.
///
/// Wire a project with:
/// ```
/// dart pub global activate flutterfire_cli
/// flutterfire configure
/// ```
/// then call `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
Future<AuthService> createAuthService() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('Firebase initialized — using FirebaseAuthService');
    return FirebaseAuthService();
  } catch (e, st) {
    debugPrint(
      'Firebase not configured ($e). Using PrototypeAuthService.\n$st',
    );
    return PrototypeAuthService();
  }
}
