import '../../models/active_chat_summary.dart';

/// Listener-facing ops: availability, active chats, upcoming bookings.
abstract class ListenerOpsRepository {
  Future<bool> getAvailableNow(String listenerId);

  Future<void> setAvailableNow(String listenerId, bool value);

  Stream<bool> watchAvailableNow(String listenerId);

  Future<List<ActiveChatSummary>> listActiveChats(String listenerId);

  Stream<List<ActiveChatSummary>> watchActiveChats(String listenerId);

  Future<List<ListenerBookingSummary>> listUpcomingBookings(String listenerId);

  Future<void> markChatRead(String listenerId, String sessionId);

  Future<void> escalateChat({
    required String sessionId,
    required String listenerId,
    String reason = 'listener_escalation',
  });
}
