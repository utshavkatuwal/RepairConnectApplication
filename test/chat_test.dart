import 'package:flutter_test/flutter_test.dart';
import 'helpers/fakes.dart';
import 'package:repairconnect/shared/models/models.dart';

void main() {
  test('send persists and history returns in order', () async {
    final svc = InMemoryChatService();
    await svc.send('c1', 'hello');
    await svc.send('c1', 'world');
    final h = await svc.history('c1');
    expect(h.length, 2);
    expect(h.first.body, 'hello');
    expect(h.last.body, 'world');
  });

  test('empty body rejected, no phantom message', () async {
    final svc = InMemoryChatService();
    expect(() => svc.send('c1', '   '), throwsArgumentError);
    expect(await svc.history('c1'), isEmpty);
  });

  test('markRead flips receipts', () async {
    final svc = InMemoryChatService();
    await svc.send('c1', 'hi');
    await svc.markRead('c1');
    final h = await svc.history('c1');
    expect(h.first.read, true);
  });

  test('stream emits new messages', () async {
    final svc = InMemoryChatService();
    final fut = svc.stream('c1').first;
    await svc.send('c1', 'live');
    final m = await fut;
    expect(m.body, 'live');
  });

  test('message type defaults to text, parses explicit', () {
    final a = ChatMessage.fromJson({'id': 1, 'body': 'x'});
    expect(a.type, 'text');
    final b =
        ChatMessage.fromJson({'id': 1, 'body': 'x', 'type': 'image'});
    expect(b.type, 'image');
  });

  test('parses real backend message shape', () {
    final m = ChatMessage.fromJson({
      'id': 9,
      'conversation_id': 1,
      'sender_id': 6,
      'message': 'Hello from customer',
      'message_type': 'text',
      'created_at': '2026-09-28T12:00:00Z',
      'read_at': null,
    });
    expect(m.body, 'Hello from customer');
    expect(m.type, 'text');
    expect(m.read, false);
    expect(m.toJson()['message'], 'Hello from customer');
  });
}
