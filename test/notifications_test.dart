import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/services/notifications/push_service.dart';
import 'package:repairconnect/shared/models/models.dart';
import 'helpers/fakes.dart';

AppNotification n(String id, String type, {bool read = false}) =>
    AppNotification(
        id: id,
        type: type,
        title: 't',
        body: 'b',
        read: read,
        createdAt: '');

void main() {
  test('center records, merges, counts unread', () async {
    final center = NotificationCenter(FakeNotificationsRepository());
    expect(await center.unreadCount(), 1);
    center.record(
        type: NotificationTypes.payment,
        title: 'Pay',
        body: 'PENDING');
    expect(await center.unreadCount(), 2);
    final all = await center.all();
    expect(all.first.type, NotificationTypes.payment);
  });

  test('markRead clears local + delegates', () async {
    final center = NotificationCenter(FakeNotificationsRepository());
    center.record(
        type: NotificationTypes.review, title: 'R', body: 'b');
    final first = (await center.all()).first;
    await center.markRead(first.id);
    expect(await center.unreadCount(), 1);
  });

  test('filterByType narrows correctly', () {
    final items = [
      n('1', NotificationTypes.booking),
      n('2', NotificationTypes.payment),
      n('3', NotificationTypes.booking),
    ];
    expect(
        NotificationCenter.filterByType(
            items, NotificationTypes.booking).length,
        2);
    expect(
        NotificationCenter.filterByType(items, null).length, 3);
    expect(
        NotificationCenter.filterByType(
            items, NotificationTypes.review),
        isEmpty);
  });
}
