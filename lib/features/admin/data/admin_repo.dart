import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/models.dart';

/// Admin reads/writes. Every write is authorized + audited server-side.
class AdminRepository {
  final DioClient api;
  AdminRepository(this.api);

  Future<Map<String, dynamic>> dashboard() async {
    try {
      final r = await api.getRetry('/api/v1/admin/dashboard');
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<User>> users({String? q, String? role}) async {
    try {
      final r = await api.getRetry('/api/v1/admin/users', query: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (role != null) 'role': role.toLowerCase(),
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      return ApiResponse.list(body, User.fromJson);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> suspend(String id) async {
    try {
      await api.dio.post('/api/v1/admin/users/$id/suspend');
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> verificationQueue() async {
    try {
      final r =
          await api.getRetry('/api/v1/admin/verification');
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return [
        for (final e in items) Map<String, dynamic>.from(e as Map)
      ];
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> verify(String id, String decision,
      {String? reason}) async {
    // decision: approve | reject | resubmit
    try {
      await api.dio.post('/api/v1/admin/verification/$id/$decision',
          data: reason == null ? {} : {'reason': reason});
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> jobs({String? status}) async {
    try {
      final r = await api.getRetry('/api/v1/admin/jobs',
          query: {if (status != null) 'status': status.toLowerCase()});
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return [
        for (final e in items) Map<String, dynamic>.from(e as Map)
      ];
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> payments(
      {String? status}) async {
    try {
      final r = await api.getRetry('/api/v1/admin/payments',
          query: {if (status != null) 'status': status.toLowerCase()});
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return [
        for (final e in items) Map<String, dynamic>.from(e as Map)
      ];
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> complaints() async {
    try {
      final r = await api.getRetry('/api/v1/admin/complaints');
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return [
        for (final e in items) Map<String, dynamic>.from(e as Map)
      ];
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> resolveComplaint(String id, String resolution) async {
    try {
      await api.dio.post('/api/v1/admin/complaints/$id/resolve',
          data: {'resolution': resolution});
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> audit() async {
    try {
      final r = await api.getRetry('/api/v1/admin/audit');
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return [
        for (final e in items) Map<String, dynamic>.from(e as Map)
      ];
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> specialties() async {
    try {
      final r = await api.getRetry('/api/v1/specialties');
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return [
        for (final e in items) Map<String, dynamic>.from(e as Map)
      ];
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> setSpecialtyActive(String id, bool active) async {
    try {
      await api.dio.patch('/api/v1/admin/specialties/$id', data: {
        'status': active ? 'active' : 'inactive',
      });
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }
}
