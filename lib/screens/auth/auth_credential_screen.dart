import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_service.dart';
import '../../widgets/soft_surface.dart';

enum _AuthMode { email, phone }

/// Collects only the credential needed for Firebase Auth (email or phone).
/// No name, birthday, or photo.
class AuthCredentialScreen extends StatefulWidget {
  const AuthCredentialScreen({
    super.key,
    required this.authController,
    required this.onAuthenticated,
  });

  final AuthController authController;
  final VoidCallback onAuthenticated;

  @override
  State<AuthCredentialScreen> createState() => _AuthCredentialScreenState();
}

class _AuthCredentialScreenState extends State<AuthCredentialScreen> {
  _AuthMode _mode = _AuthMode.email;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authController.authenticateWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      widget.onAuthenticated();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPhoneCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final started = await widget.authController
          .startPhoneVerification(_phoneController.text);
      if (!mounted) return;
      setState(() {
        _verificationId = started.verificationId;
        _codeSent = true;
      });
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send a code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPhoneCode() async {
    final verificationId = _verificationId;
    if (verificationId == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authController.confirmPhoneCode(
        verificationId: verificationId,
        smsCode: _otpController.text,
      );
      if (!mounted) return;
      widget.onAuthenticated();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not verify that code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in privately'),
      ),
      body: SoftGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Use a phone number or email only to secure your account. '
                    'We never show these as your identity.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(
                    value: _AuthMode.email,
                    label: Text('Email'),
                    icon: Icon(Icons.email_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: _AuthMode.phone,
                    label: Text('Phone'),
                    icon: Icon(Icons.phone_outlined, size: 18),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _busy
                    ? null
                    : (next) {
                        setState(() {
                          _mode = next.first;
                          _error = null;
                          _codeSent = false;
                          _verificationId = null;
                          _otpController.clear();
                        });
                      },
              ),
              const SizedBox(height: 24),
              if (_mode == _AuthMode.email) ...[
                TextField(
                  controller: _emailController,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  enabled: !_busy,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitEmail(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Show' : 'Hide',
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Creates an account if you’re new, or signs you in if you '
                  'already have one. No name or photo is collected.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submitEmail,
                  child: Text(_busy ? 'Please wait…' : 'Continue'),
                ),
              ] else ...[
                TextField(
                  controller: _phoneController,
                  enabled: !_busy && !_codeSent,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-()]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+1 555 000 0000',
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otpController,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                      hintText: '6-digit code',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prototype: use code ${PrototypeAuthService.prototypeOtpHint} '
                    'when Firebase is not configured.',
                    style: textTheme.bodySmall,
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'We’ll send a one-time code. Your number is only used to '
                    'sign you in — never as a public profile.',
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : (_codeSent ? _confirmPhoneCode : _sendPhoneCode),
                  child: Text(
                    _busy
                        ? 'Please wait…'
                        : (_codeSent ? 'Verify and continue' : 'Send code'),
                  ),
                ),
                if (_codeSent)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _verificationId = null;
                              _otpController.clear();
                            }),
                    child: const Text('Use a different number'),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}
