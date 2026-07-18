import 'package:flutter/foundation.dart';

import '../domain/repositories/membership_repository.dart';
import '../models/membership.dart';
import 'repositories/memory_membership_repository.dart';

/// UI-facing membership store (ChangeNotifier façade).
class MembershipStore extends ChangeNotifier {
  MembershipStore({
    Membership? initial,
    MembershipRepository? repository,
    this.userId = 'local_user',
  })  : repository = repository ?? MemoryMembershipRepository(),
        _membership = initial ?? const Membership();

  final MembershipRepository repository;
  final String userId;

  Membership _membership;

  Membership get membership => _membership;
  bool get hasActivePlan => _membership.hasActivePlan;

  void activatePlan({String planId = 'plan_monthly_29'}) {
    _membership = Membership(
      tier: MembershipTier.planActive,
      planId: planId,
      renewsAt: DateTime.now().add(const Duration(days: 30)),
    );
    repository.activatePlan(userId: userId, planId: planId);
    notifyListeners();
  }

  void clearPlanForTesting() {
    _membership = const Membership();
    repository.clearPlan(userId);
    notifyListeners();
  }
}
