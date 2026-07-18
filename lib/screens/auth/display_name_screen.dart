import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../widgets/anonymous_avatar.dart';
import '../../widgets/pre_auth_safety_button.dart';
import '../../widgets/soft_surface.dart';

/// System-generated anonymous name; user may regenerate once, then confirm.
class DisplayNameScreen extends StatefulWidget {
  const DisplayNameScreen({
    super.key,
    required this.authController,
    required this.onConfirmed,
  });

  final AuthController authController;
  final VoidCallback onConfirmed;

  @override
  State<DisplayNameScreen> createState() => _DisplayNameScreenState();
}

class _DisplayNameScreenState extends State<DisplayNameScreen> {
  static const _animDuration = Duration(milliseconds: 250);

  late String _name;
  double _opacity = 0;
  double _scale = 0.92;

  @override
  void initState() {
    super.initState();
    _name = widget.authController.draftAnonymousName;
    widget.authController.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _opacity = 1;
        _scale = 1;
      });
    });
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final next = widget.authController.draftAnonymousName;
    if (next == _name || !mounted) return;

    setState(() {
      _opacity = 0;
      _scale = 0.92;
    });

    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() {
        _name = next;
        _opacity = 1;
        _scale = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canRegen = widget.authController.canRegenerateName;

    return ListenableBuilder(
      listenable: widget.authController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Your anonymous name'),
            actions: const [PreAuthSafetyButton()],
          ),
          body: SoftGradientBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SoftCard(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'This is the only name anyone will see. No photos, no '
                        'real names, no public profile.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: AnonymousAvatar(displayName: _name, size: 96),
                    ),
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: _animDuration,
                      curve: Curves.easeOut,
                      child: AnimatedScale(
                        scale: _scale,
                        duration: _animDuration,
                        curve: Curves.easeOutCubic,
                        child: Text(
                          _name,
                          key: ValueKey(_name),
                          style: textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Anonymous',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: canRegen
                          ? () =>
                              widget.authController.regenerateAnonymousName()
                          : null,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        canRegen
                            ? 'Generate another name'
                            : 'Already regenerated once',
                      ),
                    ),
                    if (!canRegen) ...[
                      const SizedBox(height: 8),
                      Text(
                        'You can change this once before confirming.',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const Spacer(),
                    SoftPrimaryButton(
                      onPressed: () {
                        widget.authController.confirmAnonymousName();
                        widget.onConfirmed();
                      },
                      label: 'Use this name',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
