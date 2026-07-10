import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Soft elevated card used across Soft Premium screens.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.highlighted = false,
    this.borderRadius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool highlighted;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final bg = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.82);

    final borderColor = highlighted
        ? scheme.primary.withValues(alpha: 0.4)
        : scheme.outline.withValues(alpha: 0.16);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppTheme.softShadow(scheme, intensity: highlighted ? 1.15 : 1),
      ),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor, width: highlighted ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

/// Full-bleed warm Soft Premium gradient behind page content.
class SoftGradientBackground extends StatelessWidget {
  const SoftGradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.scaffoldGradient(scheme),
      ),
      child: child,
    );
  }
}

/// Compact confidentiality / encryption cue.
class TrustChip extends StatelessWidget {
  const TrustChip({
    super.key,
    this.label = 'Private & confidential',
    this.icon = Icons.lock_outline_rounded,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: scheme.primary.withValues(alpha: 0.9),
          ),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.primary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary Soft Premium CTA with soft gradient + shadow.
class SoftPrimaryButton extends StatelessWidget {
  const SoftPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: enabled
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                )
              : const BoxDecoration(),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: enabled ? AppTheme.primaryGradient(scheme) : null,
                  color: enabled
                      ? null
                      : scheme.onSurface.withValues(alpha: 0.12),
                ),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 20,
                          color: enabled
                              ? scheme.onPrimary
                              : scheme.onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: textTheme.labelLarge?.copyWith(
                          fontSize: 17,
                          color: enabled
                              ? scheme.onPrimary
                              : scheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
