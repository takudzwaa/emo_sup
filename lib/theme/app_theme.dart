import 'package:flutter/material.dart';

/// Jewel calm palette — soft indigo / teal / gold for confidential support.
/// All UI colors should come from [ColorScheme] / [ThemeData], not hardcoding.
class AppTheme {
  AppTheme._();

  /// Soft indigo seed (jewel calm)
  static const _seed = Color(0xFF6B7FD7);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      primary: const Color(0xFF6B7FD7),
      onPrimary: Colors.white,
      secondary: const Color(0xFF5BB8B0),
      onSecondary: Colors.white,
      tertiary: const Color(0xFFC9A87C), // premium gold
      surface: const Color(0xFFF5F2FB),
      onSurface: const Color(0xFF25233A),
      surfaceContainerHighest: const Color(0xFFE8E4F4),
      outline: const Color(0xFFB8B0C8),
      error: const Color(0xFFB07080),
      onError: Colors.white,
    );

    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      primary: const Color(0xFF9AA8F0),
      onPrimary: const Color(0xFF1A1B2E),
      secondary: const Color(0xFF7ED4CC),
      onSecondary: const Color(0xFF0F2A28),
      tertiary: const Color(0xFFD4B896),
      surface: const Color(0xFF1A1625),
      onSurface: const Color(0xFFEDE8F5),
      surfaceContainerHighest: const Color(0xFF2A2438),
      outline: const Color(0xFF5A5268),
      error: const Color(0xFFD0A0A8),
      onError: const Color(0xFF2A1818),
    );

    return _base(scheme);
  }

  /// Soft multi-layer shadow for elevated Soft Premium cards.
  /// Light mode tints toward violet for glass-card depth.
  static List<BoxShadow> softShadow(ColorScheme scheme, {double intensity = 1}) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = isDark ? Colors.black : const Color(0xFF504678);
    return [
      BoxShadow(
        color: base.withValues(alpha: (isDark ? 0.35 : 0.07) * intensity),
        blurRadius: 24 * intensity,
        offset: Offset(0, 8 * intensity),
      ),
      BoxShadow(
        color: base.withValues(alpha: (isDark ? 0.2 : 0.04) * intensity),
        blurRadius: 6 * intensity,
        offset: Offset(0, 2 * intensity),
      ),
    ];
  }

  /// Soft primary CTA gradient — indigo → teal.
  static LinearGradient primaryGradient(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.primary, scheme.secondary],
    );
  }

  /// Premium gold accent (tertiary jewel).
  static Color premiumAccent(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? const Color(0xFFD4B896)
          : const Color(0xFFC9A87C);

  /// Subtle scaffold wash — lilac → mint → ivory (light) / warm charcoal-plum (dark).
  static LinearGradient scaffoldGradient(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(scheme.surface, scheme.primary, 0.06)!,
          scheme.surface,
          Color.lerp(scheme.surface, scheme.secondary, 0.04)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF5F2FB),
        const Color(0xFFEEF7F5),
        const Color(0xFFFBF6F0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),
      bodyLarge: TextStyle(
        height: 1.5,
        color: scheme.onSurface,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        height: 1.45,
        color: scheme.onSurface.withValues(alpha: 0.88),
        fontSize: 15,
      ),
      bodySmall: TextStyle(
        height: 1.4,
        color: scheme.onSurface.withValues(alpha: 0.62),
        fontSize: 13,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: scheme.onPrimary,
        fontSize: 16,
      ),
    );

    final radius = BorderRadius.circular(18);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 17),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface.withValues(alpha: 0.72),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.72),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.65)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primary.withValues(alpha: 0.1),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface.withValues(alpha: 0.92),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : const Color(0xFFFFFBF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
        indicatorColor: scheme.primary,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outline.withValues(alpha: 0.2),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.28),
        thickness: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
