import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../shared/models/models.dart';

/// Payments (§18): Flutter -> backend -> provider -> backend verify -> DB.
/// Never trust client success; idempotency keys prevent duplicates.
abstract class PaymentsRepository {
  /// Returns server-created transaction in PENDING/PROCESSING.
  Future<Map<String, dynamic>> startPayment(
      {required String bookingId,
      required String provider,
      required double amount,
      required String idempotencyKey});
  Future<String> status(String transactionId);

  /// Sandbox provider confirmation (local dev provider only).
  Future<Map<String, dynamic>> confirm(String paymentId);

  /// Technician-issued bill for the job (404/absent = none yet).
  Future<Map<String, dynamic>?> bill(String bookingId);

  /// Technician issues a bill after job completion.
  Future<Map<String, dynamic>> createBill(
      {required String bookingId,
      required double amount,
      String? notes,
      List<Map<String, dynamic>>? lineItems});

  /// Immutable transaction records for a booking (history).
  Future<List<Transaction>> transactions(String bookingId);

  /// Invoice for a booking (totals for customer/admin).
  Future<Invoice?> invoice(String bookingId);

  /// Admin/support refund of a SUCCEEDED payment. Reason required.
  Future<String> refund(String transactionId, String reason);
}

/// Production impl: idempotency via header + body; status server-verified.
class ApiPaymentsRepository implements PaymentsRepository {
  final DioClient api;
  ApiPaymentsRepository(this.api);

  @override
  Future<Map<String, dynamic>> startPayment(
      {required String bookingId,
      required String provider,
      required double amount,
      required String idempotencyKey}) async {
    try {
      final r = await api.dio.post('/api/v1/payments',
          data: {
            'job_id': int.tryParse(bookingId) ?? bookingId,
            'provider': provider,
            'amount': amount,
            'idempotency_key': idempotencyKey,
          },
          options: Options(headers: {
            'Idempotency-Key': idempotencyKey,
          }));
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      return data;
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> confirm(String paymentId) async {
    try {
      final r =
          await api.dio.post('/api/v1/payments/$paymentId/confirm');
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      return data;
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<Map<String, dynamic>?> bill(String bookingId) async {
    try {
      final r =
          await api.getRetry('/api/v1/jobs/$bookingId/bill');
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      if (data is! Map) return null;
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw api.mapError(e);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createBill(
      {required String bookingId,
      required double amount,
      String? notes,
      List<Map<String, dynamic>>? lineItems}) async {
    try {
      final r = await api.dio.post('/api/v1/jobs/$bookingId/bill', data: {
        'amount': amount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (lineItems != null && lineItems.isNotEmpty)
          'line_items': lineItems,
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      return data;
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<String> status(String transactionId) async {
    try {
      // transactionId may be a payment id (live) — authoritative lookup.
      final r = await api.getRetry('/api/v1/payments/$transactionId');
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      return '${data['status'] ?? 'PENDING'}';
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<List<Transaction>> transactions(String bookingId) async {
    try {
      final r =
          await api.getRetry('/api/v1/jobs/$bookingId/payments');
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return items
          .map((e) => Transaction(
                id: '${(e as Map)['id']}',
                paymentId: '${e['id']}',
                kind: 'CHARGE',
                amount: double.tryParse('${e['amount'] ?? 0}') ?? 0,
              ))
          .toList();
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<Invoice?> invoice(String bookingId) async {
    try {
      final r =
          await api.getRetry('/api/v1/jobs/$bookingId/invoice');
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      if (data is! Map) return null;
      return Invoice.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw api.mapError(e);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<String> refund(String transactionId, String reason) async {
    // Admin-only server endpoint: ledger reversal + audit happen there.
    try {
      final r = await api.dio.post(
          '/api/v1/admin/payments/$transactionId/refund',
          data: {'reason': reason});
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      return '${data['status'] ?? 'REFUNDED'}';
    } catch (e) {
      throw api.mapError(e);
    }
  }
}
