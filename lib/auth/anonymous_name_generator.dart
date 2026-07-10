import 'dart:math';

/// Builds anonymous display names: adjective + nature noun
/// (e.g. "Quiet River", "Calm Harbor"). Never real names.
class AnonymousNameGenerator {
  AnonymousNameGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const adjectives = <String>[
    'Quiet',
    'Calm',
    'Gentle',
    'Soft',
    'Still',
    'Kind',
    'Warm',
    'Clear',
    'Silent',
    'Tender',
    'Steady',
    'Mellow',
    'Peaceful',
    'Humble',
    'Open',
  ];

  static const natureNouns = <String>[
    'River',
    'Harbor',
    'Moss',
    'Cedar',
    'Lantern',
    'Meadow',
    'Stone',
    'Willow',
    'Cloud',
    'Creek',
    'Grove',
    'Shore',
    'Pine',
    'Dusk',
    'Brook',
  ];

  String generate() {
    final adj = adjectives[_random.nextInt(adjectives.length)];
    final noun = natureNouns[_random.nextInt(natureNouns.length)];
    return '$adj $noun';
  }

  /// Prefer a different name than [current] when regenerating.
  String generateDifferentFrom(String current) {
    for (var i = 0; i < 12; i++) {
      final next = generate();
      if (next != current) return next;
    }
    return generate();
  }
}
