import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/network/dio_client.dart';
import 'package:repairconnect/shared/models/models.dart';

void main() {
  test('paged clamps single page and reports hasMore', () {
    const p = Paged<ServiceItem>(
        items: [], page: 1, perPage: 20, total: 0, lastPage: 1);
    expect(p.hasMore, false);
    expect(p.items, isEmpty);
  });

  test('paged envelope honors server meta', () {
    final p = ApiResponse.paged(
        {
          'success': true,
          'data': [
            {
              'id': 't1',
              'user_id': 'u1',
              'name': 'N',
              'specialty': 'S'
            }
          ],
          'meta': {
            'page': 1,
            'per_page': 20,
            'total': 41,
            'last_page': 3
          },
        },
        Technician.fromJson);
    expect(p.items.length, 1);
    expect(p.hasMore, true);
    expect(p.total, 41);
  });

  test('paged tolerates missing meta without crashing', () {
    final p = ApiResponse.paged(
        {
          'success': true,
          'data': [],
        },
        Technician.fromJson);
    expect(p.hasMore, false);
    expect(p.page, 1);
  });
}
