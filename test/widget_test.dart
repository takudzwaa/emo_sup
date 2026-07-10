import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/mood_store.dart';
import 'package:emo_sup/main.dart';
import 'package:emo_sup/models/mood_entry.dart';
import 'package:emo_sup/widgets/mood_check_in.dart';

void main() {
  testWidgets('Home shows primary CTA and safety entry points', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('Talk to Someone'), findsOneWidget);
    expect(find.text('Book a session for later'), findsOneWidget);
    expect(find.text('Report & block'), findsOneWidget);
    expect(find.text('Delete my data'), findsOneWidget);
    expect(find.text('Quiet River'), findsOneWidget);
  });

  testWidgets('Mood check-in stores entry and shows acknowledgment',
      (tester) async {
    final store = MoodStore();
    await tester.pumpWidget(buildTestApp(moodStore: store));

    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();

    expect(store.latest, isNotNull);
    expect(store.latest!.value, 3);
    expect(
      find.text(MoodCheckIn.acknowledgmentFor(3)),
      findsOneWidget,
    );
  });

  testWidgets('Talk to Someone navigates to Chat', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Talk to Someone'));
    await tester.pumpAndSettle();

    expect(find.text('Listener — Amara K.'), findsOneWidget);
    expect(find.text('Encrypted'), findsOneWidget);
  });

  testWidgets('Settings opens Safety & Privacy hub', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.byTooltip('Safety & Privacy'));
    await tester.pumpAndSettle();

    expect(find.text('Safety & Privacy'), findsWidgets);
    expect(find.text('Report & block'), findsWidgets);
  });

  testWidgets('Home shows greeting and Free plan chip', (tester) async {
    await tester.pumpWidget(buildTestApp());
    // Greeting is "Good morning/afternoon/evening, …" (mood label also says "Good").
    expect(
      find.textContaining(RegExp(r'Good (morning|afternoon|evening)')),
      findsOneWidget,
    );
    expect(find.text('Free'), findsWidgets);
  });

  test('MoodEntry serializes for future Firestore write', () {
    final entry = MoodEntry(
      timestamp: DateTime.utc(2026, 7, 9, 12),
      value: 4,
    );
    final map = entry.toMap();
    expect(map['value'], 4);
    expect(map['timestamp'], '2026-07-09T12:00:00.000Z');
    expect(MoodEntry.fromMap(map), entry);
  });
}
