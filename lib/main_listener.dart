import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'config/listener_role.dart';
import 'data/listener_dashboard_store.dart';
import 'data/repositories/memory_safety_repository.dart';
import 'domain/repositories/safety_repository.dart';
import 'screens/listener/listener_dashboard_screen.dart';
import 'theme/listener_theme.dart';

/// Separate entry point for the Listener Dashboard (vetted listeners only).
///
/// Run with:
/// ```
/// flutter run -t lib/main_listener.dart --dart-define=LISTENER_CLAIM=true
/// ```
///
/// Without a listener claim, shows a blocked screen (PR 20).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final gate = ListenerRoleGate();
  runApp(
    ListenerApp(
      roleGate: gate,
      safetyRepository: MemorySafetyRepository(),
    ),
  );
}

class ListenerApp extends StatelessWidget {
  const ListenerApp({
    super.key,
    this.store,
    this.roleGate,
    this.safetyRepository,
  });

  final ListenerDashboardStore? store;
  final ListenerRoleGate? roleGate;
  final SafetyRepository? safetyRepository;

  @override
  Widget build(BuildContext context) {
    final gate = roleGate ?? ListenerRoleGate();
    return MaterialApp(
      onGenerateTitle: (context) =>
          '${AppLocalizations.of(context).appTitle} · Listener',
      debugShowCheckedModeBanner: false,
      theme: ListenerTheme.light(),
      darkTheme: ListenerTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: gate.isListener
          ? ListenerDashboardScreen(
              store: store,
              safetyRepository: safetyRepository,
            )
          : const _NotAListenerScreen(),
    );
  }
}

class _NotAListenerScreen extends StatelessWidget {
  const _NotAListenerScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.lock_outline, size: 48, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                'Not a listener account',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This dashboard is only for vetted listeners. '
                'If you were approved, sign out and back in after your claim is set, '
                'or use a build with LISTENER_CLAIM=true for local demos.',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
