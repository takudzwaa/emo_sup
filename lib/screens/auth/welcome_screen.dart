import 'package:flutter/material.dart';

import '../../widgets/soft_surface.dart';

/// Entry point: confidentiality one-liner + single primary CTA.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
  });

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SoftGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withValues(alpha: 0.22),
                          scheme.secondary.withValues(alpha: 0.16),
                          scheme.tertiary.withValues(alpha: 0.12),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.2),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: scheme.secondary.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 38,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Someone to talk to — privately',
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  'A confidential space with trained listeners. '
                  'No public profiles, no real names required.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Center(
                  child: TrustChip(label: 'Private & confidential'),
                ),
                const Spacer(flex: 3),
                SoftPrimaryButton(
                  onPressed: onGetStarted,
                  label: 'Get started anonymously',
                ),
                const SizedBox(height: 14),
                Text(
                  'Not therapy. Not an emergency service.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.48),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
