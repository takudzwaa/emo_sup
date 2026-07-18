import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/chat_store.dart';
import 'package:emo_sup/main.dart';
import 'package:emo_sup/models/chat_message.dart';
import 'package:emo_sup/models/chat_session.dart';
import 'package:emo_sup/screens/chat_screen.dart';
import 'package:emo_sup/widgets/message_bubble.dart';
import 'package:emo_sup/widgets/typing_indicator.dart';

void main() {
  testWidgets('Chat app bar shows listener name, encrypted cue, crisis link',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatStore: ChatStore(mockListenerReplies: false),
        ),
      ),
    );

    expect(find.text('Listener — Amara K.'), findsWidgets);
    expect(find.text('Private conversation'), findsOneWidget);
    expect(find.text('Need urgent help?'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
    expect(
      find.textContaining('private session with Listener — Amara K.'),
      findsOneWidget,
    );
    expect(find.text('Private'), findsOneWidget);
  });

  testWidgets('Seed messages render as bubbles', (tester) async {
    final store = ChatStore(mockListenerReplies: false);
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(chatStore: store)),
    );

    expect(find.byType(MessageBubble), findsNWidgets(store.messages.length));
    expect(
      find.textContaining("I'm here to listen"),
      findsOneWidget,
    );
  });

  testWidgets('Sending a message adds a user bubble', (tester) async {
    final store = ChatStore(mockListenerReplies: false);
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(chatStore: store)),
    );

    await tester.enterText(find.byType(TextField), 'Hello there');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pump(); // sending state

    expect(
      store.messages.where((m) => m.text == 'Hello there').length,
      1,
    );
    expect(find.text('Hello there'), findsOneWidget);
    expect(store.messages.last.senderId, store.currentUserId);
    expect(store.messages.last.status, MessageStatus.sending);
    expect(find.text('…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    expect(store.messages.last.status, MessageStatus.sent);
    expect(find.text('✓'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(store.messages.last.status, MessageStatus.delivered);
    // Seed own messages are already read (✓✓); new one is delivered (✓✓).
    expect(find.text('✓✓'), findsWidgets);
  });

  testWidgets('Need urgent help opens Safety hub crisis section',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatStore: ChatStore(mockListenerReplies: false),
        ),
      ),
    );

    await tester.tap(find.text('Need urgent help?'));
    await tester.pumpAndSettle();

    expect(find.text('Safety & Privacy'), findsWidgets);
    expect(find.text('Crisis resources'), findsWidgets);
  });

  testWidgets('Overflow Report & block opens Safety hub', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatStore: ChatStore(mockListenerReplies: false),
        ),
      ),
    );

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report & block').last);
    await tester.pumpAndSettle();

    expect(find.text('Safety & Privacy'), findsWidgets);
  });

  testWidgets('End session appears in menu and pops ChatScreen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(
                          chatStore: ChatStore(mockListenerReplies: false),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open chat'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('End session'), findsOneWidget);

    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();

    expect(find.text('End this session?'), findsOneWidget);
    // Confirm button in the dialog (menu item already dismissed).
    await tester.tap(find.widgetWithText(TextButton, 'End session'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsNothing);
    expect(find.text('Session ended'), findsOneWidget);
  });

  testWidgets('Home Talk to Someone opens full Chat', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Talk to Someone'));
    await tester.pumpAndSettle();

    expect(find.text('Listener — Amara K.'), findsWidgets);
    expect(find.text('Private conversation'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Mock reply shows typing then listener message', (tester) async {
    final store = ChatStore(mockListenerReplies: true);
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(chatStore: store)),
    );

    final before = store.messages.length;
    await tester.enterText(find.byType(TextField), 'Feeling low today');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pump();

    // Mock reply schedules typing immediately on send.
    expect(store.isListenerTyping, isTrue);
    expect(find.byType(TypingIndicator), findsOneWidget);

    // Canned reply fires within ~0.9–1.8s after typing starts.
    await tester.pump(const Duration(milliseconds: 2200));
    expect(store.isListenerTyping, isFalse);
    expect(store.messages.length, greaterThan(before + 1));
    expect(store.messages.last.senderId, store.listenerId);
  });

  test('ChatMessage and ChatSession serialize for Firestore shape', () {
    final session = ChatSession(
      id: 'session_1',
      userId: 'user_1',
      listenerId: 'listener_1',
      startedAt: DateTime.utc(2026, 7, 9, 10),
      listenerDisplayName: 'Listener — Amara K.',
    );
    final message = ChatMessage(
      id: 'msg_1',
      senderId: 'user_1',
      text: 'Hi',
      timestamp: DateTime.utc(2026, 7, 9, 10, 1),
      status: MessageStatus.sent,
    );

    expect(session.toMap()['id'], 'session_1');
    expect(ChatSession.fromMap(session.toMap()), session);
    expect(message.toMap()['status'], 'sent');
    expect(ChatMessage.fromMap(message.toMap()), message);
  });

  test('MessageBubble statusTick maps delivery states', () {
    expect(MessageBubble.statusTick(MessageStatus.sending), '…');
    expect(MessageBubble.statusTick(MessageStatus.sent), '✓');
    expect(MessageBubble.statusTick(MessageStatus.delivered), '✓✓');
    expect(MessageBubble.statusTick(MessageStatus.read), '✓✓');
  });
}
