import '../../models/membership.dart';

/// I/O for plan status: production single doc `memberships/{uid}`.
abstract class MembershipRepository {
  Future<Membership> getMembership(String userId);

  Stream<Membership> watchMembership(String userId);

  /// Prototype / Phase A only. Production activates via payment webhook CF.
  Future<Membership> activatePlan({
    required String userId,
    String planId = 'plan_monthly_29',
  });

  Future<void> clearPlan(String userId);
}
