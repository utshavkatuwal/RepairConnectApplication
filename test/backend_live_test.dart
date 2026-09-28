import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// Live contract test against the local Laravel API.
// Runs ONLY with: flutter test --dart-define=BACKEND_LIVE=true
// Requires: backend artisan serve on 127.0.0.1:8000 + seeded dev admin.
// Never runs in CI (skipped by default) and never mutates beyond login.
const _live =
    bool.fromEnvironment('BACKEND_LIVE', defaultValue: false);

void main() {
  test('live: health + specialties + admin login + me',
      skip: !_live, () async {
    final dio = Dio(BaseOptions(
        baseUrl: 'http://127.0.0.1:8000',
        headers: {'Accept': 'application/json'}));
    final health = await dio.get('/api/v1/health');
    expect(health.data['success'], true);
    expect(health.data['data']['database'], 'healthy');

    final specs = await dio.get('/api/v1/specialties');
    expect((specs.data['data'] as List).isNotEmpty, true);

    final login = await dio.post('/api/v1/auth/login', data: {
      'email': 'admin@repairconnect.dev',
      'password': 'password123',
    });
    final token = login.data['data']['token'] as String;
    expect(token.isNotEmpty, true);

    final me = await dio.get('/api/v1/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    expect(me.data['data']['role'], 'admin');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
