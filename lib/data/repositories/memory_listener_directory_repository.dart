import 'dart:async';

import '../../domain/repositories/listener_directory_repository.dart';
import '../../models/listener_profile.dart';

/// Seeded listener directory for prototype + tests.
class MemoryListenerDirectoryRepository implements ListenerDirectoryRepository {
  MemoryListenerDirectoryRepository({List<ListenerProfile>? listeners})
      : _listeners = List.unmodifiable(
          listeners ?? MemoryListenerDirectoryRepository.defaultListeners(),
        );

  final List<ListenerProfile> _listeners;
  final _controller =
      StreamController<List<ListenerProfile>>.broadcast();

  static List<ListenerProfile> defaultListeners() {
    return const [
      ListenerProfile(
        id: 'listener_harbor',
        displayName: 'Listener — Harbor',
        bio:
            'Calm presence for late-night overthinking. I listen without rushing you.',
        languages: ['English', 'Shona'],
      ),
      ListenerProfile(
        id: 'listener_moss',
        displayName: 'Listener — Moss',
        bio:
            'Here for family pressure and quiet company. Soft check-ins, no judgment.',
        languages: ['English', 'Ndebele'],
      ),
      ListenerProfile(
        id: 'listener_cedar',
        displayName: 'Listener — Cedar',
        bio:
            'Steady support when work or business stress piles up. Happy to sit with hard days.',
        languages: ['English', 'Shona', 'Ndebele'],
      ),
      ListenerProfile(
        id: 'listener_lantern',
        displayName: 'Listener — Lantern',
        bio:
            'Warm companion for lonely evenings. Share as little or as much as you like.',
        languages: ['English'],
        tier: ListenerTier.premium,
      ),
    ];
  }

  @override
  Future<List<ListenerProfile>> listListeners() async => _listeners;

  @override
  Stream<List<ListenerProfile>> watchListeners() async* {
    yield _listeners;
    yield* _controller.stream;
  }

  @override
  Future<ListenerProfile?> getListener(String listenerId) async {
    for (final l in _listeners) {
      if (l.id == listenerId) return l;
    }
    return null;
  }
}
