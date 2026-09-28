import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/security/input_safety.dart';
import 'package:repairconnect/core/utils/validators.dart';

void main() {
  test('sanitize trims, collapses, strips controls, caps', () {
    expect(sanitizeText('  hello   world  '), 'hello world');
    expect(sanitizeText('a\u0000b'), 'ab');
    expect(sanitizeText('x' * 3000, max: 10).length, 10);
  });

  test('safeFilename strips paths and evil chars', () {
    expect(safeFilename('../../etc/passwd'), isNot(contains('/')));
    expect(safeFilename('My Photo.JPG'), isNot(contains(' ')));
    expect(safeFilename('..'), isNot('..'));
  });

  test('redactSecrets hides tokens', () {
    final m = redactSecrets(
        {'email': 'a@b.co', 'password': 'x', 'token': 'abc'});
    expect(m['email'], 'a@b.co');
    expect(m['password'], '***');
    expect(m['token'], '***');
  });

  test('normalizeEmail lowercases', () {
    expect(normalizeEmail('  User@X.CO '), 'user@x.co');
  });

  test('new validators: description, message, future date, price', () {
    expect(descriptionValidator('short'), isNotNull);
    expect(descriptionValidator('long enough text here'), isNull);
    expect(messageValidator('   '), isNotNull);
    expect(messageValidator('x' * 2001), isNotNull);
    expect(messageValidator('hi'), isNull);
    expect(
        futureDateValidator(
            DateTime.now().subtract(const Duration(hours: 1))),
        isNotNull);
    expect(
        futureDateValidator(
            DateTime.now().add(const Duration(hours: 1))),
        isNull);
    expect(priceValidator(-1), isNotNull);
    expect(priceValidator(0), isNotNull);
    expect(priceValidator(99.99), isNull);
  });
}
