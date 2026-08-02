import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'config/listener_role.dart';
import 'data/listener_dashboard_store.dart';
import 'domain/repositories/safety_repository.dart';
import 'firebase_bootstrap.dart';
import 'screens/listener/listener_dashboard_screen.dart';
import 'theme/listener_theme.dart';

/// Separate entry point for the Listener Dashboard (vetted listeners only).
///
/// Run with:
/// ```
/// # Staging demo without a real claim:
/// flutter run -t lib/main_listener.dart --dart-define=FLAVOR=staging --dart-define=LISTENER_CLAIM=true
/// # Prod / real claim (role=listener on the signed-in user):
/// flutter run -t lib/main_listener.dart --dart-define=FLAVOR=prod
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await createAppServices();
  final gate = services.listenerRoleGate;
  final uid = services.auth.currentUid ?? 'listener_unknown';
  runApp(
    ListenerApp(
      roleGate: gate,
      store: ListenerDashboardStore(
        listenerId: uid,
        repository: services.listenerOps,
        chatRepository: services.chats,
        safetyRepository: services.safety,
      ),
      safetyRepository: services.safety,
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
      // Rebuild when the role claim resolves (sign-in / token refresh).
      home: ListenableBuilder(
        listenable: gate,
        builder: (context, _) => gate.isListener
            ? ListenerDashboardScreen(
                store: store,
                safetyRepository: safetyRepository,
              )
            : const _NotAListenerScreen(),
      ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Not a listener account',
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This entry is for vetted listeners with a role claim. '
                'If you need support, open the main app instead.',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
