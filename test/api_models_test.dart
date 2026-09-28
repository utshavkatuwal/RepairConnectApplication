import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/core/network/dio_client.dart';
import 'package:repairconnect/shared/models/models.dart';

void main() {
  test('envelope parses success + message + meta', () {
    final e = ApiResponse.envelope({
      'success': true,
      'data': {'id': '1', 'name': 'N', 'email': 'e', 'role': 'CUSTOMER'},
      'message': 'ok',
      'meta': {'page': 1},
    });
    expect(e.success, true);
    expect(e.message, 'ok');
    expect(e.data?['id'], '1');
  });

  test('paged parses items + meta', () {
    final p = ApiResponse.paged(
        {
          'success': true,
          'data': [
            {'id': 's1', 'category_id': 'c1', 'name': 'S', 'base_price': 10}
          ],
          'meta': {'page': 2, 'per_page': 20, 'total': 41, 'last_page': 3},
        },
        ServiceItem.fromJson);
    expect(p.items.length, 1);
    expect(p.page, 2);
    expect(p.hasMore, true);
  });

  test('models accept snake and camel keys', () {
    final a = Technician.fromJson(
        {'id': 1, 'userId': 'u', 'name': 'N', 'specialty': 'S'});
    expect(a.userId, 'u');
    final b = Booking.fromJson(
        {'id': 1, 'service_request_id': 'r', 'price': '12.5'});
    expect(b.requestId, 'r');
    expect(b.price, 12.5);
    final m = ChatMessage.fromJson(
        {'id': 1, 'content': 'hi', 'is_read': false});
    expect(m.body, 'hi');
    expect(m.read, false);
  });

  test('attachment upload guard', () {
    expect(
        AttachmentMeta.validateForUpload(
            mime: 'image/png', bytes: 1024),
        isNull);
    expect(
        AttachmentMeta.validateForUpload(
            mime: 'video/mp4', bytes: 10),
        isNotNull);
    expect(
        AttachmentMeta.validateForUpload(
            mime: 'image/png', bytes: 99 * 1024 * 1024),
        isNotNull);
  });

  test('strict transition table enforced', () {
    expect(JobStatus.canTransition('REQUESTED', 'ACCEPTED'), true);
    expect(JobStatus.canTransition('REQUESTED', 'COMPLETED'), false);
    expect(JobStatus.canTransition('IN_PROGRESS', 'DISPUTED'), true);
    expect(JobStatus.canTransition('COMPLETED', 'SCHEDULED'), false);
  });
}
