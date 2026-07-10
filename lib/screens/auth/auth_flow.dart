import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import 'auth_credential_screen.dart';
import 'consent_screen.dart';
import 'display_name_screen.dart';
import 'welcome_screen.dart';

/// Nested navigator for Welcome → Auth → Name → Consent.
/// Completing consent updates [AuthController.profile]; the root app rebuilds Home.
class AuthFlow extends StatefulWidget {
  const AuthFlow({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => WelcomeScreen(
            onGetStarted: () {
              _navKey.currentState?.push(
                MaterialPageRoute<void>(
                  builder: (_) => AuthCredentialScreen(
                    authController: widget.authController,
                    onAuthenticated: () {
                      _navKey.currentState?.push(
                        MaterialPageRoute<void>(
                          builder: (_) => DisplayNameScreen(
                            authController: widget.authController,
                            onConfirmed: () {
                              _navKey.currentState?.push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ConsentScreen(
                                    authController: widget.authController,
                                    onCompleted: () {
                                      // Root ListenableBuilder swaps to Home.
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
