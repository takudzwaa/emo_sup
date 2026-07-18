import '../../models/user_profile.dart';

/// I/O for app profiles: `users/{uid}` (no email/phone/legalName).
abstract class UserProfileRepository {
  Future<UserProfile?> getProfile(String uid);

  Stream<UserProfile?> watchProfile(String uid);

  Future<void> upsertProfile(UserProfile profile);

  Future<void> deleteProfile(String uid);
}
