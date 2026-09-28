import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Env/config: API base URL, map/payment/feature flags. Never commit real secrets.
class AppEnv {
  static String get apiBaseUrl =>
      dotenv.isInitialized ? dotenv.get('API_BASE_URL', fallback: 'http://localhost:8000') : 'http://localhost:8000';
  static String get mapProvider =>
      dotenv.isInitialized ? dotenv.get('MAP_PROVIDER', fallback: 'carto') : 'carto';

  /// Public Carto basemap style URL (no secret). Provider keys, if any,
  /// stay server-side; Flutter only renders tiles + sends coordinates.
  static String get mapTileUrl => dotenv.isInitialized
      ? dotenv.get('MAP_TILE_URL',
          fallback:
              'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png')
      : 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
  static bool get useFakeBackend => dotenv.isInitialized
      ? dotenv.get('USE_FAKE_BACKEND', fallback: 'true') == 'true'
      : true;
}
