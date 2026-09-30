import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Env/config: API base URL, map/payment/feature flags. Never commit real secrets.
///
/// Real-API mode is the ONLY runtime mode. There is no demo fallback:
/// if the server is unreachable the app shows error/offline states.
class AppEnv {
  static String get apiBaseUrl {
    if (dotenv.isInitialized) {
      final v = dotenv.get('API_BASE_URL', fallback: '').trim();
      if (v.isNotEmpty) return v;
    }
    // Platform-aware default so a missing .env still targets localhost:
    // Android emulator reaches the host via 10.0.2.2, everything else
    // uses loopback.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String get mapProvider =>
      dotenv.isInitialized ? dotenv.get('MAP_PROVIDER', fallback: 'carto') : 'carto';

  /// Public Carto basemap style URL (no secret). Provider keys, if any,
  /// stay server-side; Flutter only renders tiles + sends coordinates.
  static String get mapTileUrl => dotenv.isInitialized
      ? dotenv.get('MAP_TILE_URL',
          fallback:
              'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png')
      : 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  /// Fail-fast configuration check. Call once at startup: a malformed
  /// base URL is a loud startup error, never a silent demo fallback.
  static void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      throw StateError(
          'Invalid API_BASE_URL "$apiBaseUrl". Set a reachable http(s) URL in .env.');
    }
  }
}
