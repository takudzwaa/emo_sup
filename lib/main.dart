import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'app_services.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'config/discreet_settings.dart';
import 'data/booking_store.dart';
import 'data/chat_store.dart';
import 'data/membership_store.dart';
import 'data/mood_store.dart';
import 'firebase_bootstrap.dart';
import 'models/user_profile.dart';
import 'screens/app_lock_screen.dart';
import 'screens/auth/auth_flow.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'services/fcm_notification_service.dart';
import 'theme/app_theme.dart';

/// Root navigator — lets notification taps push routes from outside widgets.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await createAppServices();
  await services.discreetSettings.load();
  final authController = AuthController(
    authService: services.auth,
    profileRepository: services.profiles,
  );
  await authController.tryRestoreSession();
  final uid = authController.profile?.uid ?? services.auth.currentUid;
  if (uid != null && services.firebaseReady) {
    await services.notifications.registerToken(uid);
  }
  final notifications = services.notifications;
  if (services.firebaseReady && notifications is FcmNotificationService) {
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);
    await notifications.configureMessageHandling(
      onTap: (data) => _openChatFromNotification(services, data),
    );
  }
  runApp(EmoSupApp.fromServices(services, authController: authController));
}

Future<void> _openChatFromNotification(
  AppServices services,
  Map<String, Object?> data,
) async {
  final sessionId = data['sessionId']?.toString();
  if (sessionId == null || sessionId.isEmpty) return;
  final session = await services.chats.getSession(sessionId);
  if (session == null) return;
  appNavigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        chatStore: ChatStore(
          session: session,
          repository: services.chats,
          actingAsId: session.userId,
        ),
      ),
    ),
  );
}

class EmoSupApp extends StatelessWidget {
  EmoSupApp({
    super.key,
    required this.moodStore,
    required this.authController,
    BookingStore? bookingStore,
    MembershipStore? membershipStore,
    this.services,
    DiscreetSettings? discreetSettings,
  })  : bookingStore = bookingStore ?? BookingStore(),
        membershipStore = membershipStore ?? MembershipStore(),
        discreetSettings = discreetSettings ?? DiscreetSettings();

  /// Preferred production/prototype entry: wire stores from [AppServices].
  factory EmoSupApp.fromServices(
    AppServices services, {
    AuthController? authController,
  }) {
    final uid = authController?.profile?.uid ??
        services.auth.currentUid ??
        'user_quiet_river';
    return EmoSupApp(
      services: services,
      discreetSettings: services.discreetSettings,
      moodStore: MoodStore(repository: services.moods, userId: uid),
      bookingStore: BookingStore(
        currentUserId: uid,
        bookingRepository: services.bookings,
        listenerDirectory: services.listeners,
      ),
      membershipStore: MembershipStore(repository: services.membership),
      authController: authController ??
          AuthController(
            authService: services.auth,
            profileRepository: services.profiles,
          ),
    );
  }

  final MoodStore moodStore;
  final AuthController authController;
  final BookingStore bookingStore;
  final MembershipStore membershipStore;
  final AppServices? services;
  final DiscreetSettings discreetSettings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([authController, discreetSettings]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          onGenerateTitle: (context) => discreetSettings.displayAppTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: _home(),
        );
      },
    );
  }

  Widget _home() {
    if (discreetSettings.isLocked) {
      return AppLockScreen(settings: discreetSettings);
    }
    final profile = authController.profile;
    if (profile == null) {
      return AuthFlow(authController: authController);
    }
    return HomeScreen(
      moodStore: moodStore,
      bookingStore: bookingStore,
      membershipStore: membershipStore,
      matchRepository: services?.match,
      chatRepository: services?.chats,
      featureFlags: services?.featureFlags,
      safetyRepository: services?.safety,
      discreetSettings: discreetSettings,
      analytics: services?.analytics,
      userId: profile.uid,
      anonymousUsername: profile.anonymousName,
    );
  }
}

/// Builds an app for widget tests. Default skips onboarding with a seed profile.
EmoSupApp buildTestApp({
  MoodStore? moodStore,
  AuthController? authController,
  BookingStore? bookingStore,
  MembershipStore? membershipStore,
  DiscreetSettings? discreetSettings,
  bool signedIn = true,
}) {
  final auth =
      authController ?? AuthController(authService: PrototypeAuthService());
  if (signedIn && !auth.isAuthenticated) {
    auth.setProfileForTesting(
      UserProfile(
        uid: 'test_uid',
        anonymousName: 'Quiet River',
        authMethod: AuthMethod.email,
        createdAt: DateTime.utc(2026, 7, 1),
      ),
    );
  }
  final discreet = discreetSettings ?? DiscreetSettings();
  // Tests start unlocked unless settings explicitly lock.
  return EmoSupApp(
    moodStore: moodStore ?? MoodStore(),
    authController: auth,
    bookingStore: bookingStore,
    membershipStore: membershipStore,
    discreetSettings: discreet,
  );
}
