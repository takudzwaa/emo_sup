import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'app_services.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'config/app_flavor.dart';
import 'config/discreet_settings.dart';
import 'config/feature_flags.dart';
import 'config/listener_role.dart';
import 'data/local/settings_store.dart';
import 'data/repositories/firestore_booking_checkout_repository.dart';
import 'data/repositories/firestore_booking_repository.dart';
import 'data/repositories/firestore_chat_repository.dart';
import 'data/repositories/firestore_listener_directory_repository.dart';
import 'data/repositories/firestore_listener_ops_repository.dart';
import 'data/repositories/firestore_match_repository.dart';
import 'data/repositories/firestore_membership_repository.dart';
import 'data/repositories/firestore_mood_repository.dart';
import 'data/repositories/firestore_safety_repository.dart';
import 'data/repositories/firestore_user_profile_repository.dart';
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
import 'firebase_options.dart';
import 'services/analytics_service.dart';
import 'services/app_check_service.dart';
import 'services/fcm_notification_service.dart';
import 'services/membership_activation_service.dart';
import 'services/payment_service.dart';
import 'services/staging_mobile_money_gateway.dart';

/// Composition root: flavor + auth + domain repositories.
///
/// - [AppFlavor.prototype]: [PrototypeAuthService] + memory repos + seeds.
/// - staging/prod: Firebase Auth + Firestore + Cloud Functions when configured.
/// - prod fails closed if Firebase is not linked; staging may fall back loudly.
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

  // staging / prod — fail closed. No silent memory fallback: a misconfigured
  // Firebase build must never masquerade as a working environment.
  if (!DefaultFirebaseOptions.isConfigured) {
    throw StateError(
      'Firebase options are placeholders. Run tools/firebase_setup.sh '
      '(flutterfire configure) before FLAVOR=${flavor.name}.',
    );
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  _installCrashHandlers();
  // Enable offline persistence for chat/mood on mobile.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  debugPrint('Firebase initialized — Firestore + Auth stack');
  final services = await _firestoreServices(
    flavor: flavor,
    auth: authOverride ?? FirebaseAuthService(),
  );
  await services.appCheck.activate();
  return services;
}

/// Route uncaught Flutter and platform errors to Crashlytics.
/// Collection is disabled in debug builds so local crashes stay local.
void _installCrashHandlers() {
  final crashlytics = FirebaseCrashlytics.instance;
  // Fire-and-forget: toggling collection must not delay startup.
  crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

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

/// True when the signed-in user's ID token carries `role: listener`.
Future<bool> _firebaseListenerClaim() async {
  final user = fb_auth.FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final token = await user.getIdTokenResult();
  return token.claims?['role'] == 'listener';
}

Future<AppServices> _firestoreServices({
  required AppFlavor flavor,
  required AuthService auth,
}) async {
  final listenerRoleGate = ListenerRoleGate(
    claimResolver: _firebaseListenerClaim,
  );
  await listenerRoleGate.refresh();
  // Claims arrive/leave with sign-in, sign-out, and token refresh.
  fb_auth.FirebaseAuth.instance
      .idTokenChanges()
      .listen((_) => listenerRoleGate.refresh());

  final profiles = FirestoreUserProfileRepository();
  final moods = FirestoreMoodRepository();
  final bookings = FirestoreBookingRepository();
  final listeners = FirestoreListenerDirectoryRepository();
  final memberships = FirestoreMembershipRepository();
  final chats = FirestoreChatRepository();
  final listenerOps = FirestoreListenerOpsRepository();
  final safety = FirestoreSafetyRepository();
  final match = FirestoreMatchRepository();
  final bookingCheckout = FirestoreBookingCheckoutRepository();
  final notifications = FcmNotificationService();
  final PaymentGateway payments = flavor == AppFlavor.staging
      ? StagingMobileMoneyGateway()
      : PaymentService(delay: Duration.zero);
  final discreet = DiscreetSettings(
    store: SharedPreferencesSettingsStore(),
    notifications: notifications,
  );
  return AppServices(
    flavor: flavor,
    auth: auth,
    profiles: profiles,
    moods: moods,
    bookings: bookings,
    listeners: listeners,
    membership: memberships,
    chats: chats,
    listenerOps: listenerOps,
    safety: safety,
    match: match,
    bookingCheckout: bookingCheckout,
    notifications: notifications,
    payments: payments,
    // Payments deferred for launch: real gateway not integrated yet, and the
    // Cloud Functions refuse paid flows while config/payments is disabled.
    featureFlags: FeatureFlags(paymentsEnabled: false),
    listenerRoleGate: listenerRoleGate,
    discreetSettings: discreet,
    membershipActivation: MembershipActivationService(
      memberships: memberships,
      payments: payments,
    ),
    analytics: FirebaseAnalyticsAdapter(),
    appCheck: FirebaseAppCheckService(flavor: flavor),
    firebaseReady: true,
  );
}
