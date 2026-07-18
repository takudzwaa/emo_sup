import 'auth/auth_service.dart';
import 'config/app_flavor.dart';
import 'domain/repositories/booking_repository.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/listener_directory_repository.dart';
import 'domain/repositories/listener_ops_repository.dart';
import 'domain/repositories/match_repository.dart';
import 'domain/repositories/membership_repository.dart';
import 'domain/repositories/mood_repository.dart';
import 'domain/repositories/safety_repository.dart';
import 'domain/repositories/user_profile_repository.dart';

/// Composition root for the app — auth + domain repositories.
///
/// Built by [createAppServices] in `firebase_bootstrap.dart`.
/// Screens continue to take concrete `*Store` façades; stores hold these
/// repositories for I/O.
class AppServices {
  const AppServices({
    required this.flavor,
    required this.auth,
    required this.profiles,
    required this.moods,
    required this.bookings,
    required this.listeners,
    required this.membership,
    required this.chats,
    required this.listenerOps,
    required this.safety,
    required this.match,
    this.firebaseReady = false,
  });

  final AppFlavor flavor;
  final AuthService auth;
  final UserProfileRepository profiles;
  final MoodRepository moods;
  final BookingRepository bookings;
  final ListenerDirectoryRepository listeners;
  final MembershipRepository membership;
  final ChatRepository chats;
  final ListenerOpsRepository listenerOps;
  final SafetyRepository safety;
  final MatchRepository match;

  /// True when Firebase.initializeApp succeeded (staging/prod path).
  final bool firebaseReady;
}
