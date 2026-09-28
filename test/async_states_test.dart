import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/errors/failures.dart';
import 'package:repairconnect/core/network/connectivity.dart';

void main() {
  test('auth failure maps to login affordance', () {
    final d = displayFor(const AuthFailure('Session expired'));
    expect(d.isAuth, true);
    expect(d.isOffline, false);
  });

  test('not-found maps distinctly', () {
    final d = displayFor(const NotFoundFailure('Gone'));
    expect(d.isNotFound, true);
    expect(d.isAuth, false);
  });

  test('connection errors map to offline', () {
    final d = displayFor(
        const NetworkFailure('No connection to server. Retry when online.'));
    expect(d.isOffline, true);
    final d2 = displayFor(Exception('SocketException: OS Error'));
    expect(d2.isOffline, true);
  });

  test('validation errors stay plain with message', () {
    final d = displayFor(const ValidationFailure('Bad field'));
    expect(d.isAuth, false);
    expect(d.isOffline, false);
    expect(d.isNotFound, false);
    expect(d.message, 'Bad field');
  });

  test('generic errors pass through', () {
    final d = displayFor('plain string boom');
    expect(d.message, 'plain string boom');
  });
}
