import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Listener-role palette: soft sage-plum — same Soft Premium system as
/// [AppTheme], clearly a different role (not the user jewel teal-slate).
class ListenerTheme {
  ListenerTheme._();

  /// Soft plum seed — keeps listener role distinct from user indigo.
  static const _seed = Color(0xFF7A6B8A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      primary: const Color(0xFF6B5F78),
      onPrimary: Colors.white,
      secondary: const Color(0xFF8FA88E), // soft sage when online
      onSecondary: Colors.white,
      tertiary: const Color(0xFFC4A882),
      surface: const Color(0xFFF6F2EF),
      onSurface: const Color(0xFF2C282E),
      surfaceContainerHighest: const Color(0xFFE8E2E8),
      outline: const Color(0xFFC4B8C0),
      error: const Color(0xFFA07070),
      onError: Colors.white,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      primary: const Color(0xFFB8ABC6),
      onPrimary: const Color(0xFF241F2A),
      secondary: const Color(0xFFA3B5A6),
      onSecondary: const Color(0xFF1A221C),
      tertiary: const Color(0xFFD4B896),
      surface: const Color(0xFF1B181C),
      onSurface: const Color(0xFFE8E3E9),
      surfaceContainerHighest: const Color(0xFF2C2830),
      outline: const Color(0xFF524A56),
      error: const Color(0xFFC9A0A0),
      onError: const Color(0xFF2A1818),
    );
    return _base(scheme);
  }

  /// Listener scaffold wash — plum → sage → warm ivory (aligned with jewel pattern).
  static LinearGradient scaffoldGradient(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(scheme.surface, scheme.primary, 0.07)!,
          scheme.surface,
          Color.lerp(scheme.surface, scheme.secondary, 0.05)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF6F2EF),
        const Color(0xFFF0F4F0),
        const Color(0xFFFBF6F2),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final userLike = AppTheme.light();
    final textTheme = userLike.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface.withValues(alpha: 0.9),
        ),
        bodyLarge: TextStyle(height: 1.5, color: scheme.onSurface),
        bodyMedium: TextStyle(
          height: 1.45,
          color: scheme.onSurface.withValues(alpha: 0.88),
        ),
        bodySmall: TextStyle(
          height: 1.4,
          color: scheme.onSurface.withValues(alpha: 0.62),
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: scheme.onPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onSecondary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.secondary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface.withValues(alpha: 0.72),
          minimumSize: const Size(48, 48),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.28),
        thickness: 1,
      ),
    );
  }
}
