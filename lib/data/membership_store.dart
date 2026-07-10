import 'package:flutter/foundation.dart';

import '../models/membership.dart';

class MembershipStore extends ChangeNotifier {
  MembershipStore({Membership? initial})
      : _membership = initial ?? const Membership();

  Membership _membership;

  Membership get membership => _membership;
  bool get hasActivePlan => _membership.hasActivePlan;

  void activatePlan({String planId = 'plan_monthly_29'}) {
    _membership = Membership(
      tier: MembershipTier.planActive,
      planId: planId,
      renewsAt: DateTime.now().add(const Duration(days: 30)),
    );
    notifyListeners();
  }

  void clearPlanForTesting() {
    _membership = const Membership();
    notifyListeners();
  }
}
