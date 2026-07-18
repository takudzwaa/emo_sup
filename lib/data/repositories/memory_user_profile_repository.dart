import 'dart:async';

import '../../domain/repositories/user_profile_repository.dart';
import '../../models/user_profile.dart';

/// In-memory user profiles for prototype + tests.
class MemoryUserProfileRepository implements UserProfileRepository {
  MemoryUserProfileRepository({Map<String, UserProfile>? seed})
      : _profiles = Map<String, UserProfile>.from(seed ?? {});

  final Map<String, UserProfile> _profiles;
  final _controllers = <String, StreamController<UserProfile?>>{};

  void _emit(String uid) {
    final c = _controllers[uid];
    if (c != null && !c.isClosed) {
      c.add(_profiles[uid]);
    }
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => _profiles[uid];

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    final controller = _controllers.putIfAbsent(
      uid,
      () => StreamController<UserProfile?>.broadcast(),
    );
    // Emit current value asynchronously so subscribers receive it.
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(_profiles[uid]);
    });
    return controller.stream;
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    _profiles[profile.uid] = profile;
    _emit(profile.uid);
  }

  @override
  Future<void> deleteProfile(String uid) async {
    _profiles.remove(uid);
    _emit(uid);
  }
}
