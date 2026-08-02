import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/user_profile_repository.dart';
import '../../models/user_profile.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.doc(FirestorePaths.user(uid));

  UserProfile? _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return null;
    return UserProfile(
      uid: (data['uid'] as String?) ?? snap.id,
      anonymousName: (data['anonymousName'] as String?) ?? 'Anonymous',
      authMethod: AuthMethod.values.firstWhere(
        (m) => m.name == data['authMethod'],
        orElse: () => AuthMethod.email,
      ),
      createdAt: requireTimestamp(data['createdAt'], fallback: DateTime.now()),
    );
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _doc(uid).get();
    return _fromSnap(snap);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map(_fromSnap);
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    await _doc(profile.uid).set({
      'uid': profile.uid,
      'anonymousName': profile.anonymousName,
      'authMethod': profile.authMethod.name,
      'createdAt': toTimestamp(profile.createdAt),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteProfile(String uid) async {
    await _doc(uid).delete();
  }
}
