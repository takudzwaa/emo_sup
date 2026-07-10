import 'package:flutter/material.dart';

/// Calmer, quieter Safety & Privacy hub — sturdy room, warmer Soft Premium.
class SafetyTheme {
  SafetyTheme._();

  static ThemeData wrap(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;

    final scheme = base.colorScheme.copyWith(
      primary: isDark ? const Color(0xFF8E9A96) : const Color(0xFF5A6A66),
      onPrimary: isDark ? const Color(0xFF1A1E1C) : Colors.white,
      secondary: isDark ? const Color(0xFFA89A8E) : const Color(0xFF8A7A6E),
      surface: isDark ? const Color(0xFF171513) : const Color(0xFFF3F0EC),
      onSurface: isDark ? const Color(0xFFDDD8D2) : const Color(0xFF2A2826),
      surfaceContainerHighest:
          isDark ? const Color(0xFF262220) : const Color(0xFFE6E1DB),
      outline: isDark ? const Color(0xFF45403C) : const Color(0xFFB8B0A8),
      error: isDark ? const Color(0xFFB88989) : const Color(0xFF8B6B6B),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.82),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.7)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
