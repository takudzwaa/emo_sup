enum MembershipTier { free, planActive }

class Membership {
  const Membership({
    this.tier = MembershipTier.free,
    this.planId,
    this.renewsAt,
  });

  final MembershipTier tier;
  final String? planId;
  final DateTime? renewsAt;

  bool get hasActivePlan => tier == MembershipTier.planActive;

  Membership copyWith({
    MembershipTier? tier,
    String? planId,
    DateTime? renewsAt,
  }) {
    return Membership(
      tier: tier ?? this.tier,
      planId: planId ?? this.planId,
      renewsAt: renewsAt ?? this.renewsAt,
    );
  }
}
