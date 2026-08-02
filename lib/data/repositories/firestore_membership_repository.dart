import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/membership_repository.dart';
import '../../models/membership.dart';
import '../firebase/callable_client.dart';
import '../firebase/firestore_paths.dart';
import '../mappers/timestamp_mapper.dart';

class FirestoreMembershipRepository implements MembershipRepository {
  FirestoreMembershipRepository({
    FirebaseFirestore? firestore,
    CallableClient? callables,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _callables = callables ?? CallableClient();

  final FirebaseFirestore _db;
  final CallableClient _callables;

  Membership _fromData(Map<String, dynamic>? d) {
    if (d == null) return const Membership();
    final tierName = d['tier'] as String?;
    return Membership(
      tier: tierName == 'planActive'
          ? MembershipTier.planActive
          : MembershipTier.free,
      planId: d['planId'] as String?,
      renewsAt: parseTimestamp(d['renewsAt']),
    );
  }

  @override
  Future<Membership> getMembership(String userId) async {
    final snap = await _db.doc(FirestorePaths.membership(userId)).get();
    return _fromData(snap.data());
  }

  @override
  Stream<Membership> watchMembership(String userId) {
    return _db
        .doc(FirestorePaths.membership(userId))
        .snapshots()
        .map((s) => _fromData(s.data()));
  }

  @override
  Future<Membership> activatePlan({
    required String userId,
    String planId = 'plan_monthly_29',
  }) async {
    try {
      // Phase A: paymentId may be a client-generated ledger id after Fake charge.
      final paymentId =
          'pay_client_${DateTime.now().millisecondsSinceEpoch}';
      final data = await _callables.call('activateMembership', {
        'planId': planId,
        'paymentId': paymentId,
      });
      return Membership(
        tier: MembershipTier.planActive,
        planId: (data['planId'] as String?) ?? planId,
        renewsAt: data['renewsAt'] != null
            ? DateTime.tryParse(data['renewsAt'] as String)
            : DateTime.now().add(const Duration(days: 30)),
      );
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }

  @override
  Future<void> clearPlan(String userId) async {
    // Client cannot write memberships; ops/CF only.
    throw UnsupportedError('clearPlan is server-only on staging/prod');
  }
}
