import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/main.dart';
import 'package:emo_sup/screens/safety_privacy_screen.dart';

void main() {
  testWidgets('Welcome pre-auth Safety shield opens Safety hub', (tester) async {
    await tester.pumpWidget(buildTestApp(signedIn: false));

    expect(find.text('Get started anonymously'), findsOneWidget);
    expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.health_and_safety_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SafetyPrivacyScreen), findsOneWidget);
    expect(find.text('Safety & Privacy'), findsOneWidget);
    // Crisis and report still free without completing auth.
    expect(find.text('Crisis resources'), findsOneWidget);
    expect(find.text('Report & block'), findsOneWidget);
  });

  testWidgets('Welcome crisis link opens crisis section', (tester) async {
    await tester.pumpWidget(buildTestApp(signedIn: false));

    await tester.tap(find.text('Need urgent help?'));
    await tester.pumpAndSettle();

    expect(find.byType(SafetyPrivacyScreen), findsOneWidget);
    expect(find.text("If you're in immediate danger"), findsOneWidget);
  });

  testWidgets('Auth credential screen exposes Safety action', (tester) async {
    await tester.pumpWidget(buildTestApp(signedIn: false));

    await tester.tap(find.text('Get started anonymously'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in privately'), findsOneWidget);
    expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.health_and_safety_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SafetyPrivacyScreen), findsOneWidget);
  });
}
