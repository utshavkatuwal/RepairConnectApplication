// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_mapper.dart';
import '../../../core/config/env.dart';
import '../../../core/security/input_safety.dart';
import '../../../shared/models/models.dart';
import '../../bookings/domain/job_machine.dart'
    show JobMachine;

/// Repositories: Dio -> Laravel REST; USE_FAKE_BACKEND=true -> deterministic
/// seed data for dev (clearly fake, never prod). No business data hardcoded in widgets.

class Seed {
  static final categories = [
    const Category(id: 'c1', name: 'Appliance'),
    const Category(id: 'c2', name: 'Medical Devices'),
    const Category(id: 'c3', name: 'HVAC'),
    const Category(id: 'c4', name: 'Electrical'),
  ];
  static final services = [
    const ServiceItem(
        id: 's1',
        categoryId: 'c2',
        name: 'Anesthesia Vent Calibration',
        description: 'Certified calibration with telemetry lock.',
        basePrice: 299),
    const ServiceItem(
        id: 's2',
        categoryId: 'c1',
        name: 'Washer Diagnostics',
        description: 'On-site diagnostic + repair estimate.',
        basePrice: 89),
  ];
  static final technicians = [
    const Technician(
        id: 't1',
        userId: 'u-t1',
        name: 'Dr. Keith Sterling',
        specialty: 'Surgical Electronics Specialist',
        rating: 4.95,
        jobsCompleted: 142,
        verified: true,
        available: true,
        serviceArea: 'St. Jude Research Wing'),
    const Technician(
        id: 't2',
        userId: 'u-t2',
        name: 'Aris Vance',
        specialty: 'General Clinical Systems',
        rating: 4.8,
        jobsCompleted: 98,
        verified: true,
        available: true),
  ];
}

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
    if (AppEnv.useFakeBackend) return Seed.categories;
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

  /// Paginated services (§20). Fake backend slices deterministically.
  Future<Paged<ServiceItem>> servicesPaged(
      {String? categoryId,
      String? q,
      int page = 1,
      int perPage = 20}) async {
    if (AppEnv.useFakeBackend) {
      final all = Seed.services
          .where((s) =>
              (categoryId == null || s.categoryId == categoryId) &&
              (q == null ||
                  s.name.toLowerCase().contains(q.toLowerCase())))
          .toList();
      return Paged(
          items: all
              .skip((page - 1) * perPage)
              .take(perPage)
              .toList(),
          page: page,
          perPage: perPage,
          total: all.length,
          lastPage: (all.length / perPage).ceil().clamp(1, 1 << 30));
    }
    try {
      final r = await api.getRetry(ApiRoutes.services, query: {
        if (categoryId != null) 'category_id': categoryId,
        if (q != null) 'q': q,
        'page': page,
        'per_page': perPage,
      });
      return ApiResponse.paged(
          Map<String, dynamic>.from(r.data as Map),
          ServiceItem.fromJson);
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
    if (AppEnv.useFakeBackend) {
      final all = Seed.technicians
          .where((t) =>
              (q == null ||
                  t.name.toLowerCase().contains(q.toLowerCase()) ||
                  t.specialty.toLowerCase().contains(q.toLowerCase())) &&
              (available == null || t.available == available))
          .toList();
      return Paged(
          items: all
              .skip((page - 1) * perPage)
              .take(perPage)
              .toList(),
          page: page,
          perPage: perPage,
          total: all.length,
          lastPage: (all.length / perPage).ceil().clamp(1, 1 << 30));
    }
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

  /// Current user's bookings: history, invoices, payments derive from this.
  /// Fake seeds mirror representative states; prod paginates server-side.
  Future<List<Booking>> myBookings() async {
    if (AppEnv.useFakeBackend) {
      return [
        const Booking(
            id: 'b-101',
            requestId: 'req-101',
            customerId: 'me',
            technicianId: 't1',
            status: JobStatus.completed,
            price: 299,
            paymentStatus: 'SUCCEEDED'),
        const Booking(
            id: 'b-102',
            requestId: 'req-102',
            customerId: 'me',
            technicianId: 't2',
            status: JobStatus.completed,
            price: 89,
            paymentStatus: 'SUCCEEDED'),
        const Booking(
            id: 'b-103',
            requestId: 'req-103',
            customerId: 'me',
            technicianId: 't1',
            status: JobStatus.cancelled,
            price: 0,
            paymentStatus: 'REFUNDED'),
      ];
    }
    try {
      final r = await api.getRetry(ApiRoutes.bookings,
          query: {'mine': 1, 'per_page': 50});
      final body = Map<String, dynamic>.from(r.data as Map);
      return ApiResponse.list(body, Booking.fromJson);
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
    if (AppEnv.useFakeBackend) {
      return ServiceRequest(
          id: 'req-${DateTime.now().millisecondsSinceEpoch}',
          customerId: 'me',
          serviceId: serviceId,
          description: cleanDesc,
          status: JobStatus.requested,
          preferredAt: preferredAt,
          address: cleanAddr);
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

  Future<Booking> booking(String id) async {
    if (AppEnv.useFakeBackend) {
      return Booking(
          id: id,
          requestId: 'req-1',
          customerId: 'me',
          technicianId: 't1',
          status: JobStatus.accepted,
          price: 299,
          paymentStatus: 'PENDING');
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
    if (AppEnv.useFakeBackend) {
      final b = await booking(id);
      final from = knownFrom ?? b.status;
      if (!JobStatus.canTransition(from, to)) {
        throw ValidationFailure(
            'Cannot move from $from to $to');
      }
      if (actorRole != null &&
          !_canActor(role: actorRole, from: from, to: to)) {
        throw const ValidationFailure(
            'Your role cannot perform this transition');
      }
      return Booking(
          id: b.id,
          requestId: b.requestId,
          customerId: b.customerId,
          technicianId: b.technicianId,
          status: to,
          price: b.price,
          paymentStatus: b.paymentStatus,
          scheduledAt: b.scheduledAt);
    }
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
      final r = await api.dio.post('${ApiRoutes.bookings}/$id/transition',
          data: {
            'status': to,
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
