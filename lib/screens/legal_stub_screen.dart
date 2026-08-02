import 'package:flutter/material.dart';

/// Terms of Service / Privacy Policy, rendered in-app.
///
/// Mirrors the static pages under `public/legal/` (see docs/legal-hosting.md)
/// so the in-app copy and the hosted URL users are pointed to from the App
/// Store / Play Console never drift apart. Bracketed `[PLACEHOLDER]` values
/// (legal entity name, support email, jurisdiction, data-residency region)
/// must be filled in — and this content reviewed by a lawyer for your target
/// jurisdiction — before a store submission.
class LegalStubScreen extends StatelessWidget {
  const LegalStubScreen({
    super.key,
    required this.title,
    required this.sections,
    required this.hostedPath,
  });

  final String title;
  final List<LegalSection> sections;

  /// Path under the hosted legal site, e.g. 'terms.html'.
  final String hostedPath;

  factory LegalStubScreen.termsOfService() {
    return LegalStubScreen(
      title: 'Terms of Service',
      hostedPath: 'terms.html',
      sections: const [
        LegalSection(
          '1. What this app is',
          'Emo Sup provides confidential emotional support and '
              'companionship with trained, vetted listeners for private 1:1 '
              'chat and scheduled sessions. It is not therapy, not medical '
              'care, and not an emergency or crisis service. If you are in '
              'immediate danger, contact local emergency services or a '
              'trusted person near you — do not rely on this app.',
        ),
        LegalSection(
          '2. Eligibility',
          'You must be 18 or older to use this app. By creating an '
              'account, you confirm you meet this requirement.',
        ),
        LegalSection(
          '3. Your account',
          "You're responsible for keeping your sign-in credentials secure. "
              'You may use an anonymous display name; avoid sharing '
              "identifying details you're not comfortable a listener "
              'seeing.',
        ),
        LegalSection(
          '4. Acceptable use',
          'You agree not to harass, threaten, or abuse a listener or any '
              'other user; attempt to contact a listener outside the app; '
              'misrepresent yourself as a listener; or use the app for any '
              'unlawful purpose. We may suspend or terminate accounts that '
              'violate this.',
        ),
        LegalSection(
          '5. Listeners',
          'Listeners are vetted by us but are not licensed medical or '
              'mental-health professionals unless stated otherwise. '
              'Nothing said by a listener is medical advice, diagnosis, or '
              'treatment.',
        ),
        LegalSection(
          '6. Safety reporting',
          'If something in a conversation concerns you, use Report or '
              'Block from Safety & Privacy or from within the chat. Reports '
              'are reviewed by our safety team.',
        ),
        LegalSection(
          '7. Payments',
          'Paid features are disabled at launch. If we enable payments in '
              'the future, additional terms covering pricing, refunds, and '
              "billing will be presented before you're charged.",
        ),
        LegalSection(
          '8. Availability',
          "The app depends on third-party infrastructure and listener "
              "availability, and we don't guarantee uninterrupted access or "
              'that a listener will be available at any given time.',
        ),
        LegalSection(
          '9. Termination',
          'You can stop using the app and delete your account at any time '
              'from Safety & Privacy. We may suspend or terminate your '
              'access for violating these terms or to protect the safety '
              'of other users.',
        ),
        LegalSection(
          '10. Limitation of liability',
          'The app is provided "as is." To the fullest extent permitted '
              'by law, [LEGAL_ENTITY_NAME] is not liable for indirect or '
              'consequential damages arising from your use of the app.',
        ),
        LegalSection(
          '11. Governing law',
          'These terms are governed by the laws of [JURISDICTION].',
        ),
        LegalSection(
          '12. Changes',
          'We may update these terms; material changes will be announced '
              'in-app before they take effect.',
        ),
        LegalSection('13. Contact', '[SUPPORT_EMAIL]'),
      ],
    );
  }

  factory LegalStubScreen.privacyPolicy() {
    return LegalStubScreen(
      title: 'Privacy Policy',
      hostedPath: 'privacy.html',
      sections: const [
        LegalSection(
          'What we collect',
          'Account: sign-up happens via Firebase Authentication using your '
              'phone number or an email + password. That contact info is '
              "used only for sign-in and is never stored in the app's "
              'shared database or shown to other users.\n\n'
              "Anonymous profile: inside the app you're identified only by "
              "an anonymous display name you choose — we don't collect "
              'your legal name.\n\n'
              'Chats: messages you send are stored so the conversation can '
              'be delivered and retrieved. Only you and the listener on '
              'that conversation can read them.\n\n'
              'Mood check-ins: if you use the optional mood tracker, we '
              'store the values you log.\n\n'
              'Device & notifications: we store a device token to deliver '
              'chat notifications.\n\n'
              'Crash & diagnostic data: crash reports (device model, OS '
              'version, the code path that crashed) via Firebase '
              'Crashlytics — never your chat content.\n\n'
              'Product analytics: a small, allow-listed set of product '
              'events (e.g. "screen opened"). Chat text, crisis-resource '
              'activity, and anything that could reveal a mental-health '
              'crisis are excluded before an event is ever sent.\n\n'
              'Safety reports: if you report or block someone, we store '
              'the report for our safety team to review.\n\n'
              'Device attestation: Firebase App Check confirms requests '
              "come from a genuine copy of the app — it doesn't track "
              'your behavior.',
        ),
        LegalSection(
          'What we do not do',
          "We don't sell your data. We don't run advertising or ad "
              "tracking. There are no public profiles, public message "
              'feeds, or open forums — every conversation is private and '
              "1:1 with a listener we've vetted. Payments are switched off "
              'at launch; no billing information is collected until a '
              'payment feature is explicitly enabled and announced.',
        ),
        LegalSection(
          'Listeners',
          'Listeners are individually vetted before they can be assigned '
              "conversations — there's no open sign-up path to become one. "
              'A listener can see your anonymous display name and your '
              'messages during an active conversation, and nothing else.',
        ),
        LegalSection(
          'How long we keep data',
          'We keep chat and account data while your account is active. '
              'If you request deletion, we delete your authentication '
              'account, scrub the text of messages you sent, remove your '
              'device tokens, and unlink you from past sessions. We retain '
              'safety reports after a deletion request, because they may '
              "involve another person's safety.",
        ),
        LegalSection(
          'Your choices',
          'Delete your data any time from Safety & Privacy → Delete my '
              'data — this permanently deletes your account. Block or '
              'report is available from Safety & Privacy or directly '
              'inside a chat. The app and crisis resources are available '
              'in English, Shona, and Ndebele.',
        ),
        LegalSection(
          'Crisis resources',
          "Safety & Privacy links to public emergency numbers and "
              "mental-health helplines. We don't operate them, and numbers "
              'can change — always verify before relying on one in an '
              'emergency.',
        ),
        LegalSection(
          'Children',
          'This app is intended for adults aged 18 and over. If you '
              'believe a minor has created an account, contact us at '
              "[SUPPORT_EMAIL] and we'll remove it.",
        ),
        LegalSection(
          'Where data is stored',
          'Data is stored on Google Firebase infrastructure. '
              '[DATA_RESIDENCY_REGION].',
        ),
        LegalSection(
          'Changes to this policy',
          "If a change affects how your data is used, we'll notify you "
              'in-app before it takes effect.',
        ),
        LegalSection('Contact', '[SUPPORT_EMAIL]'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          for (final section in sections) ...[
            Text(
              section.heading,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(section.body, style: textTheme.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: 20),
          ],
          Divider(color: scheme.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          SelectableText(
            'Also published at: https://emo-sup-prod.web.app/legal/$hostedPath',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bracketed placeholders above must be filled in, and this '
            'content reviewed by a lawyer for your launch jurisdiction, '
            'before this is relied on as a real policy.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}
