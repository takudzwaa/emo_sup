import 'dart:async';

import '../../domain/repositories/membership_repository.dart';
import '../../models/membership.dart';

/// In-memory memberships for prototype + tests.
class MemoryMembershipRepository implements MembershipRepository {
  MemoryMembershipRepository({Map<String, Membership>? seed})
      : _byUser = Map<String, Membership>.from(seed ?? {});

  final Map<String, Membership> _byUser;
  final _controllers = <String, StreamController<Membership>>{};

  Membership _get(String userId) =>
      _byUser[userId] ?? const Membership();

  void _emit(String userId) {
    final c = _controllers[userId];
    if (c != null && !c.isClosed) {
      c.add(_get(userId));
    }
  }

  @override
  Future<Membership> getMembership(String userId) async => _get(userId);

  @override
  Stream<Membership> watchMembership(String userId) {
    final controller = _controllers.putIfAbsent(
      userId,
      () => StreamController<Membership>.broadcast(),
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(_get(userId));
    });
    return controller.stream;
  }

  @override
  Future<Membership> activatePlan({
    required String userId,
    String planId = 'plan_monthly_29',
  }) async {
    final membership = Membership(
      tier: MembershipTier.planActive,
      planId: planId,
      renewsAt: DateTime.now().add(const Duration(days: 30)),
    );
    _byUser[userId] = membership;
    _emit(userId);
    return membership;
  }

  @override
  Future<void> clearPlan(String userId) async {
    _byUser[userId] = const Membership();
    _emit(userId);
  }
}
