import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/services/location/location_service.dart';

void main() {
  test('haversine Lagos to Abuja ~ 500-600km', () {
    const lagos = LatLng(6.5244, 3.3792);
    const abuja = LatLng(9.0765, 7.3986);
    final d = haversineKm(lagos, abuja);
    expect(d, greaterThan(400));
    expect(d, lessThan(700));
  });

  test('haversine same point is zero', () {
    const p = LatLng(0, 0);
    expect(haversineKm(p, p), 0);
  });

  test('coordinate validators enforce ranges', () {
    expect(validateLat('91'), isNotNull);
    expect(validateLat('-91'), isNotNull);
    expect(validateLat('6.5'), isNull);
    expect(validateLng('181'), isNotNull);
    expect(validateLng('-181'), isNotNull);
    expect(validateLng('3.3'), isNull);
    expect(validateLat('abc'), isNotNull);
  });
}
