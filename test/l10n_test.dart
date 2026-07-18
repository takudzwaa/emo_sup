import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/l10n/app_localizations.dart';

void main() {
  testWidgets('English localizations load for pilot chrome', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(l10n.talkToSomeone, 'Talk to Someone');
    expect(l10n.privateConversation, 'Private conversation');
    expect(l10n.safetyAndPrivacy, 'Safety & Privacy');
  });

  test('Shona and Ndebele stubs are registered locales', () {
    final codes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
    expect(codes, containsAll(['en', 'sn', 'nd']));
  });

  test('Shona and Ndebele load via delegate without Material widgets',
      () async {
    final sn = await AppLocalizations.delegate.load(const Locale('sn'));
    final nd = await AppLocalizations.delegate.load(const Locale('nd'));
    expect(sn.talkToSomeone, isNotEmpty);
    expect(nd.talkToSomeone, isNotEmpty);
    // Not English placeholders for primary CTA.
    expect(sn.talkToSomeone, isNot(equals('Talk to Someone')));
    expect(nd.talkToSomeone, isNot(equals('Talk to Someone')));
  });
}
