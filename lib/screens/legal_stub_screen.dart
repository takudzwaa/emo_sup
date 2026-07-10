import 'package:flutter/material.dart';

/// Prototype stub for Terms of Service / Privacy Policy.
/// Always returns cleanly to the Safety & Privacy hub via back.
class LegalStubScreen extends StatelessWidget {
  const LegalStubScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  factory LegalStubScreen.termsOfService() {
    return const LegalStubScreen(
      title: 'Terms of Service',
      body:
          'This is a prototype placeholder for Terms of Service.\n\n'
          'When published, this page will describe how the app works as '
          'confidential emotional support and companionship — not therapy, '
          'not a medical service, and not an emergency service.\n\n'
          'Use the back control to return to Safety & Privacy.',
    );
  }

  factory LegalStubScreen.privacyPolicy() {
    return const LegalStubScreen(
      title: 'Privacy Policy',
      body:
          'This is a prototype placeholder for the Privacy Policy.\n\n'
          'When published, this page will explain what data we store, why, '
          'and how you can download or delete it.\n\n'
          'Use the back control to return to Safety & Privacy.',
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
          Text(body, style: textTheme.bodyLarge),
          const SizedBox(height: 28),
          Text(
            'Prototype document — not legal advice.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
