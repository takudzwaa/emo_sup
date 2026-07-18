import 'package:flutter/material.dart';

import '../screens/safety_privacy_screen.dart';

/// Opens Safety & Privacy without requiring a signed-in profile.
///
/// Used on Welcome + auth screens so crisis / report / delete guidance is
/// never gated behind onboarding (AGENTS.md + production design PR 5).
void openPreAuthSafety(
  BuildContext context, {
  SafetyHubSection initialSection = SafetyHubSection.overview,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SafetyPrivacyScreen(initialSection: initialSection),
    ),
  );
}

/// App-bar action: shield → Safety hub (overview).
class PreAuthSafetyButton extends StatelessWidget {
  const PreAuthSafetyButton({
    super.key,
    this.initialSection = SafetyHubSection.overview,
    this.tooltip = 'Safety & Privacy',
  });

  final SafetyHubSection initialSection;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.health_and_safety_outlined),
      onPressed: () => openPreAuthSafety(
        context,
        initialSection: initialSection,
      ),
    );
  }
}

/// Compact text button for crisis resources (Welcome footer / secondary).
class PreAuthCrisisLink extends StatelessWidget {
  const PreAuthCrisisLink({
    super.key,
    this.label = 'Need urgent help?',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: () => openPreAuthSafety(
        context,
        initialSection: SafetyHubSection.crisisResources,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
