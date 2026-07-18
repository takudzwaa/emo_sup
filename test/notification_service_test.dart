import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/domain/repositories/notification_service.dart';

void main() {
  test('private notification policy strips body by default', () async {
    final n = MemoryNotificationService();
    expect(n.allowNotificationBodies, isFalse);
    await n.registerToken('u1');
    expect(n.tokens['u1'], isNotEmpty);

    await n.notifyNewMessage(
      recipientUserId: 'u1',
      title: 'New message',
      body: 'Secret chat content',
    );
    expect(n.sent.single['body'], isEmpty);
    expect(n.sent.single['title'], 'New message');
  });

  test('bodies allowed only when explicitly enabled', () async {
    final n = MemoryNotificationService();
    await n.setAllowNotificationBodies(true);
    await n.notifyNewMessage(
      recipientUserId: 'u1',
      title: 'New message',
      body: 'Visible only if opted in',
    );
    expect(n.sent.single['body'], 'Visible only if opted in');
  });
}
