import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../widgets/pre_auth_safety_button.dart';
import '../../widgets/soft_surface.dart';

/// Entry point: confidentiality one-liner + single primary CTA.
///
/// Safety & Privacy is always reachable pre-auth (shield + crisis link).
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PreAuthSafetyButton(tooltip: l10n.safetyAndPrivacy),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SoftGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
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
                  l10n.welcomeHeadline,
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.welcomeBody,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TrustChip(label: l10n.welcomeTrustChip),
                ),
                const Spacer(flex: 3),
                SoftPrimaryButton(
                  onPressed: onGetStarted,
                  label: l10n.getStartedAnonymously,
                ),
                const SizedBox(height: 8),
                Center(
                  child: PreAuthCrisisLink(label: l10n.needUrgentHelp),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.notTherapyDisclaimer,
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
