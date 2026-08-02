import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/crisis/crisis_pack.dart';
import 'package:emo_sup/main.dart';
import 'package:emo_sup/screens/safety_privacy_screen.dart';

CrisisPack get _testPack => const CrisisPack(
      locale: 'en',
      region: 'ZW',
      version: 'test',
      partnerSignOff: CrisisPartnerSignOff(
        partner: 'test',
        signedAt: '2026-07-19',
        reviewer: 'test',
      ),
      disclaimer:
          'This app is not an emergency service. Reach real-world help first.',
      resources: [
        CrisisResource(
          id: 'zw_police_emergency',
          title: 'Zimbabwe emergency (police)',
          subtitle: 'Public emergency line',
          tel: '999',
          icon: 'emergency',
        ),
      ],
    );

Widget _safetyApp() {
  return MaterialApp(
    home: SafetyPrivacyScreen(crisisPackOverride: _testPack),
  );
}

void main() {
  testWidgets('Safety hub shows all five section anchors', (tester) async {
    await tester.pumpWidget(_safetyApp());

    expect(find.text('Safety & Privacy'), findsOneWidget);
    expect(find.text("If you're in immediate danger"), findsOneWidget);
    expect(find.text('Crisis resources'), findsOneWidget);
    expect(find.text('Report & block'), findsOneWidget);
    expect(find.text('Your data'), findsOneWidget);
    expect(find.text('How your messages are protected'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Private conversation'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('States app is not emergency or medical service', (tester) async {
    await tester.pumpWidget(_safetyApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('not an emergency service'),
      findsWidgets,
    );
    expect(
      find.textContaining('not medical care'),
      findsWidgets,
    );
  });

  testWidgets('Crisis resource cards open stub dialog', (tester) async {
    await tester.pumpWidget(_safetyApp());
    await tester.pumpAndSettle();

    expect(find.text('Zimbabwe emergency (police)'), findsOneWidget);
    await tester.tap(find.text('Zimbabwe emergency (police)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Call 999'), findsOneWidget);
    expect(find.textContaining('not an emergency service'), findsWidgets);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Safety & Privacy'), findsOneWidget);
  });

  testWidgets('Report form requires reason then submits', (tester) async {
    await tester.pumpWidget(_safetyApp());

    final submit = find.widgetWithText(FilledButton, 'Submit report');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.scrollUntilVisible(
      find.text('Something else'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Something else'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.enterText(
      find.byType(TextField),
      'Felt uncomfortable during the chat.',
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Report received'), findsOneWidget);
  });

  testWidgets('Delete my data requires typing DELETE then snackbar',
      (tester) async {
    await tester.pumpWidget(_safetyApp());

    await tester.scrollUntilVisible(
      find.text('Delete my data'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete my data'));
    await tester.pumpAndSettle();

    expect(find.text('Delete my data?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.textContaining('Messages and chat history'), findsOneWidget);
    expect(find.textContaining('Bookings and scheduled sessions'), findsOneWidget);
    expect(find.textContaining('Mood check-ins'), findsOneWidget);
    expect(find.textContaining('Account nickname'), findsOneWidget);

    final deleteButton = find.widgetWithText(TextButton, 'Delete everything');
    expect(tester.widget<TextButton>(deleteButton).onPressed, isNull);

    final deleteField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(deleteField, 'DELETE');
    await tester.pump();

    expect(tester.widget<TextButton>(deleteButton).onPressed, isNotNull);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Deletion started'), findsOneWidget);
    // Still on hub — no dead-end.
    expect(find.text('Safety & Privacy'), findsOneWidget);
  });

  testWidgets('Download my data shows prototype snackbar', (tester) async {
    await tester.pumpWidget(_safetyApp());

    await tester.scrollUntilVisible(
      find.text('Download my data'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Download my data'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Download started'), findsOneWidget);
    expect(find.text('Safety & Privacy'), findsOneWidget);
  });

  testWidgets('Legal stubs open and return to hub', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SafetyPrivacyScreen()),
    );

    await tester.scrollUntilVisible(
      find.text('Terms of Service'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();

    expect(find.textContaining('What this app is'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Safety & Privacy'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Privacy Policy'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your data'), findsOneWidget);
  });

  testWidgets('Footer Report & block deep-links into report section',
      (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Report & block'));
    await tester.pumpAndSettle();

    expect(find.text('Safety & Privacy'), findsOneWidget);
    expect(find.text('Submit report'), findsOneWidget);
  });

  testWidgets('Settings opens full Safety hub', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.byTooltip('Safety & Privacy'));
    await tester.pumpAndSettle();

    expect(find.text("If you're in immediate danger"), findsOneWidget);
    expect(find.text('How your messages are protected'), findsOneWidget);
  });
}
