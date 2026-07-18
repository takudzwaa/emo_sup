import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app_services.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'config/app_flavor.dart';
import 'config/discreet_settings.dart';
import 'config/feature_flags.dart';
import 'config/listener_role.dart';
import 'data/local/settings_store.dart';
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
import 'domain/repositories/payment_gateway.dart';
import 'services/analytics_service.dart';
import 'services/app_check_service.dart';
import 'services/membership_activation_service.dart';
import 'services/payment_service.dart';
import 'services/staging_mobile_money_gateway.dart';

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
/// Crashlytics / real FCM stay deferred until a Firebase project is linked.
/// App Check is activated via [AppCheckService] for staging/prod flavors.
Future<AppServices> createAppServices({
  AppFlavor? flavorOverride,
  AuthService? authOverride,
}) async {
  final flavor = flavorOverride ?? AppFlavorConfig.current;
  debugPrint('App flavor: ${flavor.name}');

  if (flavor == AppFlavor.prototype) {
    final services = await _memoryServices(
      flavor: flavor,
      auth: authOverride ?? PrototypeAuthService(),
      firebaseReady: false,
    );
    await services.appCheck.activate();
    return services;
  }

  // staging / prod path
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('Firebase initialized — using FirebaseAuthService');
    final services = await _memoryServices(
      flavor: flavor,
      auth: authOverride ?? FirebaseAuthService(),
      firebaseReady: true,
    );
    await services.appCheck.activate();
    return services;
  } catch (e, st) {
    debugPrint(
      'Firebase not configured ($e). Falling back to prototype stack.\n$st',
    );
    final services = await _memoryServices(
      flavor: AppFlavor.prototype,
      auth: authOverride ?? PrototypeAuthService(),
      firebaseReady: false,
    );
    await services.appCheck.activate();
    return services;
  }
}

/// Backward-compatible helper used by older call sites / tests.
Future<AuthService> createAuthService() async {
  final services = await createAppServices();
  return services.auth;
}

Future<AppServices> _memoryServices({
  required AppFlavor flavor,
  required AuthService auth,
  required bool firebaseReady,
}) async {
  final listeners = MemoryListenerDirectoryRepository();
  final chats = MemoryChatRepository.withDemoSession();
  final listenerOps = MemoryListenerOpsRepository();
  final profiles = MemoryUserProfileRepository();
  final memberships = MemoryMembershipRepository();
  final notifications = MemoryNotificationService();
  // Phase A default: Fake. Phase B staging: set FLAVOR=staging and use MM gateway.
  final PaymentGateway payments = flavor == AppFlavor.staging
      ? StagingMobileMoneyGateway()
      : PaymentService(delay: Duration.zero);
  final discreet = DiscreetSettings(
    store: MemorySettingsStore(),
    notifications: notifications,
  );
  return AppServices(
    flavor: flavor,
    auth: auth,
    profiles: profiles,
    moods: MemoryMoodRepository(),
    bookings: MemoryBookingRepository(),
    listeners: listeners,
    membership: memberships,
    chats: chats,
    listenerOps: listenerOps,
    safety: MemorySafetyRepository(chats: chats, profiles: profiles),
    match: MemoryMatchRepository(listeners: listeners, chats: chats),
    bookingCheckout: MemoryBookingCheckoutRepository(listenerOps: listenerOps),
    notifications: notifications,
    payments: payments,
    featureFlags: FeatureFlags(),
    listenerRoleGate: ListenerRoleGate(),
    discreetSettings: discreet,
    membershipActivation: MembershipActivationService(
      memberships: memberships,
      payments: payments,
    ),
    analytics: MemoryAnalyticsService(),
    appCheck: MemoryAppCheckService(flavor: flavor),
    firebaseReady: firebaseReady,
  );
}
