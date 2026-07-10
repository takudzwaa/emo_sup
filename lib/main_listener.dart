import 'package:flutter/material.dart';

import 'data/listener_dashboard_store.dart';
import 'screens/listener/listener_dashboard_screen.dart';
import 'theme/listener_theme.dart';

/// Separate entry point for the Listener Dashboard (vetted listeners only).
///
/// Run with:
/// ```
/// flutter run -t lib/main_listener.dart
/// ```
///
/// Distinct from the end-user app (`lib/main.dart`) — plum accent, no
/// user onboarding shell.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ListenerApp());
}

class ListenerApp extends StatelessWidget {
  const ListenerApp({
    super.key,
    this.store,
  });

  final ListenerDashboardStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emo Sup · Listener',
      debugShowCheckedModeBanner: false,
      theme: ListenerTheme.light(),
      darkTheme: ListenerTheme.dark(),
      themeMode: ThemeMode.system,
      home: ListenerDashboardScreen(store: store),
    );
  }
}
