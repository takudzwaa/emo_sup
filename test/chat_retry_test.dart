import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/chat_store.dart';
import 'package:emo_sup/models/chat_message.dart';
import 'package:emo_sup/models/chat_session.dart';

void main() {
  test('client message ids are unique and non-empty', () async {
    final store = ChatStore(
      session: ChatSession(
        id: 's1',
        userId: 'u1',
        listenerId: 'l1',
        startedAt: DateTime.now(),
      ),
      seedMessages: const [],
      mockListenerReplies: false,
      actingAsId: 'u1',
    );

    await store.sendMessage('Hello');
    await store.sendMessage('Again');
    final mine = store.messages.where((m) => m.senderId == 'u1').toList();
    expect(mine.length, 2);
    expect(mine[0].id, isNot(equals(mine[1].id)));
    expect(mine[0].id, startsWith('msg_'));
  });

  test('failed message can be retried with same id', () async {
    final store = ChatStore(
      session: ChatSession(
        id: 's1',
        userId: 'u1',
        listenerId: 'l1',
        startedAt: DateTime.now(),
      ),
      seedMessages: const [],
      mockListenerReplies: false,
      actingAsId: 'u1',
    );

    store.debugForceNextSendFail = true;
    await store.sendMessage('Will fail');
    final failed = store.messages.singleWhere((m) => m.senderId == 'u1');
    expect(failed.status, MessageStatus.failed);
    final id = failed.id;

    await store.retryMessage(id);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final after = store.messages.singleWhere((m) => m.id == id);
    expect(after.status, isNot(MessageStatus.failed));
    expect(after.text, 'Will fail');
  });

  test('blocked peer prevents send', () async {
    final store = ChatStore(
      session: ChatSession(
        id: 's1',
        userId: 'u1',
        listenerId: 'l1',
        startedAt: DateTime.now(),
      ),
      seedMessages: const [],
      mockListenerReplies: false,
      actingAsId: 'u1',
      blockedPeerIds: {'l1'},
    );

    await store.sendMessage('Should not send');
    expect(store.messages.where((m) => m.senderId == 'u1'), isEmpty);
  });
}
