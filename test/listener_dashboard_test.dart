import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/config/listener_role.dart';
import 'package:emo_sup/data/listener_dashboard_store.dart';
import 'package:emo_sup/main_listener.dart';
import 'package:emo_sup/models/active_chat_summary.dart';
import 'package:emo_sup/screens/chat_screen.dart';
import 'package:emo_sup/widgets/message_bubble.dart';

ListenerApp _listenerApp(ListenerDashboardStore store) {
  return ListenerApp(
    store: store,
    roleGate: ListenerRoleGate(claimOverride: true),
  );
}

void main() {
  testWidgets('Dashboard shows availability, chats, bookings, reminder',
      (tester) async {
    final store = ListenerDashboardStore();
    await tester.pumpWidget(_listenerApp(store));

    expect(find.text('Listener dashboard'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Sessions today'), findsOneWidget);
    expect(find.textContaining('Volunteer pilot'), findsWidgets);
    expect(find.text('Active chats'), findsOneWidget);
    expect(find.text('Upcoming bookings'), findsOneWidget);
    expect(find.text('Quiet River'), findsOneWidget);
    expect(find.text('Open chat'), findsWidgets);
    expect(
      find.textContaining('never diagnose'),
      findsWidgets,
    );
    expect(find.textContaining('Escalate button'), findsOneWidget);
  });

  testWidgets('Without claim shows not a listener', (tester) async {
    await tester.pumpWidget(
      ListenerApp(roleGate: ListenerRoleGate(claimOverride: false)),
    );
    expect(find.text('Not a listener account'), findsOneWidget);
    expect(find.text('Listener dashboard'), findsNothing);
  });

  testWidgets('Availability toggle updates store', (tester) async {
    final store = ListenerDashboardStore(availableNow: true);
    await tester.pumpWidget(_listenerApp(store));

    expect(store.availableNow, isTrue);
    expect(find.text('Online'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(store.availableNow, isFalse);
    expect(find.text('Away'), findsOneWidget);
  });

  testWidgets('Today summary shows sessions without demo earnings',
      (tester) async {
    final store = ListenerDashboardStore();
    await tester.pumpWidget(_listenerApp(store));

    final count = store.sessionsToday;
    expect(find.text('$count'), findsWidgets);
    // Pilot: earnings UI hidden (PR 20).
    expect(find.text('\$${count * 8}'), findsNothing);
    expect(find.textContaining('Volunteer pilot'), findsOneWidget);
  });

  testWidgets('Open chat opens listener Chat perspective', (tester) async {
    final store = ListenerDashboardStore();
    await tester.pumpWidget(_listenerApp(store));

    final openChat = find.text('Open chat').first;
    await tester.ensureVisible(openChat);
    await tester.pumpAndSettle();
    await tester.tap(openChat);
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    // Peer name is the user (listener perspective).
    expect(find.text('Quiet River'), findsWidgets);
    expect(find.text('Private conversation'), findsOneWidget);
    expect(find.text('Escalate'), findsWidgets);
    expect(find.byType(MessageBubble), findsWidgets);
  });

  testWidgets('Escalate on card shows confirmation dialog', (tester) async {
    final store = ListenerDashboardStore(
      activeChats: [
        ActiveChatSummary(
          sessionId: 's1',
          userId: 'u1',
          userAnonymousName: 'Soft Meadow',
          lastMessagePreview: 'Hello',
          lastMessageAt: DateTime.now(),
          unreadCount: 1,
        ),
      ],
      upcomingBookings: const [],
    );
    await tester.pumpWidget(_listenerApp(store));

    await tester.tap(find.text('Escalate').first);
    await tester.pumpAndSettle();

    expect(find.text('Escalate this chat?'), findsOneWidget);
    await tester.tap(find.text('Escalate now'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Escalation recorded'), findsOneWidget);
  });

  testWidgets('Join at time is disabled for future slots', (tester) async {
    final now = DateTime.now();
    final store = ListenerDashboardStore(
      activeChats: const [],
      upcomingBookings: [
        ListenerBookingSummary(
          bookingId: 'b_future',
          userId: 'u2',
          userAnonymousName: 'Gentle Cloud',
          slotStart: now.add(const Duration(hours: 5)),
        ),
      ],
    );
    await tester.pumpWidget(_listenerApp(store));

    final joinBtn = find.widgetWithText(FilledButton, 'Join at time');
    expect(joinBtn, findsOneWidget);
    expect(tester.widget<FilledButton>(joinBtn).onPressed, isNull);
  });

  testWidgets('Join now enabled when slot is open', (tester) async {
    final now = DateTime.now();
    final store = ListenerDashboardStore(
      activeChats: const [],
      upcomingBookings: [
        ListenerBookingSummary(
          bookingId: 'b_now',
          userId: 'u3',
          userAnonymousName: 'Calm Brook',
          slotStart: now.subtract(const Duration(minutes: 1)),
        ),
      ],
    );
    await tester.pumpWidget(_listenerApp(store));

    final joinBtn = find.widgetWithText(FilledButton, 'Join now');
    expect(joinBtn, findsOneWidget);
    expect(tester.widget<FilledButton>(joinBtn).onPressed, isNotNull);

    await tester.ensureVisible(joinBtn);
    await tester.pumpAndSettle();
    await tester.tap(joinBtn);
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Calm Brook'), findsWidgets);
  });

  test('ListenerDashboardStore marks chat read', () {
    final store = ListenerDashboardStore();
    final id = store.activeChats.first.sessionId;
    expect(store.activeChats.first.hasUnread, isTrue);
    store.markChatRead(id);
    expect(
      store.activeChats.firstWhere((c) => c.sessionId == id).unreadCount,
      0,
    );
  });
}
