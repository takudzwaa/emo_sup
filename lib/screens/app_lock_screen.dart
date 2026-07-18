import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/discreet_settings.dart';
import '../widgets/soft_surface.dart';

/// Full-screen PIN unlock (PR 21). No chat previews, no identity.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({
    super.key,
    required this.settings,
  });

  final DiscreetSettings settings;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = widget.settings.unlock(_pin.text);
    if (!ok) {
      setState(() {
        _error = 'Incorrect PIN. Try again.';
        _pin.clear();
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final discreet = widget.settings.discreetMode;

    return Scaffold(
      body: SoftGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: scheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  discreet ? 'Enter PIN' : 'Unlock Emo Sup',
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  discreet
                      ? 'Private notes are locked on this device.'
                      : 'App lock is on. Enter your 4-digit PIN.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(letterSpacing: 8),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                SoftPrimaryButton(
                  onPressed: _submit,
                  label: 'Unlock',
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
