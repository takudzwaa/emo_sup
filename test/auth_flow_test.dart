import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/auth/anonymous_name_generator.dart';
import 'package:emo_sup/auth/auth_controller.dart';
import 'package:emo_sup/auth/auth_service.dart';
import 'package:emo_sup/main.dart';
import 'package:emo_sup/models/user_profile.dart';

void main() {
  testWidgets('Welcome shows confidentiality and Get started CTA',
      (tester) async {
    await tester.pumpWidget(buildTestApp(signedIn: false));

    expect(find.text('Someone to talk to — privately'), findsOneWidget);
    expect(find.textContaining('confidential'), findsWidgets);
    expect(find.text('Get started anonymously'), findsOneWidget);
    expect(find.text('Talk to Someone'), findsNothing);
  });

  testWidgets('Full email auth flow lands on Home with generated name',
      (tester) async {
    final auth = AuthController(
      authService: PrototypeAuthService(),
      nameGenerator: AnonymousNameGenerator(random: _FixedRandom(0)),
    );
    await tester.pumpWidget(
      buildTestApp(authController: auth, signedIn: false),
    );

    await tester.tap(find.text('Get started anonymously'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in privately'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'user@example.com');
    await tester.enterText(fields.at(1), 'secret12');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Your anonymous name'), findsOneWidget);
    final expectedName =
        '${AnonymousNameGenerator.adjectives[0]} ${AnonymousNameGenerator.natureNouns[0]}';
    expect(find.text(expectedName), findsOneWidget);

    await tester.tap(find.text('Use this name'));
    await tester.pumpAndSettle();

    expect(find.text('Before you continue'), findsOneWidget);
    expect(find.textContaining('not therapy'), findsWidgets);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter the app'));
    await tester.pumpAndSettle();

    expect(find.text('Talk to Someone'), findsOneWidget);
    expect(find.text(expectedName), findsOneWidget);
    expect(auth.profile?.authMethod, AuthMethod.email);
    expect(auth.profile?.anonymousName, expectedName);
  });

  testWidgets('Name can be regenerated only once', (tester) async {
    final auth = AuthController(
      authService: PrototypeAuthService(),
      nameGenerator: AnonymousNameGenerator(
        random: _SequenceRandom([0, 0, 1, 1, 2, 2]),
      ),
    );
    await tester.pumpWidget(
      buildTestApp(authController: auth, signedIn: false),
    );

    await tester.tap(find.text('Get started anonymously'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'a@b.co');
    await tester.enterText(fields.at(1), 'secret12');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(auth.canRegenerateName, isTrue);
    await tester.tap(find.text('Generate another name'));
    await tester.pumpAndSettle();
    expect(auth.canRegenerateName, isFalse);
    expect(find.text('Already regenerated once'), findsOneWidget);
  });

  testWidgets('Phone path sends code then verifies', (tester) async {
    final auth = AuthController(authService: PrototypeAuthService());
    await tester.pumpWidget(
      buildTestApp(authController: auth, signedIn: false),
    );

    await tester.tap(find.text('Get started anonymously'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '+15551234567');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(
      find.byType(TextField).at(1),
      PrototypeAuthService.prototypeOtpHint,
    );
    await tester.tap(find.text('Verify and continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Your anonymous name'), findsOneWidget);
    expect(auth.pendingSession?.authMethod, AuthMethod.phone);
  });

  test('UserProfile has no email/phone fields in map', () {
    final profile = UserProfile(
      uid: 'u1',
      anonymousName: 'Calm Harbor',
      authMethod: AuthMethod.phone,
      createdAt: DateTime.utc(2026, 7, 9),
    );
    final map = profile.toMap();
    expect(map.keys.toSet(), {
      'uid',
      'anonymousName',
      'authMethod',
      'createdAt',
    });
    expect(map.containsKey('email'), isFalse);
    expect(map.containsKey('phone'), isFalse);
    expect(UserProfile.fromMap(map), profile);
  });

  test('AnonymousNameGenerator produces adjective + noun', () {
    final gen = AnonymousNameGenerator(random: _FixedRandom(3));
    final name = gen.generate();
    final parts = name.split(' ');
    expect(parts.length, 2);
    expect(AnonymousNameGenerator.adjectives, contains(parts[0]));
    expect(AnonymousNameGenerator.natureNouns, contains(parts[1]));
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  int _i = 0;

  @override
  int nextInt(int max) {
    final v = values[_i % values.length];
    _i++;
    return v % max;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
