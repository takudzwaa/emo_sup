import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/listener_directory_repository.dart';
import '../../models/listener_profile.dart';
import '../firebase/firestore_paths.dart';

class FirestoreListenerDirectoryRepository
    implements ListenerDirectoryRepository {
  FirestoreListenerDirectoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  ListenerProfile _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final langs = (d['languages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['English'];
    return ListenerProfile(
      id: (d['id'] as String?) ?? doc.id,
      displayName: (d['displayName'] as String?) ?? 'Listener',
      bio: (d['bio'] as String?) ?? '',
      languages: langs,
      tier: ListenerTier.values.firstWhere(
        (t) => t.name == d['tier'],
        orElse: () => ListenerTier.standard,
      ),
    );
  }

  @override
  Future<List<ListenerProfile>> listListeners() async {
    final snap = await _db.collection(FirestorePaths.listenerPublic).get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Stream<List<ListenerProfile>> watchListeners() {
    return _db
        .collection(FirestorePaths.listenerPublic)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<ListenerProfile?> getListener(String listenerId) async {
    final snap =
        await _db.doc('${FirestorePaths.listenerPublic}/$listenerId').get();
    if (!snap.exists) return null;
    return _fromDoc(snap);
  }
}
