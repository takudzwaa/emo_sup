import 'package:flutter/material.dart';

/// Soft avatar for anonymous usernames — initials or icon, never a photo.
class AnonymousAvatar extends StatelessWidget {
  const AnonymousAvatar({
    super.key,
    required this.displayName,
    this.size = 40,
  });

  final String displayName;
  final double size;

  String get _initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word[0].toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final warmer = Color.lerp(scheme.primary, scheme.secondary, 0.35)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.22),
            warmer.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
