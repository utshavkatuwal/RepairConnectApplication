import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../../core/network/dio_client.dart';
import '../../shared/models/models.dart';

/// Location abstraction (§15). Provider (Carto/local) hidden behind interface.
/// Responsibilities: permission, current position, coordinates, address
/// resolve (via backend — no provider secrets in Flutter), map config,
/// location selection state, nearby queries (server-side ranking).
abstract class LocationService {
  Future<bool> ensurePermission();
  Future<LatLng?> currentPosition();
  Future<List<TechnicianNearby>> nearbyTechnicians(
      {required double lat, required double lng, String? categoryId});

  /// Reverse-geocode via backend (keeps provider keys server-side).
  /// Returns human address or null; never throws.
  Future<String?> resolveAddress(double lat, double lng);
}

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);

  String get label =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

/// Pure geo helpers (tested). Haversine distance in km.
double haversineKm(LatLng a, LatLng b) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final s = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(s));
}

String? validateLat(String? v) {
  if (v == null || v.trim().isEmpty) return 'Latitude required';
  final n = double.tryParse(v.trim());
  if (n == null || n < -90 || n > 90) return 'Latitude must be -90…90';
  return null;
}

String? validateLng(String? v) {
  if (v == null || v.trim().isEmpty) return 'Longitude required';
  final n = double.tryParse(v.trim());
  if (n == null || n < -180 || n > 180) {
    return 'Longitude must be -180…180';
  }
  return null;
}

class TechnicianNearby {
  final String id;
  final double distanceKm;
  const TechnicianNearby(this.id, this.distanceKm);
}

/// Carto/local-map implementation: OS GPS for position; nearby search via
/// backend (keeps ranking server-side, §20). Tile URLs from env/backend only.
class CartoLocationService implements LocationService {
  final DioClient? api;
  CartoLocationService({this.api});

  @override
  Future<bool> ensurePermission() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  @override
  Future<LatLng?> currentPosition() async {
    try {
      if (!await ensurePermission()) return null;
      final ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) return null;
      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TechnicianNearby>> nearbyTechnicians(
      {required double lat, required double lng, String? categoryId}) async {
    final client = api;
    if (client == null) return const [];
    try {
      final r = await client.getRetry('/api/v1/technicians', query: {
        'lat': lat,
        'lng': lng,
        // ignore: use_null_aware_elements
        if (categoryId != null) 'category_id': categoryId,
        'per_page': 20,
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      final techs = ApiListX.list(body, Technician.fromJson);
      // Distance computed server-side when available; fallback omitted
      // rather than fabricated (no fake distances in prod path).
      return [
        for (final t in techs) TechnicianNearby(t.id, 0),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> resolveAddress(double lat, double lng) async {
    final client = api;
    if (client == null) return null;
    try {
      final r = await client.getRetry('/api/v1/geocode/reverse',
          query: {'lat': lat, 'lng': lng});
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      if (data is Map) return data['address']?.toString();
      return null;
    } catch (_) {
      return null;
    }
  }
}

class ApiListX {
  static List<T> list<T>(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) from) {
    final d = json['data'];
    final items = d is List ? d : (d is Map ? d['items'] ?? [] : []);
    return ((items ?? []) as List)
        .map((e) => from(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class FakeLocationService implements LocationService {
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Future<LatLng?> currentPosition() async => const LatLng(6.5244, 3.3792);
  @override
  Future<List<TechnicianNearby>> nearbyTechnicians(
          {required double lat, required double lng, String? categoryId}) async =>
      const [];
  @override
  Future<String?> resolveAddress(double lat, double lng) async =>
      'Demo address near ${LatLng(lat, lng).label}';
}
