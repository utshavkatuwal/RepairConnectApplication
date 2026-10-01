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

  /// Public Carto key (tiles + reverse geocoding). Backend proxies
  /// geocoding with its own copy; this key is for tile requests only.
  static String get mapApiKey => dotenv.isInitialized
      ? dotenv.get('MAP_TILE_API_KEY', fallback: '')
      : '';

  /// Theme-aware Carto basemap: `dark_all` in dark mode, `voyager`
  /// in light mode. Optional MAP_TILE_URL override still wins (may
  /// contain `{z}/{x}/{y}` placeholders).
  static String mapTileUrlFor(Brightness brightness) {
    final override = dotenv.isInitialized
        ? dotenv.get('MAP_TILE_URL', fallback: '')
        : '';
    final base = override.isNotEmpty
        ? override
        : (brightness == Brightness.dark
            ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
            : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png');
    final key = mapApiKey;
    if (key.isEmpty) return base;
    // CARTO basemaps accept the key as `key=` (api_key= is ignored and
    // returns the "API KEY REQUIRED" watermark tile).
    return base.contains('?') ? '$base&key=$key' : '$base?key=$key';
  }

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
