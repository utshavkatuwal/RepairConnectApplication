// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../services/location/location_service.dart';
import '../../theme.dart';
import 'rc_map.dart';
import 'rc_widgets.dart';

/// Location selection (15): permission states, GPS fix, interactive
/// Carto map (tap to place marker), manual coordinates with validation,
/// backend-resolved reverse-geocoded address.
class LocationPicker extends ConsumerStatefulWidget {
  final void Function(LatLng? pos, String address)? onChanged;
  final String initialAddress;
  const LocationPicker(
      {super.key, this.onChanged, this.initialAddress = ''});

  @override
  ConsumerState<LocationPicker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<LocationPicker> {
  final _addr = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  LatLng? _pos;
  String? _permErr;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _addr.text = widget.initialAddress;
  }

  Future<void> _reverse(double lat, double lng) async {
    try {
      final resolved =
          await ref.read(locationServiceProvider).resolveAddress(lat, lng);
      if (resolved != null && resolved.isNotEmpty && mounted) {
        setState(() => _addr.text = resolved);
        // Parent filled its address from the (still empty) sync callback;
        // re-notify now that the backend actually resolved one.
        widget.onChanged?.call(_pos, resolved);
      }
    } catch (_) {
      // Reverse geocode is best-effort; coordinates remain authoritative.
    }
  }

  Future<void> _useGps() async {
    setState(() {
      _busy = true;
      _permErr = null;
    });
    try {
      final svc = ref.read(locationServiceProvider);
      final ok = await svc.ensurePermission();
      if (!ok) {
        setState(() => _permErr =
            'Location permission denied. Tap the map or enter coordinates.');
        return;
      }
      final pos = await svc.currentPosition();
      if (pos == null) {
        setState(() =>
            _permErr = 'GPS unavailable. Tap the map or enter coordinates.');
        return;
      }
      setState(() {
        _pos = pos;
        _lat.text = pos.lat.toStringAsFixed(5);
        _lng.text = pos.lng.toStringAsFixed(5);
      });
      await _reverse(pos.lat, pos.lng);
      widget.onChanged?.call(_pos, _addr.text.trim());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setPos(double la, double ln) {
    if (la < -90 || la > 90 || ln < -180 || ln > 180) return;
    setState(() {
      _pos = LatLng(la, ln);
      _lat.text = la.toStringAsFixed(5);
      _lng.text = ln.toStringAsFixed(5);
    });
    _reverse(la, ln);
    widget.onChanged?.call(_pos, _addr.text.trim());
  }

  void _manual() {
    final la = double.tryParse(_lat.text.trim());
    final ln = double.tryParse(_lng.text.trim());
    if (la == null || ln == null) return;
    _setPos(la, ln);
  }

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SERVICE LOCATION',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          const SizedBox(height: 8),
          RcMap(
            centerLat: _pos?.lat,
            centerLng: _pos?.lng,
            markerLat: _pos?.lat,
            markerLng: _pos?.lng,
            onTap: (lat, lng) => _setPos(lat, lng),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(_pos == null
                    ? 'Tap the map or use GPS to set coordinates'
                    : 'GPS: ${_pos!.label}'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : _useGps,
                icon: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.my_location, size: 16),
                label: Text('Use GPS', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_permErr != null)
            Text(_permErr!,
                style:
                    TextStyle(fontSize: 11, color: RepairColors.copper)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'LAT (-90 to 90)'),
                  validator: validateLat,
                  onChanged: (_) => _manual(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'LNG (-180 to 180)'),
                  validator: validateLng,
                  onChanged: (_) => _manual(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Carto map tiles (dark/light follow app theme). Coordinates are sent with the request; ranking stays server-side.',
              style: TextStyle(
                  fontSize: 10,
                  color: RepairColors.faintOn(context))),
        ],
      ),
    );
  }
}
