// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_mapper.dart';
import '../../../core/security/input_safety.dart';
import '../../../shared/models/models.dart';
import '../../bookings/domain/job_machine.dart'
    show JobMachine;

/// Repositories: Dio -> Laravel REST. Every method hits the real API;
/// failures surface as typed Failures. No business data hardcoded in widgets.

/// Tiny TTL cache for reference data (categories). Booking/payment/chat
/// data is never cached — always server-verified.
class _TtlCache<T> {
  T? value;
  DateTime? at;
  final Duration ttl;
  _TtlCache(this.ttl);
  bool get fresh =>
      value != null &&
      at != null &&
      DateTime.now().difference(at!) < ttl;
  void set(T v) {
    value = v;
    at = DateTime.now();
  }

  void clear() {
    value = null;
    at = null;
  }
}

class CatalogRepository {
  final DioClient api;
  final _cats = _TtlCache<List<Category>>(const Duration(minutes: 10));
  CatalogRepository(this.api);

  Future<List<Category>> categories({bool force = false}) async {
    if (!force && _cats.fresh) return _cats.value!;
    try {
      final r = await api.getRetry(ApiRoutes.categories);
      final body = Map<String, dynamic>.from(r.data as Map);
      final list = ApiResponse.list(body, Category.fromJson);
      _cats.set(list);
      return list;
    } catch (e) {
      if (_cats.value != null) return _cats.value!;
      throw api.mapError(e);
    }
  }

  /// Services resolve from backend specialties (there is no services
  /// table by design — a request carries specialty + title). Each
  /// specialty surfaces as one bookable item; price is estimated at
  /// request time, never a stored promise.
  Future<Paged<ServiceItem>> servicesPaged(
      {String? categoryId,
      String? q,
      int page = 1,
      int perPage = 20}) async {
    try {
      final cats = await categories();
      final wanted = {
        for (final c in cats)
          if (categoryId == null || c.id == categoryId) c.id: c
      };
      final ql = q?.toLowerCase();
      final items = [
        for (final c in wanted.values)
          if (ql == null || c.name.toLowerCase().contains(ql))
            ServiceItem(
                id: c.id,
                categoryId: c.id,
                name: c.name,
                description: null,
                basePrice: 0),
      ];
      return Paged(
          items: items
              .skip((page - 1) * perPage)
              .take(perPage)
              .toList(),
          page: page,
          perPage: perPage,
          total: items.length,
          lastPage: (items.length / perPage).ceil().clamp(1, 1 << 30));
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<ServiceItem>> services({String? categoryId, String? q}) async =>
      (await servicesPaged(categoryId: categoryId, q: q)).items;

  /// Paginated technician search (§20): keyword, category, specialty,
  /// location, availability server-side. Never bulk-download.
  Future<Paged<Technician>> techniciansPaged(
      {String? q,
      String? categoryId,
      double? lat,
      double? lng,
      bool? available,
      int page = 1,
      int perPage = 20}) async {
    try {
      final r = await api.getRetry(ApiRoutes.technicians, query: {
        if (q != null) 'q': q,
        if (categoryId != null) 'category_id': categoryId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (available != null) 'available': available ? 1 : 0,
        'page': page,
        'per_page': perPage,
      });
      return ApiResponse.paged(
          Map<String, dynamic>.from(r.data as Map),
          Technician.fromJson);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Technician>> technicians(
          {String? q,
          String? categoryId,
          double? lat,
          double? lng}) async =>
      (await techniciansPaged(
              q: q, categoryId: categoryId, lat: lat, lng: lng))
          .items;

  /// Open requests visible to an eligible technician (backend enforces
  /// approval + specialty + radius; 403 while pending).
  Future<List<ServiceRequest>> openRequests() async {
    try {
      final r = await api.getRetry('/api/v1/technician/requests');
      final body = Map<String, dynamic>.from(r.data as Map);
      return ApiResponse.list(body, ServiceRequest.fromJson);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  /// Own technician profile with live stats (rating, completed, docs).
  Future<Map<String, dynamic>> technicianProfile() async {
    try {
      final r = await api.getRetry('/api/v1/technician/profile');
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (e) {
      throw api.mapError(e);
    }
  }
}

class BookingsRepository {
  final DioClient api;
  BookingsRepository(this.api);

  static String? _validateReason(String to, String? reason) =>
      JobMachine.validateReason(to, reason);

  static bool _canActor(
          {required String role,
          required String from,
          required String to}) =>
      JobMachine.canActor(role: role, from: from, to: to);

  /// Service requests keep their own id until a technician accepts and
  /// the backend mints a job (separate id sequence). The app carries a
  /// request as `req-{id}` so job endpoints are never hit with an id they
  /// cannot resolve; [booking] swaps to the job id once one exists.
  static const _reqPrefix = 'req-';

  static bool isServiceRequest(String id) => id.startsWith(_reqPrefix);

  static Booking _bookingFromServiceRequest(Map<String, dynamic> sr) =>
      Booking.fromJson({
        ...sr,
        'id': '$_reqPrefix${sr['id']}',
        'request_id': '${sr['id']}',
      });

  Future<Map<String, dynamic>> _serviceRequest(String srId) async {
    final r = await api.getRetry('${ApiRoutes.serviceRequests}/$srId');
    final body = Map<String, dynamic>.from(r.data as Map);
    final env = ApiResponse.envelope(body);
    return env.data ??
        Map<String, dynamic>.from(
            body['data'] as Map? ?? <String, dynamic>{});
  }

  /// Current user's bookings: history, invoices, payments derive from this.
  /// Requests nobody has accepted yet have no job row, so they are merged
  /// in front of the jobs list — the customer must see what is still
  /// waiting. That endpoint is customer-scoped (role:customer); technicians
  /// and admins get a 403 here and simply see their jobs.
  Future<List<Booking>> myBookings() async {
    try {
      final r = await api.getRetry(ApiRoutes.bookings,
          query: {'mine': 1, 'per_page': 50});
      final jobs = ApiResponse.list(
          Map<String, dynamic>.from(r.data as Map), Booking.fromJson);
      var requests = const <Booking>[];
      try {
        final sr = await api.getRetry(ApiRoutes.serviceRequests,
            query: {'per_page': 50});
        final rows = ApiResponse.list(
            Map<String, dynamic>.from(sr.data as Map), (m) => m);
        requests = [
          for (final m in rows)
            if (m['job_id'] == null) _bookingFromServiceRequest(m),
        ];
      } catch (_) {
        // Customer-only endpoint: other roles are excluded by the
        // middleware, not by an error in this user's data.
      }
      return [...requests, ...jobs];
    } catch (e) {
      throw api.mapError(e);
    }
  }

  /// serviceId doubles as the backend specialty id (Flutter catalog
  /// categories map 1:1 to backend specialties; see FLUTTER_MAPPING).
  Future<ServiceRequest> createRequest(
      {required String serviceId,
      required String description,
      String? title,
      String? preferredAt,
      String? address}) async {
    final cleanDesc = sanitizeText(description, max: 2000);
    final cleanAddr =
        address == null ? null : sanitizeText(address, max: 512);
    if (cleanDesc.length < 10) {
      throw const ValidationFailure('Describe the problem (min 10 chars)');
    }
    try {
      // Backend shape: specialty_id/title/description/address/lat/lng.
      final body = serviceRequestBody(
        specialtyId: serviceId,
        title: title,
        description: cleanDesc,
        address: cleanAddr ?? '',
        preferredAt: preferredAt,
      );
      final r =
          await api.dio.post(ApiRoutes.serviceRequests, data: body);
      final env =
          ApiResponse.envelope(Map<String, dynamic>.from(r.data as Map));
      return ServiceRequest.fromJson(
          env.data ?? Map<String, dynamic>.from((r.data as Map)['data']));
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  /// Explicit acceptance: backend validates eligibility, locks the
  /// request, creates the job. Returns the real job or throws the
  /// backend error (e.g. 409 already taken, 403 not approved).
  Future<Booking> acceptRequest(String requestId) async {
    try {
      final r = await api.dio
          .post('${ApiRoutes.bookings}/$requestId/accept');
      final body = Map<String, dynamic>.from(r.data as Map);
      final env = ApiResponse.envelope(body);
      return Booking.fromJson(
          env.data ?? Map<String, dynamic>.from(body['data']));
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  /// Resolves a booking id in either id space: `req-{id}` returns the
  /// service request (and switches to the real job as soon as one exists),
  /// a plain id is fetched as a job.
  Future<Booking> booking(String id) async {
    if (isServiceRequest(id)) {
      try {
        final sr = await _serviceRequest(id.substring(_reqPrefix.length));
        final jobId = sr['job_id'];
        if (jobId != null) return await booking('$jobId');
        return _bookingFromServiceRequest(sr);
      } on DioException catch (e) {
        throw api.mapError(e);
      }
    }
    try {
      final r = await api.getRetry('${ApiRoutes.bookings}/$id');
      final body = Map<String, dynamic>.from(r.data as Map);
      final env = ApiResponse.envelope(body);
      return Booking.fromJson(
          env.data ?? Map<String, dynamic>.from(body['data']));
    } catch (e) {
      throw api.mapError(e);
    }
  }

  /// Strict transition: validates from→to + actor + reason client-side
  /// for fast UX AND relies on server authoritative rejection (§35).
  /// Before acceptance the id space is the service request: only the
  /// technician's accept and the customer's cancel exist there (§14 —
  /// no job means no lifecycle moves, no chat, no bill).
  Future<Booking> transition(String id, String to,
      {String? knownFrom, String? actorRole, String? reason}) async {
    if (!JobStatus.transitions.values.any((l) => l.contains(to)) &&
        !JobStatus.ordered.contains(to) &&
        to != JobStatus.cancelled &&
        to != JobStatus.disputed) {
      throw const ValidationFailure('Unknown status');
    }
    final reasonErr = _validateReason(to, reason);
    if (reasonErr != null) throw ValidationFailure(reasonErr);
    try {
      // Fetch current to validate locally before POST (fast UX).
      final cur = await booking(id);
      if (!JobStatus.canTransition(cur.status, to)) {
        throw ValidationFailure(
            'Cannot move from ${cur.status} to $to');
      }
      if (actorRole != null &&
          !_canActor(role: actorRole, from: cur.status, to: to)) {
        throw const ValidationFailure(
            'Your role cannot perform this transition');
      }
      if (isServiceRequest(cur.id)) {
        final srId = cur.id.substring(_reqPrefix.length);
        if (to == JobStatus.accepted) return await acceptRequest(srId);
        if (to == JobStatus.cancelled) {
          await api.dio.post('${ApiRoutes.serviceRequests}/$srId/cancel',
              data: {'reason': reason});
          return await booking(cur.id);
        }
        throw const ValidationFailure(
            'No technician has accepted this request yet.');
      }
      final r = await api.dio
          .post('${ApiRoutes.bookings}/${cur.id}/transition', data: {
        'status': apiStatus(to),
        if (reason != null) 'reason': reason,
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      final env = ApiResponse.envelope(body);
      return Booking.fromJson(
          env.data ?? Map<String, dynamic>.from(body['data']));
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }
}
