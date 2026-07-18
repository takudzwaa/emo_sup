import '../../models/listener_profile.dart';

/// Read model for booking directory (eventually `listener_public/{id}`).
abstract class ListenerDirectoryRepository {
  Future<List<ListenerProfile>> listListeners();

  Stream<List<ListenerProfile>> watchListeners();

  Future<ListenerProfile?> getListener(String listenerId);
}
