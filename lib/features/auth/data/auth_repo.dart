import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_mapper.dart';
import '../../../core/security/input_safety.dart';
import '../../../core/storage/session_store.dart';
import '../../../shared/models/models.dart';

class AuthRepository {
  final DioClient api;
  final SessionStore sessions;
  AuthRepository(this.api, this.sessions);

  Future<void> _persist(User u, String token, String? refresh) =>
      sessions.saveSession(
        token: token,
        refresh: refresh,
        role: u.role,
        userId: u.id,
        name: u.name,
        email: u.email,
        isVerified: u.isVerified,
        techVerified: u.techVerified,
        techStatus: u.techStatus,
      );

  Future<User> login(String email, String password) async {
    final clean = normalizeEmail(email);
    try {
      final r = await api.dio.post(ApiRoutes.authLogin,
          data: {'email': clean, 'password': password});
      final d = Map<String, dynamic>.from(r.data['data']);
      final u =
          User.fromJson(Map<String, dynamic>.from(d['user']));
      await _persist(u, '${d['token']}', d['refresh_token']?.toString());
      return u;
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<User> register(
      {required String name,
      required String email,
      required String password,
      required String role}) async {
    final cleanEmail = normalizeEmail(email);
    final cleanName = sanitizeText(name, max: 120);
    try {
      final r = await api.dio.post(ApiRoutes.authRegister, data: {
        'name': cleanName,
        'email': cleanEmail,
        'password': password,
        'password_confirmation': password,
        'role': apiRole(role),
      });
      final d = Map<String, dynamic>.from(r.data['data']);
      final u =
          User.fromJson(Map<String, dynamic>.from(d['user']));
      await _persist(u, '${d['token']}', d['refresh_token']?.toString());
      return u;
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  /// Rehydrate session against the backend (validates token).
  Future<User?> me() async {
    final token = await sessions.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final r = await api.dio.get(ApiRoutes.me);
      return User.fromJson(Map<String, dynamic>.from(r.data['data']));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await sessions.clear();
        return null;
      }
      throw api.mapError(e);
    }
  }

  Future<void> logout() async {
    try {
      await api.dio.post(ApiRoutes.authLogout);
    } catch (_) {}
    await sessions.clear();
  }

  Future<String?> currentRole() => sessions.readRole();

  Future<void> requestPasswordReset(String email) async {
    try {
      await api.dio.post(ApiRoutes.authForgot, data: {'email': email});
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> resetPassword(
      {required String email,
      required String token,
      required String password}) async {
    try {
      await api.dio.post(ApiRoutes.authReset, data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': password,
      });
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<User> verifyOtp({required String email, required String code}) async {
    try {
      final r = await api.dio.post(ApiRoutes.authVerify,
          data: {'email': email, 'code': code});
      final d = Map<String, dynamic>.from(r.data['data']);
      final u =
          User.fromJson(Map<String, dynamic>.from(d['user']));
      await _persist(u, '${d['token'] ?? await sessions.readToken()}',
          d['refresh_token']?.toString());
      return u;
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      await api.dio
          .post(ApiRoutes.authVerifySend, data: {'email': email});
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }
}
