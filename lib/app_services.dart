import 'auth/auth_service.dart';
import 'config/app_flavor.dart';
import 'config/discreet_settings.dart';
import 'config/feature_flags.dart';
import 'config/listener_role.dart';
import 'domain/repositories/booking_checkout_repository.dart';
import 'domain/repositories/booking_repository.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/listener_directory_repository.dart';
import 'domain/repositories/listener_ops_repository.dart';
import 'domain/repositories/match_repository.dart';
import 'domain/repositories/membership_repository.dart';
import 'domain/repositories/mood_repository.dart';
import 'domain/repositories/notification_service.dart';
import 'domain/repositories/payment_gateway.dart';
import 'domain/repositories/safety_repository.dart';
import 'domain/repositories/user_profile_repository.dart';
import 'services/membership_activation_service.dart';
import 'services/payment_service.dart';

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
    required this.bookingCheckout,
    required this.notifications,
    required this.payments,
    required this.featureFlags,
    required this.listenerRoleGate,
    required this.discreetSettings,
    required this.membershipActivation,
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
  final BookingCheckoutRepository bookingCheckout;
  final NotificationService notifications;
  final PaymentGateway payments;
  final FeatureFlags featureFlags;
  final ListenerRoleGate listenerRoleGate;
  final DiscreetSettings discreetSettings;
  final MembershipActivationService membershipActivation;

  /// True when Firebase.initializeApp succeeded (staging/prod path).
  final bool firebaseReady;
}
