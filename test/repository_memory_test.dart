import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/repositories/memory_booking_repository.dart';
import 'package:emo_sup/data/repositories/memory_chat_repository.dart';
import 'package:emo_sup/data/repositories/memory_membership_repository.dart';
import 'package:emo_sup/data/repositories/memory_mood_repository.dart';
import 'package:emo_sup/data/repositories/memory_safety_repository.dart';
import 'package:emo_sup/data/repositories/memory_user_profile_repository.dart';
import 'package:emo_sup/models/chat_message.dart';
import 'package:emo_sup/models/membership.dart';
import 'package:emo_sup/models/user_profile.dart';

void main() {
  group('MemoryMoodRepository', () {
    test('add and latest', () async {
      final repo = MemoryMoodRepository();
      await repo.add(userId: 'u1', value: 3);
      await repo.add(userId: 'u1', value: 5);
      final latest = await repo.latest('u1');
      expect(latest?.value, 5);
      final list = await repo.listEntries('u1');
      expect(list.length, 2);
    });
  });

  group('MemoryChatRepository', () {
    test('sendMessage is idempotent on clientMessageId', () async {
      final repo = MemoryChatRepository.withDemoSession();
      const sessionId = 'session_demo_001';
      await repo.sendMessage(
        sessionId: sessionId,
        senderId: 'user_quiet_river',
        text: 'Hello',
        clientMessageId: 'client_1',
      );
      await repo.sendMessage(
        sessionId: sessionId,
        senderId: 'user_quiet_river',
        text: 'Hello again',
        clientMessageId: 'client_1',
      );
      final messages = await repo.getMessages(sessionId);
      final matches = messages.where((m) => m.id == 'client_1').toList();
      expect(matches.length, 1);
      expect(matches.first.text, 'Hello again');
      expect(matches.first.status, MessageStatus.sent);
    });

    test('endSession sets endedAt', () async {
      final repo = MemoryChatRepository.withDemoSession();
      await repo.endSession('session_demo_001');
      final session = await repo.getSession('session_demo_001');
      expect(session?.isActive, isFalse);
      expect(session?.endedAt, isNotNull);
    });
  });

  group('MemoryMembershipRepository', () {
    test('activate and clear plan', () async {
      final repo = MemoryMembershipRepository();
      final active = await repo.activatePlan(userId: 'u1');
      expect(active.hasActivePlan, isTrue);
      expect(active.tier, MembershipTier.planActive);
      await repo.clearPlan('u1');
      final cleared = await repo.getMembership('u1');
      expect(cleared.hasActivePlan, isFalse);
    });
  });

  group('MemoryBookingRepository', () {
    test('confirmBooking adds booking', () async {
      final repo = MemoryBookingRepository(seedBookings: []);
      final booking = await repo.confirmBooking(
        userId: 'u1',
        listenerId: 'listener_harbor',
        slotStart: DateTime.utc(2026, 8, 1, 14),
      );
      expect(booking.userId, 'u1');
      final list = await repo.listUserBookings('u1');
      expect(list.length, 1);
    });
  });

  group('MemoryUserProfileRepository', () {
    test('upsert and get', () async {
      final repo = MemoryUserProfileRepository();
      final profile = UserProfile(
        uid: 'u1',
        anonymousName: 'Quiet River',
        authMethod: AuthMethod.phone,
        createdAt: DateTime.utc(2026, 7, 1),
      );
      await repo.upsertProfile(profile);
      final got = await repo.getProfile('u1');
      expect(got, profile);
    });
  });

  group('MemorySafetyRepository', () {
    test('captures report, block, delete', () async {
      final repo = MemorySafetyRepository();
      await repo.submitReport(
        reporterId: 'u1',
        targetType: 'listener',
        targetId: 'l1',
        reason: 'Felt unsafe or pressured',
      );
      await repo.blockTarget(blockerId: 'u1', blockedId: 'l1');
      await repo.requestDeleteMyData('u1');
      expect(repo.reports.length, 1);
      expect(repo.blocks.length, 1);
      expect(repo.deleteRequests, ['u1']);
    });
  });
}
