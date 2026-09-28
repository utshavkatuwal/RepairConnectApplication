// ignore_for_file: use_null_aware_elements
import '../constants/app_constants.dart';

/// Backend contract bridge (§52): the Laravel API speaks lowercase
/// snake_case (`requested`, `technician_arriving`, `customer`), while the
/// Flutter domain uses SCREAMING states/roles. All translation happens
/// here at the repository boundary — never in widgets, never trusted
/// blindly (unknown values fall back safely and actions hide).
String normalizeStatus(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'requested':
    case 'searching':
    case 'offered':
      return JobStatus.requested;
    case 'accepted':
      return JobStatus.accepted;
    case 'scheduled':
      return JobStatus.scheduled;
    case 'technician_arriving':
      return JobStatus.enRoute;
    case 'arrived':
      return JobStatus.arrived;
    case 'in_progress':
      return JobStatus.inProgress;
    case 'completed':
      return JobStatus.completed;
    case 'cancelled':
      return JobStatus.cancelled;
    case 'disputed':
      return JobStatus.disputed;
    default:
      // Unknown future state: surface read-only (no transitions match).
      return raw.trim().toUpperCase();
  }
}

String normalizeRole(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'customer':
      return AppRoles.customer;
    case 'technician':
      return AppRoles.technician;
    case 'admin':
    case 'super_admin':
      return AppRoles.admin;
    default:
      return AppRoles.customer;
  }
}

/// Flutter SCREAMING role -> API lowercase role for outbound requests.
String apiRole(String role) {
  switch (role) {
    case AppRoles.technician:
      return 'technician';
    case AppRoles.admin:
      return 'admin';
    default:
      return 'customer';
  }
}

/// Backend ServiceRequest shape differs from the legacy fake shape:
/// `{specialty_id,title,description,address,lat,lng,scheduled_at}`.
/// Returns the POST body for a create-request call.
Map<String, dynamic> serviceRequestBody({
  required String specialtyId,
  String? title,
  required String description,
  required String address,
  String? preferredAt,
}) {
  var addr = address;
  double? lat;
  double? lng;
  // LocationPicker appends " [lat, lng]" — split into real coordinates.
  final m = RegExp(r'^(.*)\[(-?\d+(\.\d+)?),\s*(-?\d+(\.\d+)?)\]\s*$')
      .firstMatch(address);
  if (m != null) {
    addr = m.group(1)!.trim();
    lat = double.tryParse(m.group(2)!);
    lng = double.tryParse(m.group(4)!);
  }
  final cleanTitle = (title == null || title.trim().isEmpty)
      ? (description.trim().length <= 40
          ? description.trim()
          : '${description.trim().substring(0, 40)}…')
      : title.trim();
  return {
    'specialty_id': specialtyId,
    'title': cleanTitle,
    'description': description,
    'address': addr,
    if (lat != null) 'latitude': lat,
    if (lng != null) 'longitude': lng,
    if (preferredAt != null) 'scheduled_at': preferredAt,
  };
}
