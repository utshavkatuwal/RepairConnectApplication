import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../errors/failures.dart';
import '../storage/session_store.dart';

/// Standard API envelope (§12):
/// success: { success:true, data, message?, meta? }
/// error: { success:false, message, code?, errors? }
/// Paged lists: data:[...], meta:{ page, per_page, total, last_page }.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;
  const ApiResponse(
      {required this.success, this.data, this.message, this.meta});

  static ApiResponse<Map<String, dynamic>> envelope(
      Map<String, dynamic> json) {
    final data = json['data'];
    return ApiResponse(
      success: (json['success'] ?? true) == true,
      data: data is Map ? Map<String, dynamic>.from(data) : null,
      message: json['message']?.toString(),
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'])
          : null,
    );
  }

  static List<T> list<T>(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) from) {
    final d = json['data'];
    final items = d is List ? d : (d is Map ? d['items'] ?? [] : []);
    return ((items ?? []) as List)
        .map((e) => from(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Paged<T> paged<T>(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) from) {
    final items = list(json, from);
    final m = (json['meta'] is Map)
        ? Map<String, dynamic>.from(json['meta'])
        : <String, dynamic>{};
    return Paged(
      items: items,
      page: int.tryParse('${m['page'] ?? 1}') ?? 1,
      perPage: int.tryParse('${m['per_page'] ?? m['perPage'] ?? items.length}') ??
          items.length,
      total: int.tryParse('${m['total'] ?? items.length}') ?? items.length,
      lastPage: int.tryParse('${m['last_page'] ?? m['lastPage'] ?? 1}') ?? 1,
    );
  }
}

class Paged<T> {
  final List<T> items;
  final int page;
  final int perPage;
  final int total;
  final int lastPage;
  const Paged(
      {required this.items,
      required this.page,
      required this.perPage,
      required this.total,
      required this.lastPage});
  bool get hasMore => page < lastPage;
}

class DioClient {
  final Dio dio;
  final SessionStore sessions;
  bool _refreshing = false;
  DioClient({required this.sessions, String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) async {
        final token = await sessions.readToken();
        if (token != null && token.isNotEmpty) {
          o.headers['Authorization'] = 'Bearer $token';
        }
        // Idempotency for payment-sensitive POSTs is added by callers via
        // header 'Idempotency-Key' (see PaymentsRepository).
        h.next(o);
      },
      onError: (e, h) async {
        final code = e.response?.statusCode;
        final isRefreshCall =
            e.requestOptions.path.contains('refresh');
        if ((code == 401 || code == 419) &&
            !isRefreshCall &&
            !_refreshing) {
          _refreshing = true;
          try {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final req = e.requestOptions;
              final token = await sessions.readToken();
              req.headers['Authorization'] = 'Bearer $token';
              try {
                final r = await dio.fetch(req);
                return h.resolve(r);
              } catch (_) {}
            } else {
              await sessions.clear();
            }
          } finally {
            _refreshing = false;
          }
        }
        if (kDebugMode &&
            e.type != DioExceptionType.cancel) {
          debugPrint(
              '[API] ${e.requestOptions.method} ${e.requestOptions.path} -> $code ${e.message}');
        }
        h.next(e);
      },
    ));
  }

  /// GET with one automatic retry on connection errors/timeouts.
  Future<Response> getRetry(String path,
      {Map<String, dynamic>? query}) async {
    try {
      return await dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        await Future.delayed(const Duration(milliseconds: 600));
        return dio.get(path, queryParameters: query);
      }
      rethrow;
    }
  }

  Future<bool> _tryRefresh() async {
    try {
      final rt = await sessions.readRefreshToken();
      if (rt == null) return false;
      final r = await Dio(BaseOptions(baseUrl: dio.options.baseUrl))
          .post(ApiRoutes.authRefresh, data: {'refresh_token': rt});
      final body = r.data is Map
          ? Map<String, dynamic>.from(r.data)
          : <String, dynamic>{};
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      final token = data['token'] as String?;
      if (token == null) return false;
      await sessions.saveToken(token);
      final nr = data['refresh_token']?.toString();
      if (nr != null) {
        final old = await sessions.readRefreshToken();
        if (old != nr) {
          // Persist rotated refresh token via full session rewrite guard.
          await sessions.saveToken(token);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Failure mapError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      String msg = 'Network error. Please retry.';
      String? errCode;
      Map<String, List<String>>? fields;
      if (body is Map) {
        final m = Map<String, dynamic>.from(body);
        msg = (m['message'] ?? msg).toString();
        errCode = m['code']?.toString();
        final errs = m['errors'];
        if (errs is Map) {
          fields = errs.map((k, v) => MapEntry(k.toString(),
              (v is List
                      ? v
                      : [v])
                  .map((x) => x.toString())
                  .toList()));
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        msg = 'Request timed out. Check connection and retry.';
      } else if (e.type == DioExceptionType.connectionError) {
        msg = 'No connection to server. Retry when online.';
      }
      if (code == 401 || code == 419) return AuthFailure(msg, code: errCode);
      if (code == 403) return ForbiddenFailure(msg, code: errCode);
      if (code == 404) return NotFoundFailure(msg, code: errCode);
      if (code == 422) {
        return ValidationFailure(msg, code: errCode, fields: fields);
      }
      if (code == 429) {
        return NetworkFailure('Too many requests. Slow down and retry.',
            code: errCode);
      }
      if (code != null && code >= 500) return ServerFailure(msg, code: errCode);
      return NetworkFailure(msg, code: errCode);
    }
    return NetworkFailure(e.toString());
  }
}

// Env indirection avoids importing flutter_dotenv in core network layer.
class Env {
  static String apiBaseUrl = 'http://localhost:8000';
}
