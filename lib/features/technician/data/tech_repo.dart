import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/network/dio_client.dart';

/// Technician self-service: profile, documents, availability, location.
/// All state lives in Laravel; verification gates enforced server-side.
class TechnicianRepository {
  final DioClient api;
  TechnicianRepository(this.api);

  Future<Map<String, dynamic>> saveProfile({
    required String specialtyId,
    String? bio,
    required int experienceYears,
    required int serviceRadius,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final r = await api.dio.post('/api/v1/technician/profile', data: {
        'specialty_id': specialtyId,
        'bio': bio,
        'experience_years': experienceYears,
        'service_radius': serviceRadius,
        'latitude': latitude,
        'longitude': longitude,
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required PlatformFile file,
    required String documentType,
  }) async {
    try {
      final bytes = file.bytes;
      final multipart = bytes != null
          ? MultipartFile.fromBytes(bytes, filename: file.name)
          : await MultipartFile.fromFile(file.path!,
              filename: file.name);
      final form = FormData.fromMap({
        'document_type': documentType,
        'file': multipart,
      });
      final r = await api.dio
          .post('/api/v1/technician/documents', data: form);
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> setAvailability(String status) async {
    try {
      await api.dio.post('/api/v1/technician/availability',
          data: {'availability_status': status});
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> setLocation(double lat, double lng) async {
    try {
      await api.dio.post('/api/v1/technician/location',
          data: {'latitude': lat, 'longitude': lng});
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }
}
