import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'data/booking_store.dart';
import 'data/membership_store.dart';
import 'data/mood_store.dart';
import 'firebase_bootstrap.dart';
import 'models/user_profile.dart';
import 'screens/auth/auth_flow.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = await createAuthService();
  runApp(
    EmoSupApp(
      moodStore: MoodStore(),
      authController: AuthController(authService: authService),
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
  })  : bookingStore = bookingStore ?? BookingStore(),
        membershipStore = membershipStore ?? MembershipStore();

  final MoodStore moodStore;
  final AuthController authController;
  final BookingStore bookingStore;
  final MembershipStore membershipStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emo Sup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
