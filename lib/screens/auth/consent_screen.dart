import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_service.dart';
import '../../widgets/pre_auth_safety_button.dart';
import '../../widgets/soft_surface.dart';
import '../legal_stub_screen.dart';

/// Explicit consent before Home: Privacy Policy + not a therapy service.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({
    super.key,
    required this.authController,
    required this.onCompleted,
  });

  final AuthController authController;
  final VoidCallback onCompleted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _checked = false;
  bool _ageChecked = false;
  String? _error;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    super.dispose();
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalStubScreen.privacyPolicy(),
      ),
    );
  }

  void _continue() {
    if (!_ageChecked) {
      setState(() => _error = 'Please confirm you are 18 or older to continue.');
      return;
    }
    if (!_checked) {
      setState(() => _error = 'Please confirm to continue.');
      return;
    }
    setState(() => _error = null);
    widget.authController.setAgeConfirmed(true);
    widget.authController.setConsentAccepted(true);
    try {
      widget.authController.completeOnboarding();
      widget.onCompleted();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Before you continue'),
        actions: const [PreAuthSafetyButton()],
      ),
      body: SoftGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A few plain facts',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This app offers confidential emotional support and '
                        'companionship with trained listeners. It is not therapy, '
                        'not a medical service, and not for emergencies.',
                        style: textTheme.bodyLarge?.copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your chats stay private. You can download or delete your data '
                        'anytime from Safety & Privacy.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: CheckboxListTile(
                    value: _ageChecked,
                    onChanged: (v) {
                      setState(() {
                        _ageChecked = v ?? false;
                        _error = null;
                      });
                      widget.authController.setAgeConfirmed(_ageChecked);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                    title: Text(
                      'I confirm I am 18 years of age or older.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: CheckboxListTile(
                  value: _checked,
                  onChanged: (v) {
                    setState(() {
                      _checked = v ?? false;
                      _error = null;
                    });
                    widget.authController.setConsentAccepted(_checked);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                  title: Text.rich(
                    TextSpan(
                      style: textTheme.bodyMedium,
                      children: [
                        const TextSpan(
                          text:
                              'I understand this is not therapy, and I agree to the ',
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _privacyTap,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                SoftPrimaryButton(
                  onPressed: _continue,
                  label: 'Enter the app',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
