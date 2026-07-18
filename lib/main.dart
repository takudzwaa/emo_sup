import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'app_services.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'data/booking_store.dart';
import 'data/membership_store.dart';
import 'data/mood_store.dart';
import 'domain/repositories/match_repository.dart';
import 'firebase_bootstrap.dart';
import 'models/user_profile.dart';
import 'screens/auth/auth_flow.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await createAppServices();
  final authController = AuthController(
    authService: services.auth,
    profileRepository: services.profiles,
  );
  await authController.tryRestoreSession();
  runApp(EmoSupApp.fromServices(services, authController: authController));
}

class EmoSupApp extends StatelessWidget {
  EmoSupApp({
    super.key,
    required this.moodStore,
    required this.authController,
    BookingStore? bookingStore,
    MembershipStore? membershipStore,
    this.services,
  })  : bookingStore = bookingStore ?? BookingStore(),
        membershipStore = membershipStore ?? MembershipStore();

  /// Preferred production/prototype entry: wire stores from [AppServices].
  factory EmoSupApp.fromServices(
    AppServices services, {
    AuthController? authController,
  }) {
    return EmoSupApp(
      services: services,
      moodStore: MoodStore(repository: services.moods),
      bookingStore: BookingStore(
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
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
      home: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          final profile = authController.profile;
          if (profile == null) {
            return AuthFlow(authController: authController);
          }
          return HomeScreen(
            moodStore: moodStore,
            bookingStore: bookingStore,
            membershipStore: membershipStore,
            matchRepository: services?.match,
            userId: profile.uid,
            anonymousUsername: profile.anonymousName,
          );
        },
      ),
    );
  }
}

/// Builds an app for widget tests. Default skips onboarding with a seed profile.
EmoSupApp buildTestApp({
  MoodStore? moodStore,
  AuthController? authController,
  BookingStore? bookingStore,
  MembershipStore? membershipStore,
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
  return EmoSupApp(
    moodStore: moodStore ?? MoodStore(),
    authController: auth,
    bookingStore: bookingStore,
    membershipStore: membershipStore,
  );
}
