import 'package:flutter/material.dart';

/// Horizontal filter: "All" plus one chip per language.
///
/// [selected] is null when "All" is active.
class LanguageFilterChips extends StatelessWidget {
  const LanguageFilterChips({
    super.key,
    required this.languages,
    required this.selected,
    required this.onChanged,
  });

  final List<String> languages;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
              showCheckmark: false,
              selectedColor: scheme.primary.withValues(alpha: 0.18),
              checkmarkColor: scheme.primary,
              labelStyle: TextStyle(
                color: selected == null
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.75),
                fontWeight:
                    selected == null ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: selected == null
                    ? scheme.primary.withValues(alpha: 0.45)
                    : scheme.outline.withValues(alpha: 0.28),
              ),
            ),
          ),
          for (final lang in languages)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(lang),
                selected: selected == lang,
                onSelected: (_) => onChanged(lang),
                showCheckmark: false,
                selectedColor: scheme.primary.withValues(alpha: 0.18),
                checkmarkColor: scheme.primary,
                labelStyle: TextStyle(
                  color: selected == lang
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.75),
                  fontWeight:
                      selected == lang ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected == lang
                      ? scheme.primary.withValues(alpha: 0.45)
                      : scheme.outline.withValues(alpha: 0.28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
