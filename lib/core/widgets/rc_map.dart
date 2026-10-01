import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../theme.dart';
import '../config/env.dart';

/// Real Carto map (theme-aware dark/light tiles, key from env).
/// Used for location picking and job addresses — no fabricated canvas.
class RcMap extends StatelessWidget {
  /// Center in app coordinates (services/location LatLng-like numbers).
  final double? centerLat;
  final double? centerLng;
  final double zoom;
  final bool interactive;
  final void Function(double lat, double lng)? onTap;

  /// Single selection marker (e.g. picked location).
  final double? markerLat;
  final double? markerLng;

  const RcMap({
    super.key,
    this.centerLat,
    this.centerLng,
    this.zoom = 13,
    this.interactive = true,
    this.onTap,
    this.markerLat,
    this.markerLng,
  });

  @override
  Widget build(BuildContext context) {
    final dark = RepairColors.isDark(context);
    final hasMarker = markerLat != null && markerLng != null;
    final center = ll.LatLng(
      centerLat ?? markerLat ?? 27.7172,
      centerLng ?? markerLng ?? 85.3240,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                interactionOptions: InteractionOptions(
                  flags: interactive
                      ? InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.drag
                      : InteractiveFlag.none,
                ),
                onTap: onTap == null
                    ? null
                    : (_, p) => onTap!(p.latitude, p.longitude),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppEnv.mapTileUrlFor(
                      dark ? Brightness.dark : Brightness.light),
                  userAgentPackageName: 'com.example.repairconnect',
                  retinaMode: RetinaMode.isHighDensity(context),
                ),
                if (hasMarker)
                  MarkerLayer(markers: [
                    Marker(
                      point: ll.LatLng(markerLat!, markerLng!),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        size: 40,
                        color: dark ? RepairColors.teal : RepairColors.lightTeal,
                      ),
                    ),
                  ]),
              ],
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: Text(
                '© OpenStreetMap, © CARTO',
                style: TextStyle(
                    fontSize: 9,
                    color: dark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
