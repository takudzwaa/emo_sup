import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app_services.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'config/app_flavor.dart';
import 'config/feature_flags.dart';
import 'config/listener_role.dart';
import 'data/repositories/memory_booking_checkout_repository.dart';
import 'data/repositories/memory_booking_repository.dart';
import 'data/repositories/memory_chat_repository.dart';
import 'data/repositories/memory_listener_directory_repository.dart';
import 'data/repositories/memory_listener_ops_repository.dart';
import 'data/repositories/memory_match_repository.dart';
import 'data/repositories/memory_membership_repository.dart';
import 'data/repositories/memory_mood_repository.dart';
import 'data/repositories/memory_safety_repository.dart';
import 'data/repositories/memory_user_profile_repository.dart';
import 'domain/repositories/notification_service.dart';
import 'services/payment_service.dart';

/// Composition root: flavor + auth + domain repositories.
///
/// - [AppFlavor.prototype] (default): [PrototypeAuthService] + memory repos.
/// - staging/prod: attempts Firebase.initializeApp; falls back to prototype
///   stack if the project is not linked yet.
///
/// Wire a project with:
/// ```
/// dart pub global activate flutterfire_cli
/// flutterfire configure
/// flutter run --dart-define=FLAVOR=staging
/// ```
///
/// Crashlytics / real FCM / App Check init stay deferred until a Firebase
/// project is linked. [MemoryNotificationService] provides the PR 12 policy
/// surface (no chat bodies) without requiring `firebase_messaging` at runtime.
Future<AppServices> createAppServices({
  AppFlavor? flavorOverride,
  AuthService? authOverride,
}) async {
  final flavor = flavorOverride ?? AppFlavorConfig.current;
  debugPrint('App flavor: ${flavor.name}');

  if (flavor == AppFlavor.prototype) {
    return _memoryServices(
      flavor: flavor,
      auth: authOverride ?? PrototypeAuthService(),
      firebaseReady: false,
    );
  }

  // staging / prod path
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('Firebase initialized — using FirebaseAuthService');
    // Memory repos until Firestore-backed adapters land (later PRs).
    // Auth is real so phone/email work against the linked project.
    return _memoryServices(
      flavor: flavor,
      auth: authOverride ?? FirebaseAuthService(),
      firebaseReady: true,
    );
  } catch (e, st) {
    debugPrint(
      'Firebase not configured ($e). Falling back to prototype stack.\n$st',
    );
    return _memoryServices(
      flavor: AppFlavor.prototype,
      auth: authOverride ?? PrototypeAuthService(),
      firebaseReady: false,
    );
  }
}

/// Backward-compatible helper used by older call sites / tests.
Future<AuthService> createAuthService() async {
  final services = await createAppServices();
  return services.auth;
}

AppServices _memoryServices({
  required AppFlavor flavor,
  required AuthService auth,
  required bool firebaseReady,
}) {
  final listeners = MemoryListenerDirectoryRepository();
  final chats = MemoryChatRepository.withDemoSession();
  final listenerOps = MemoryListenerOpsRepository();
  final profiles = MemoryUserProfileRepository();
  return AppServices(
    flavor: flavor,
    auth: auth,
    profiles: profiles,
    moods: MemoryMoodRepository(),
    bookings: MemoryBookingRepository(),
    listeners: listeners,
    membership: MemoryMembershipRepository(),
    chats: chats,
    listenerOps: listenerOps,
    safety: MemorySafetyRepository(chats: chats, profiles: profiles),
    match: MemoryMatchRepository(listeners: listeners, chats: chats),
    bookingCheckout: MemoryBookingCheckoutRepository(listenerOps: listenerOps),
    notifications: MemoryNotificationService(),
    payments: PaymentService(delay: Duration.zero),
    featureFlags: FeatureFlags(),
    listenerRoleGate: ListenerRoleGate(),
    firebaseReady: firebaseReady,
  );
}
